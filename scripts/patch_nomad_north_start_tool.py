#!/usr/bin/env python3
"""Patch NOMAD NORTH start_tool to skip uploads with missing file trees.

This avoids crashing notebook launch for all uploads when one upload has
inconsistent metadata/filesystem state.
"""

from __future__ import annotations

import pathlib
import sys


def main() -> int:
    pyver = f"{sys.version_info.major}.{sys.version_info.minor}"
    target = pathlib.Path(
        f"/opt/venv/lib/python{pyver}/site-packages/nomad/app/v1/routers/north.py"
    )

    if not target.exists():
        raise FileNotFoundError(f"Target file not found: {target}")

    text = target.read_text(encoding="utf-8")

    if "upload files missing, skipping upload mount" in text:
        print("Patch already applied")
        return 0

    old_block = """    for upload in Upload.objects.filter(upload_query):  # type: ignore\n        if not hasattr(upload.upload_files, 'external_os_path'):\n            # In case the files are missing for one reason or another\n            logger.info(\n                'upload: the external path is missing for one reason or another'\n            )\n            continue\n\n        if upload.upload_name:\n"""

    new_block = """    for upload in Upload.objects.filter(upload_query):  # type: ignore\n        try:\n            upload_files = upload.upload_files\n        except KeyError:\n            logger.warning(\n                'upload files missing, skipping upload mount',\n                upload_id=upload.upload_id,\n            )\n            continue\n\n        if not hasattr(upload_files, 'external_os_path'):\n            # In case the files are missing for one reason or another\n            logger.info(\n                'upload: the external path is missing for one reason or another'\n            )\n            continue\n\n        if upload.upload_name:\n"""

    if old_block not in text:
        raise RuntimeError("Expected start_tool loop block not found; patch needs update")

    text = text.replace(old_block, new_block, 1)
    text = text.replace(
        "os.path.join(upload.upload_files.external_os_path, 'raw')",
        "os.path.join(upload_files.external_os_path, 'raw')",
    )

    target.write_text(text, encoding="utf-8")
    print(f"Patched {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
