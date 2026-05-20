#!/usr/bin/env python3
"""Split NoxTests/NoxTests.swift into one file per test struct under NoxTests/Mac/."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "NoxTests" / "NoxTests.swift"
OUT_DIR = ROOT / "NoxTests" / "Mac"

HEADER = """import Foundation
import Testing
import NoxCore
import NoxPlatformContracts
import NoxContextCore
import NoxSemanticCore
import NoxMemoryCore
import NoxContinuityCore
import NoxBehavioralIntelligenceCore
import NoxAmbientUtilityCore
import NoxSystemStateCore
import NoxObservatoryCore
import NoxPresenceCore
import NoxDesignCore
@testable import Nox

"""

SKIP_STRUCTS = {
    # Moved to Packages/*/Tests
    "NoxPhilosophyTests",
    "NoxTitleSanitizerTests",
    "NoxClassifierTests",
    "NoxSelfExclusionTests",
    "NoxSemanticConfidenceTests",
    "NoxSemanticSpanStitcherTests",
    "NoxPresenceEngineTests",
}


def main() -> None:
    text = SOURCE.read_text(encoding="utf-8")
    # Drop file-level imports
    body = re.sub(r"^import .+\n", "", text, flags=re.MULTILINE)
    body = re.sub(r"^@testable import .+\n", "", body, flags=re.MULTILINE)
    body = body.lstrip("\n")

    pattern = re.compile(
        r"^((?:@MainActor\s+)?struct\s+(\w+)\s*\{)",
        re.MULTILINE,
    )
    matches = list(pattern.finditer(body))
    if not matches:
        raise SystemExit("no test structs found")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    written = 0
    for i, match in enumerate(matches):
        name = match.group(2)
        if name in SKIP_STRUCTS:
            continue
        start = match.start()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(body)
        chunk = body[start:end].rstrip() + "\n"
        out = OUT_DIR / f"{name}.swift"
        out.write_text(HEADER + chunk, encoding="utf-8")
        written += 1

    stub = HEADER.strip() + "\n\n// macOS integration tests live in NoxTests/Mac/*.swift\n"
    SOURCE.write_text(stub, encoding="utf-8")
    print(f"Wrote {written} files under {OUT_DIR.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
