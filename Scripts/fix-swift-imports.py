#!/usr/bin/env python3
"""Deduplicate Swift import lines; optionally append standard Nox package imports."""
from __future__ import annotations

import sys
from pathlib import Path

STANDARD_IMPORTS = [
    "import Foundation",
    "import CryptoKit",
    "import XCTest",
    "import Testing",
    "import SwiftUI",
    "import AppKit",
    "import Combine",
    "import Network",
    "import CoreBluetooth",
    "import SQLite3",
]

NOX_PACKAGES = [
    "NoxCore",
    "NoxPlatformContracts",
    "NoxContextCore",
    "NoxSemanticCore",
    "NoxMemoryCore",
    "NoxContinuityCore",
    "NoxBehavioralIntelligenceCore",
    "NoxAmbientUtilityCore",
    "NoxSystemStateCore",
    "NoxObservatoryCore",
    "NoxPresenceCore",
    "NoxDesignCore",
    "NoxShrineCore",
]

ORDER = {
    line: i
    for i, line in enumerate(
        STANDARD_IMPORTS
        + [f"import {p}" for p in NOX_PACKAGES]
        + ["@testable import Nox"]
    )
}


def normalize_file(path: Path, add_nox_packages: bool = False) -> bool:
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    imports: list[str] = []
    seen: set[str] = set()
    body: list[str] = []

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("import ") or stripped.startswith("@testable import "):
            if stripped not in seen:
                seen.add(stripped)
                imports.append(stripped + "\n")
        else:
            body.append(line)

    if add_nox_packages:
        for pkg in NOX_PACKAGES:
            stmt = f"import {pkg}"
            if stmt not in seen:
                seen.add(stmt)
                imports.append(stmt + "\n")

    imports.sort(key=lambda s: ORDER.get(s.strip(), 999))
    while body and body[0].strip() == "":
        body.pop(0)
    new = "".join(imports) + ("\n" if imports else "") + "".join(body)
    old = path.read_text(encoding="utf-8")
    if new != old:
        path.write_text(new, encoding="utf-8")
        return True
    return False


def main(argv: list[str]) -> int:
    add_nox = "--add-nox-packages" in argv
    paths = [p for p in argv[1:] if not p.startswith("--")]
    if not paths:
        print("usage: fix-swift-imports.py [--add-nox-packages] <path>...", file=sys.stderr)
        return 1
    changed = 0
    for raw in paths:
        root = Path(raw)
        files = [root] if root.is_file() else root.rglob("*.swift")
        for path in files:
            if normalize_file(path, add_nox_packages=add_nox):
                changed += 1
    print(f"fixed {changed} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
