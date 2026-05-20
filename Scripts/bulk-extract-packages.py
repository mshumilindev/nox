#!/usr/bin/env python3
"""Move Foundation-only Core files into Packages (git mv)."""
from __future__ import annotations
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NOX_CORE = ROOT / "Nox" / "Core"

FORBIDDEN = re.compile(
    r"import (AppKit|SwiftUI|SQLite3|EventKit|UserNotifications|"
    r"CoreBluetooth|Network|ApplicationServices|IOKit|Cocoa|Combine)\b"
)

SKIP_NAMES = {
    "NoxActivityObserver.swift", "NoxAXFocusMonitor.swift", "NoxWindowContextReader.swift",
    "NoxPermissionService.swift", "NoxCalendarContextProvider.swift",
    "NoxAmbientNotificationEngine.swift", "NoxSystemStateProvider.swift",
    "NoxSystemActionExecutor.swift", "NoxCaffeinateController.swift",
    "LocalHTTPPresenceTransport.swift", "BonjourPresenceDiscoveryProvider.swift",
    "AppleBluetoothPresenceDiscoveryProvider.swift", "CompositePresenceDiscoveryProvider.swift",
    "LocalIdentityProvider.swift", "NoxIdentityKeychain.swift", "DeviceArtworkImageDecoder.swift",
    "PresenceMeshManager.swift", "NoxSFSymbol.swift", "NoxSemanticMemoryStore.swift",
    "NoxMemoryStore.swift", "NoxMemoryRollupStore.swift", "NoxTypedMemoryStore.swift",
    "NoxContinuityThreadStore.swift", "NoxBehavioralIntelligenceSignalStore.swift",
    "NoxConnectorSignalStore.swift", "NoxReflectionStore.swift", "NoxPreferencesStore.swift",
    "NoxAmbientStateStore.swift", "NoxSessionStore.swift", "NoxTimelineStore.swift",
    "NoxSQLiteBindings.swift", "NoxPersistencePaths.swift", "NoxLocalDataResetSQL.swift",
    "NoxDesignTokens.swift", "NoxMaterials.swift", "NoxTypography.swift", "NoxIcon.swift",
    "NoxAtmosphere.swift", "NoxWindowModeControl.swift", "NoxInteraction.swift",
    "NoxAmbientHover.swift", "NoxSectionHeader.swift", "NoxFixedLineText.swift",
    "NoxObservatorySignals.swift",  # split later
    "NoxSemanticMemoryEngine.swift", "NoxSemanticLiveSignalPresenter.swift",
    "NoxSemanticArcEngine.swift", "NoxSemanticArcTypes.swift",
}

