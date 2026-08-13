#!/usr/bin/env python3
"""Thin entrypoint — implementation lives in scripts/inject/."""

from __future__ import annotations

import sys
from pathlib import Path

# Allow `python3 scripts/inject.py` without installing the package.
sys.path.insert(0, str(Path(__file__).resolve().parent))

from inject.__main__ import main

if __name__ == "__main__":
    raise SystemExit(main())
