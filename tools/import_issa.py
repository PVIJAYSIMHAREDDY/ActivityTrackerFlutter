#!/usr/bin/env python3
"""Build a private, page-addressable ISSA library from supplied PDFs.

Requires pdftotext (Poppler). No network calls or third-party Python packages.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    args = parser.parse_args()
    manifest_path = ROOT / "docs/coaching-source-manifest.json"
    manifest = json.loads(manifest_path.read_text())
    books = []
    coverage = []
    for entry in manifest["files"]:
        path = args.source / entry["filename"]
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if digest != entry["sha256"]:
            raise ValueError(f"Source hash mismatch: {path.name}")
        raw = subprocess.run(
            ["pdftotext", "-enc", "UTF-8", str(path), "-"],
            check=True, capture_output=True, text=True,
        ).stdout
        pages = raw.split("\f")
        if not pages[-1].strip():
            pages.pop()
        pages = [re.sub(r"[ \t]+", " ", p).strip() for p in pages]
        title = re.sub(r"[-_]", " ", path.name.split("Main")[0])
        title = title.replace("Certification", "").strip()
        book_id = hashlib.sha256(path.name.encode()).hexdigest()[:12]
        books.append(dict(id=book_id, title=title, file=path.name,
                          sha256=digest, pages=pages))
        coverage.append(dict(file=path.name, sha256=digest, pages=len(pages),
                             searchable_pages=sum(bool(p) for p in pages),
                             empty_pages=[i + 1 for i, p in enumerate(pages) if not p]))
    target = ROOT / "assets/coaching/issa_library.json"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(dict(version=1, books=books), ensure_ascii=False))
    (ROOT / "docs/issa-library-coverage.json").write_text(
        json.dumps(dict(extraction="Poppler pdftotext; PDF page numbers; text only, no OCR or diagram interpretation",
                        books=coverage), indent=2) + "\n")
    for book in coverage:
        print(f"{book['file']}: {book['searchable_pages']}/{book['pages']} searchable pages")
    print(f"Library: {target.stat().st_size:,} bytes")


if __name__ == "__main__":
    main()