# (relative to Nox/Core, glob pattern or path) -> (package, subpath under Sources/Package/)
MOVES: list[tuple[str, str, str]] = [
    ("Memory", "NoxMemoryCore", ""),
    ("MemoryEvolution", "NoxMemoryCore", "Evolution"),
    ("Continuity", "NoxContinuityCore", ""),
    ("ContinuityMaturity", "NoxContinuityCore", "Maturity"),
    ("ReflectiveContinuity", "NoxContinuityCore", "Reflective"),
    ("Morning", "NoxContinuityCore", "Morning"),
    ("EngagementStabilization", "NoxContinuityCore", "Engagement"),
    ("BehavioralIntelligence", "NoxBehavioralIntelligenceCore", ""),
    ("AmbientUtility", "NoxAmbientUtilityCore", ""),
    ("Quiet", "NoxAmbientUtilityCore", "Quiet"),
    ("Observatory", "NoxObservatoryCore", ""),
    ("Presence", "NoxPresenceCore", ""),
    ("PresenceMesh/Messages", "NoxPresenceCore", "Messages"),
    ("PresenceMesh/Pairing/NoxTrustedNode.swift", "NoxPresenceCore", "Pairing"),
    ("PresenceMesh/Pairing/PairingInviteService.swift", "NoxPresenceCore", "Pairing"),
    ("PresenceMesh/Pairing/NoxTrustedNode.swift", "NoxPresenceCore", "Pairing"),
    ("PresenceMesh/NoxPresenceCurator.swift", "NoxPresenceCore", ""),
    ("PresenceMesh/NoxMeshProfile.swift", "NoxPresenceCore", ""),
    ("PresenceMesh/Identity/NoxNodeIdentity.swift", "NoxPresenceCore", "Identity"),
    ("PresenceMesh/Identity/IdentityProvider.swift", "NoxPresenceCore", "Identity"),
    ("PresenceMesh/Discovery/PresenceDiscoveryProvider.swift", "NoxPresenceCore", "Discovery"),
    ("PresenceMesh/Transport/PresenceTransportProvider.swift", "NoxPresenceCore", "Transport"),
    ("PresenceMesh/Artwork/DeviceArtworkURLBuilder.swift", "NoxPresenceCore", "Artwork"),
    ("PresenceMesh/Artwork/NoxPresenceFamilyArtwork.swift", "NoxPresenceCore", "Artwork"),
    ("PresenceMesh/Artwork/NoxPresenceHardwareIdentity.swift", "NoxPresenceCore", "Artwork"),
    ("PresenceMesh/Artwork/AppleDBDeviceRecord.swift", "NoxPresenceCore", "Artwork"),
    ("PresenceMesh/Artwork/AppleDBDeviceCatalog.swift", "NoxPresenceCore", "Artwork"),
    ("DesignSystem/NoxSpacing.swift", "NoxDesignCore", ""),
]

SYSTEM_STATE_FILES = {
    "NoxSystemStateTypes.swift", "NoxSystemContradictionEngine.swift",
    "NoxSystemContradictionContextBuilder.swift", "NoxSystemContradictionPresenter.swift",
    "NoxSystemContradictionSuppressionModel.swift", "NoxSystemActionPermissionModel.swift",
    "NoxSystemStateOrchestrator.swift",
}


def can_move(path: Path) -> bool:
    if path.name in SKIP_NAMES:
        return False
    text = path.read_text(encoding="utf-8", errors="ignore")
    if FORBIDDEN.search(text):
        return False
    if "import SQLite3" in text:
        return False
    return True


def git_mv(src: Path, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        return
    if not src.exists():
        return
    subprocess.run(["git", "mv", str(src), str(dest)], cwd=ROOT, check=False)
    if dest.exists():
        return
    dest.write_bytes(src.read_bytes())
    src.unlink()


def move_tree(rel: str, pkg: str, sub: str) -> int:
    src_base = NOX_CORE / rel
    dest_base = ROOT / "Packages" / pkg / "Sources" / pkg
    if sub:
        dest_base = dest_base / sub
    n = 0
    if src_base.is_file():
        files = [src_base]
    elif src_base.is_dir():
        files = list(src_base.rglob("*.swift"))
    else:
        return 0
    for f in files:
        if not can_move(f):
            continue
        rel_in = f.relative_to(src_base) if src_base.is_dir() else Path(f.name)
        dest = dest_base / rel_in
        git_mv(f, dest)
        n += 1
    return n


def main() -> None:
    total = 0
    ss_dir = NOX_CORE / "SystemState"
    if ss_dir.is_dir():
        dest = ROOT / "Packages" / "NoxSystemStateCore" / "Sources" / "NoxSystemStateCore"
        for f in ss_dir.glob("*.swift"):
            if f.name in SKIP_NAMES or not can_move(f):
                continue
            git_mv(f, dest / f.name)
            total += 1

    for rel, pkg, sub in MOVES:
        total += move_tree(rel, pkg, sub)

    # Remove placeholders when real sources exist
    for pkg in ROOT.glob("Packages/Nox*Core"):
        ph = pkg / "Sources" / pkg.name / f"{pkg.name}Placeholder.swift"
        if ph.exists() and any(pkg.glob("Sources/**/*.swift")) and len(list(pkg.glob("Sources/**/*.swift"))) > 1:
            ph.unlink()

    print(f"Moved {total} files")


if __name__ == "__main__":
    main()
