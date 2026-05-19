# Day 1 Acceptance — Birth of Nox

## Project foundation

- [x] Native macOS SwiftUI app named **Nox**
- [x] macOS 14+ deployment target, macOS-only
- [x] Folder structure: `App/`, `Core/`, `Features/`, `Resources/`, `SupportingFiles/`
- [x] No default `ContentView` or unused sample code
- [x] `Docs/PROJECT_RULES.md` with all 15 rules
- [x] `README.md`, `Docs/ARCHITECTURE.md`, `Docs/ROADMAP.md`

## Menu bar presence

- [x] App launches as a macOS app
- [x] Menu bar icon visible (`MenuBarExtra`)
- [x] Dropdown opens on click (window style)
- [x] No Dock icon (`LSUIElement`)

## Dropdown content

- [x] Nox title/header
- [x] Short presence line (state-derived)
- [x] Current presence state (title + description + symbol)
- [x] **Open Nox** — disabled placeholder
- [x] **Settings** — disabled placeholder
- [x] Separator before Quit
- [x] **Quit Nox** works

## Presence model

- [x] `NoxPresenceState`: `quiet`, `observing`, `reflecting`, `paused`
- [x] Each state has `title`, `description`, `symbolName`
- [x] Default state: **quiet**
- [x] Copy is honest (no fake tracking, reflections, or AI output)

## Visual & quality

- [x] Design tokens for spacing, radius, opacity, typography, symbols
- [x] Dark/light semantic colors
- [x] Minimal, native, non-SaaS aesthetic
- [x] Project builds; unit tests pass
- [x] No permission prompts
- [x] No third-party deps (SwiftLint optional)

## Wow-effect

- [x] Opening the panel feels like meeting Nox—quiet, precise, slightly mysterious
