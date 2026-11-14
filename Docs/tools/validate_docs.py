#!/usr/bin/env python3
"""Validate Sorta's public documentation without network access or dependencies."""

import json
from pathlib import Path
import re
from urllib.parse import unquote, urlsplit
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[2]


def fail(message: str) -> None:
    raise SystemExit(message)


def exact_case_path_exists(path: Path) -> bool:
    """Catch paths that work on a case-insensitive Mac but fail on GitHub."""
    current = ROOT
    if not path.is_relative_to(ROOT):
        return False
    for part in path.relative_to(ROOT).parts:
        if not current.is_dir():
            return False
        entries = {entry.name: entry for entry in current.iterdir()}
        if part not in entries:
            return False
        current = entries[part]
    return current.exists()


def markdown_anchors(path: Path) -> set[str]:
    content = path.read_text(encoding="utf-8")
    anchors = set(re.findall(r'<a\b[^>]*(?:id|name)=[\"\']([^\"\']+)', content))
    occurrences: dict[str, int] = {}
    for heading in re.findall(r"^#{1,6}\s+(.+?)\s*#*\s*$", content, re.MULTILINE):
        plain = re.sub(r"<[^>]*>", "", heading)
        plain = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", plain)
        slug = re.sub(r"[^\w\- ]", "", plain.lower()).replace(" ", "-")
        number = occurrences.get(slug, 0)
        occurrences[slug] = number + 1
        anchors.add(f"{slug}-{number}" if number else slug)
    return anchors


def main() -> None:
    pages = [ROOT / name for name in ("README.md", "README-ru.md", "SUPPORT.md", "PRIVACY.md")]
    pages.extend(sorted((ROOT / "Docs").rglob("*.md")))
    local_links = 0
    for page in pages:
        content = page.read_text(encoding="utf-8")
        if "\ufffd" in content or re.search(r"/(?:Users|Volumes|private/tmp)/", content):
            fail(f"Invalid Unicode or private machine path: {page.relative_to(ROOT)}")
        targets = re.findall(r"!?\[[^\]]*\]\(([^)]+)\)", content)
        targets += re.findall(r'(?:src|href)="([^"]+)"', content)
        for target in targets:
            url = urlsplit(target.strip("<>"))
            if url.scheme or url.netloc:
                continue
            destination = (page.parent / unquote(url.path)).resolve() if url.path else page
            if not exact_case_path_exists(destination):
                fail(f"Broken or case-mismatched link in {page.relative_to(ROOT)}: {target}")
            if url.fragment and destination.suffix == ".md":
                if unquote(url.fragment) not in markdown_anchors(destination):
                    fail(f"Missing heading in {page.relative_to(ROOT)}: {target}")
            local_links += 1

    english = {path.name for path in (ROOT / "Docs/en").glob("*.md")}
    russian = {path.name for path in (ROOT / "Docs/ru").glob("*.md")}
    if not english or english != russian:
        fail(f"Translation page mismatch: EN-only={english-russian}; RU-only={russian-english}")
    for language, other in (("en", "ru"), ("ru", "en")):
        for name in english:
            page = ROOT / "Docs" / language / name
            if f"../{other}/{name}" not in page.read_text(encoding="utf-8"):
                fail(f"Missing language switch: {page.relative_to(ROOT)}")

    artwork = sorted((ROOT / "Docs/assets").glob("*.svg"))
    expected = {"banner-en.svg", "banner-ru.svg", "workflow-en.svg", "workflow-ru.svg"}
    if {path.name for path in artwork} != expected:
        fail("Expected English/Russian banner and workflow SVGs")
    for path in artwork:
        tree = ET.fromstring(path.read_text(encoding="utf-8"))
        if not all(tree.get(key) for key in ("width", "height", "viewBox", "aria-labelledby")):
            fail(f"Missing SVG size or accessible label: {path.name}")
        ids = {element.get("id") for element in tree.iter() if element.get("id")}
        if not set(tree.get("aria-labelledby", "").split()).issubset(ids):
            fail(f"Broken SVG accessible label: {path.name}")
        for element in tree.iter():
            tag = element.tag.rsplit("}", 1)[-1]
            if tag in {"script", "foreignObject", "image", "font", "font-face"}:
                fail(f"Unexpected SVG dependency: {path.name}: {tag}")
            for key, value in element.attrib.items():
                if key.rsplit("}", 1)[-1] == "href" and not value.startswith("#"):
                    fail(f"External SVG resource: {path.name}")
                if key.lower().startswith("on") or re.search(r"url\(\s*[\"\']?(?:https?:|//|data:)", value):
                    fail(f"Active or external SVG content: {path.name}")

    print(json.dumps({"status": "PASS", "markdown_pages": len(pages), "local_links": local_links,
                      "language_pairs": len(english), "standalone_svgs": len(artwork)}, indent=2))


if __name__ == "__main__":
    main()
