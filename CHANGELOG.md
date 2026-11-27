# Changelog

All notable changes to this project are documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project follows [Semantic Versioning](https://semver.org/). See [RELEASING.md](RELEASING.md) for the release process.

## [Unreleased]

Planned as `3.0.0`: the new folder layout requires a fresh install when upgrading from `2.1`.

### Changed

- Custom scripts moved into `maps/mp/centurypackage/` with submenus split into separate files.
- Player menu completely reworked: access rights are shown directly in the player list, options reordered, menu returns to the parent after kicking a player.
- Player verification reworked: XUID roles are cached once per connect and stored as a salted one-way hash instead of Vigenère encoding.
- SnD time extension runs in its own level thread and can be toggled.
- Menu title no longer shows a version number.

### Added

- PC support and Silinium stubs for PS3 (`silinium/` overlay).
- Option to give / take a player's ability to revive other players.
- Option to switch a player to spectator.
- Reticle color, clantag and emblem options, saved across respawns.
- Killcam is always shown at the end of an SnD round.
- `FEATURES.md`, `LICENSE`, `.editorconfig` and `.gitattributes`.

### Fixed

- Menu overflow clear retriggering itself every frame; overflow anchor is registered after precaching in every round.
- Menu could be opened without rights; removed admins kept admin access.
- Multiple controller threads and binds clashing with other binds.
- Hide toggle not working in some modes or not persisting after respawn.
- Revive ability lost after a new SnD round; host unable to revive.
- Forfeit popup not disabled properly.
- Lag when toggling unfair killstreaks.

### Removed

- Misc weapons.

## [2.1] - 2021-05-03

Last release before this changelog was introduced. See the [GitHub releases](https://github.com/itacentury/CenturyPackageBO1/releases) for older versions.

[Unreleased]: https://github.com/itacentury/CenturyPackageBO1/compare/2.1...HEAD
[2.1]: https://github.com/itacentury/CenturyPackageBO1/releases/tag/2.1
