#!/usr/bin/env python3
"""Add local Swift packages to Nox.xcodeproj (Nox + NoxTests targets)."""
from __future__ import annotations
import re
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / "Nox.xcodeproj" / "project.pbxproj"

PACKAGES = [
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


def uid() -> str:
    return uuid.uuid4().hex[:24].upper()


def main() -> None:
    text = PBX.read_text()
    existing = set(re.findall(r'XCLocalSwiftPackageReference "([^"]+)"', text))
    to_add = [p for p in PACKAGES if p not in existing]
    if not to_add:
        print("All packages already wired.")
        return

    ref_entries = []
    prod_entries = []
    ref_ids = {}
    prod_ids = {}

    for name in to_add:
        rid = uid()
        pid = uid()
        ref_ids[name] = rid
        prod_ids[name] = pid
        ref_entries.append(
            f'\t\t{rid} /* XCLocalSwiftPackageReference "{name}" */ = {{\n'
            f'\t\t\tisa = XCLocalSwiftPackageReference;\n'
            f'\t\t\trelativePath = Packages/{name};\n'
            f'\t\t}};'
        )
        prod_entries.append(
            f'\t\t{pid} /* {name} */ = {{\n'
            f'\t\t\tisa = XCSwiftPackageProductDependency;\n'
            f'\t\t\tproductName = {name};\n'
            f'\t\t\tpackage = {rid} /* XCLocalSwiftPackageReference "{name}" */;\n'
            f'\t\t}};'
        )

    text = text.replace(
        "/* End XCLocalSwiftPackageReference section */",
        "\n".join(ref_entries) + "\n/* End XCLocalSwiftPackageReference section */",
    )
    text = text.replace(
        "/* End XCSwiftPackageProductDependency section */",
        "\n".join(prod_entries) + "\n/* End XCSwiftPackageProductDependency section */",
    )

    refs_block = ",\n".join(
        f'\t\t\t\t{ref_ids[n]} /* XCLocalSwiftPackageReference "{n}" */' for n in to_add
    )
    text = re.sub(
        r"(packageReferences = \(\n(?:\t\t\t\t[^\n]+\n)*)(\t\t\t\);)",
        lambda m: m.group(1) + refs_block + ",\n" + m.group(2) if refs_block else m.group(0),
        text,
        count=1,
    )

    for target_marker, indent in [
        ("B580C3882FBBC1C700CB70C6 /* Nox */", "\t\t\t\t"),
        ("B580C3952FBBC1C800CB70C6 /* NoxTests */", "\t\t\t\t"),
    ]:
        deps = ",\n".join(f"{indent}{prod_ids[n]} /* {n} */," for n in to_add)
        pattern = (
            rf"(isa = PBXNativeTarget;\n.*?name = {target_marker.split()[2]};\n"
            rf".*?packageProductDependencies = \(\n)"
            rf"((?:\t\t\t\t[^\n]+\n)*)(\t\t\t\);)"
        )
        # Simpler: append to both packageProductDependencies blocks for Nox and NoxTests
    for name in ("Nox */", "NoxTests */"):
        pass

    # Append product deps to Nox and NoxTests targets
    dep_lines = "\n".join(f"\t\t\t\t{prod_ids[n]} /* {n} */," for n in to_add)
    count = 0
    def repl(m: re.Match) -> str:
        nonlocal count
        count += 1
        if count > 2:
            return m.group(0)
        return m.group(1) + m.group(2) + dep_lines + "\n" + m.group(3)

    text = re.sub(
        r"(packageProductDependencies = \(\n)((?:\t\t\t\t[^\n]+\n)*)(\t\t\t\);)",
        repl,
        text,
        count=2,
    )

    PBX.write_text(text)
    print(f"Wired packages: {', '.join(to_add)}")


if __name__ == "__main__":
    main()
