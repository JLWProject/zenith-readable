# Changelog

## [1.8.2]

- Moved to dedicated public repository

## [1.8.1]

- Fixed marketplace preview GIF not loading (absolute image URLs)

## [1.8.0]

- Added preview screenshot and animated GIF

## [1.7.0]

- Removed repository link from marketplace resources

## [1.5.0]

- Unified syntax token colours across all languages using a consistent warm palette
- Replaced cool blues (`#77B7D7`), teals (`#86D9CA`), and purples (`#977CDC`) with warm amber, green, and orange equivalents
- Default text colour now warm tan (`#D0B890`) matching the editor foreground — no more cool grey text
- Comments updated to warm dim brown (`#7A6850`)
- All language-specific overrides (JS/TS, Python, C#, HCL, JSON, CSS, Markdown, Rust, etc.) remapped to the same warm palette

## [1.4.0]

- Activity bar badge number colour changed to warm white (`#FFF4D6`) — was previously invisible (dark on dark)
- Inactive activity bar icons lightened (`#C4A878`) for better visibility

## [1.3.0]

- Added `list.background` colour token for consistent warm dark brown background in list views
- Fixed `secondarySideBar.background` to match primary background (`#181512`) for visual consistency

## [1.1.0]

- Renamed theme to "Zenith Night Shift" — warmer, amber/brown-toned palette replacing the original cool grey/blue
- Shifted all background colours from neutral greys (`#151515`) to warm dark browns (`#181512`)
- Replaced accent colours: amber/gold (`#E8A830`) replaces cyan (`#6cc7f6`), warm orange replaces purple for info/remote indicators
- Expanded UI coverage: added panel, breadcrumb, minimap, notifications, settings, git decoration, diff editor, debug console, command centre, menu bar, and keybinding label colours
- Added ghost text, inlay hints, and suggest widget colour tokens

## [1.0.0]

- Initial release
- Forked from Zenith Theme by britown
- Improved text contrast across all languages
- Full Terraform / HCL colour scheme (block keywords, labels, attribute names, functions, types)
- Reduced orange overuse — orange reserved for Terraform block type keywords only
