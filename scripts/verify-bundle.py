#!/usr/bin/env python3
"""Validate all archived Mach-O dependencies and architecture/minimum OS contracts."""

import pathlib
import re
import subprocess
import sys


def command(*arguments):
    return subprocess.run(arguments, check=True, capture_output=True, text=True).stdout


def check_bundle(app, expected_architectures):
    app = app.resolve(strict=True)
    executable_dir = app / "Contents/MacOS"
    main = executable_dir / "Sorta"
    if main.is_symlink() or not main.is_file():
        raise ValueError("Missing application executable")
    checked = 0
    for binary in app.rglob("*"):
        if not binary.is_file() or binary.is_symlink():
            continue
        if "Mach-O" not in command("/usr/bin/file", "-b", str(binary)):
            continue
        checked += 1
        actual = set(command("/usr/bin/lipo", "-archs", str(binary)).split())
        if actual != expected_architectures:
            raise ValueError(f"Wrong architectures in {binary.relative_to(app)}: {sorted(actual)}")
        build_info = command("/usr/bin/xcrun", "vtool", "-show-build", str(binary))
        minimums = re.findall(r"\bminos\s+(\d+(?:\.\d+)*)", build_info)
        if not minimums:
            raise ValueError(f"Missing minimum OS in {binary.relative_to(app)}")
        for minimum in minimums:
            version = tuple(int(part) for part in minimum.split("."))
            version = version + (0,) * (3 - len(version))
            if version > (15, 1, 0) or (binary == main and version != (15, 1, 0)):
                raise ValueError(f"Unsupported minimum macOS {minimum} in {binary.relative_to(app)}")
        def expand(path, loader=binary):
            if path.startswith("@executable_path/"):
                return (executable_dir / path.removeprefix("@executable_path/")).resolve()
            if path.startswith("@loader_path/"):
                return (loader.parent / path.removeprefix("@loader_path/")).resolve()
            if path.startswith("/"):
                return pathlib.Path(path).resolve()
            raise ValueError(f"Unsupported load path {path}")

        def system(path):
            return path.is_relative_to("/usr/lib") or path.is_relative_to("/System/Library")

        for architecture in sorted(expected_architectures):
            resolved_rpaths = []
            # Inherit only paths actually declared by this slice of the main executable.
            for owner in {main, binary}:
                load_commands = command("/usr/bin/otool", "-arch", architecture, "-l", str(owner))
                rpaths = re.findall(r"cmd LC_RPATH\s+cmdsize \d+\s+path (.*?) \(offset", load_commands)
                resolved_rpaths.extend(expand(path, owner) for path in rpaths)
            for rpath in resolved_rpaths:
                if not rpath.is_relative_to(app) and not system(rpath):
                    raise ValueError(f"External runtime search path in {binary.relative_to(app)}: {rpath}")
            dependencies = re.findall(
                r"^\s+(.+?) \(compatibility version",
                command("/usr/bin/otool", "-arch", architecture, "-L", str(binary)), re.M
            )
            for dependency in dependencies:
                if dependency.startswith("@rpath/"):
                    relative = dependency.removeprefix("@rpath/")
                    candidates = [(base / relative).resolve() for base in resolved_rpaths]
                else:
                    candidates = [expand(dependency)]
                if not any(system(path) or (path.is_relative_to(app) and path.is_file()) for path in candidates):
                    raise ValueError(f"Unbundled dependency in {binary.relative_to(app)} ({architecture}): {dependency}")
    if checked == 0:
        raise ValueError("No Mach-O executables found")
    print("PASS: Mach-O architectures, minimum OS, dependency paths and runtime search paths")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("Usage: verify-bundle.py Sorta.app 'arm64 x86_64'")
    try:
        architectures = set(sys.argv[2].split())
        if not architectures or not architectures <= {"arm64", "x86_64"}:
            raise ValueError("Invalid expected architectures")
        check_bundle(pathlib.Path(sys.argv[1]), architectures)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        raise SystemExit(f"Bundle verification failed: {error}") from error
