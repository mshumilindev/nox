# Dev identity & permissions

Nox uses a stable bundle identifier: **`dev.nox.Nox`**.

Grant macOS privacy permissions to the **same binary you run**, or context will stay app-only and MEMORY will stay thin.

## Run modes

| Mode | Permission target | Recommended for |
| --- | --- | --- |
| Xcode Run (⌘R) | Often Xcode or a transient helper | Quick UI edits |
| Standalone `Nox.app` | `dev.nox.Nox` in DerivedData or `/Applications` | **Permission testing, context QA** |

**For Iteration 6A (context reliability): use standalone builds.** TCC (Transparency, Consent, and Control) attaches permissions to the app path you launched. Switching between Xcode Run and Finder launch splits permissions across identities.

## Standalone build

```bash
xcodebuild -scheme Nox -destination 'platform=macOS' -configuration Debug build
```

Open the built app:

`~/Library/Developer/Xcode/DerivedData/Nox-*/Build/Products/Debug/Nox.app`

Drag to `/Applications` or always launch from the same path so TCC remembers the app.

## Permissions

| Permission | Enables |
| --- | --- |
| **Accessibility** | Window titles, browser URL (`kAXDocument`), focused roles |
| **Screen Recording** | Optional window-title fallback via `CGWindowList` |
| **Automation** | Not integrated in this build (shown as missing in dev explainability) |

System Settings → Privacy & Security → Accessibility / Screen Recording → enable **Nox** (`dev.nox.Nox`).

After changing permissions, **quit and relaunch** Nox (standalone recommended).

## Developer explainability (DEBUG only)

When running a **Debug** build, the dashboard includes **Context evidence (dev)**:

- Active app, bundle id, PID, window title, browser URL/domain
- Adapters invoked, dominant/secondary/stale context
- Capability matrix (available vs missing channels)
- Flat evidence list with source, kind, confidence, freshness
- Sensitivity and redaction reason
- Safe display label (never raw AX dump)

Release builds omit this panel.

## Diagnostics

- Bundle: `NoxDevRuntimeIdentity.bundleIdentifier`
- Launch context: `NoxDevRuntimeIdentity.launchContextSummary`
- Permission target: `NoxDevRuntimeIdentity.permissionTargetSummary`
- Running from Xcode: `NoxDevRuntimeIdentity.isRunningFromXcode`

Do not hack TCC databases; use the stable app identity above.

## QA

See `Docs/CONTEXT_QA_MATRIX.md` and `NoxTests/NoxContextScenarioQATests.swift` for scenario-class coverage.
