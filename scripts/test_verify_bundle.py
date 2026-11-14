import importlib.util
import pathlib
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True

spec = importlib.util.spec_from_file_location("verify_bundle", pathlib.Path(__file__).with_name("verify-bundle.py"))
verifier = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verifier)


class BundleValidationTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="sorta-bundle-test-")
        self.addCleanup(self.directory.cleanup)
        self.app = pathlib.Path(self.directory.name) / "Sorta.app"
        executable = self.app / "Contents/MacOS/Sorta"
        executable.parent.mkdir(parents=True)
        executable.write_bytes(b"test-only Mach-O tool fixture")
        self.architectures = "arm64 x86_64"
        self.minimum = "15.1"
        self.dependencies = ["/usr/lib/libSystem.B.dylib"]
        self.rpaths = ["@executable_path/../Frameworks"]
        self.rpaths_by_arch = {}

    def tool_output(self, *arguments):
        tool = pathlib.Path(arguments[0]).name
        if tool == "file":
            return "Mach-O universal binary"
        if tool == "lipo":
            return self.architectures
        if tool == "xcrun":
            return f"cmd LC_BUILD_VERSION\nminos {self.minimum}\n"
        if "-L" in arguments:
            return "Sorta:\n" + "".join(f"\t{path} (compatibility version 1.0.0, current version 1.0.0)\n" for path in self.dependencies)
        rpaths = self.rpaths_by_arch.get(arguments[2], self.rpaths)
        return "".join(f"cmd LC_RPATH\ncmdsize 48\npath {path} (offset 12)\n" for path in rpaths)

    def validate(self):
        with patch.object(verifier, "command", side_effect=self.tool_output):
            verifier.check_bundle(self.app, {"arm64", "x86_64"})

    def test_system_dependencies_are_allowed(self):
        self.validate()

    def test_external_volume_dependency_is_rejected(self):
        self.dependencies.append("/Volumes/Development Folder/libPrivate.dylib")
        with self.assertRaisesRegex(ValueError, "Unbundled dependency"):
            self.validate()

    def test_external_rpath_is_rejected(self):
        self.rpaths.append("/private/tmp/developer-libraries")
        with self.assertRaisesRegex(ValueError, "External runtime search path"):
            self.validate()

    def test_unbundled_rpath_dependency_is_rejected(self):
        self.dependencies.append("@rpath/libMissing.dylib")
        with self.assertRaisesRegex(ValueError, "Unbundled dependency"):
            self.validate()

    def test_extra_architecture_is_rejected(self):
        self.architectures += " arm64e"
        with self.assertRaisesRegex(ValueError, "Wrong architectures"):
            self.validate()

    def test_higher_minimum_os_is_rejected(self):
        self.minimum = "26.0"
        with self.assertRaisesRegex(ValueError, "Unsupported minimum"):
            self.validate()

    def add_bundled_library(self):
        library = self.app / "Contents/Frameworks/libFixture.dylib"
        library.parent.mkdir(parents=True)
        library.write_bytes(b"test-only library fixture")
        self.dependencies.append("@rpath/libFixture.dylib")

    def test_bundled_library_requires_real_rpath(self):
        self.add_bundled_library()
        self.rpaths = []
        with self.assertRaisesRegex(ValueError, "Unbundled dependency"):
            self.validate()

    def test_one_architecture_cannot_supply_another_rpath(self):
        self.add_bundled_library()
        self.rpaths_by_arch["arm64"] = []
        with self.assertRaisesRegex(ValueError, "Unbundled dependency"):
            self.validate()

    def test_main_executable_cannot_be_external_symlink(self):
        main = self.app / "Contents/MacOS/Sorta"
        external = pathlib.Path(self.directory.name) / "external"
        main.rename(external)
        main.symlink_to(external)
        with self.assertRaisesRegex(ValueError, "Missing application executable"):
            self.validate()


if __name__ == "__main__":
    unittest.main()
