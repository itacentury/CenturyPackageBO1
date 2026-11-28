# Changelog

All notable changes to this project are documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project follows [Semantic Versioning](https://semver.org/). See [RELEASING.md](RELEASING.md) for the release process.

## [Unreleased]

Planned as `3.0.0`: the new folder layout requires a fresh install when upgrading from `2.1`.

### Changed

- Custom scripts moved from `maps/mp/gametypes/century/` to `maps/mp/centurypackage/`.
- PC install: clone the repository into the Black Ops `mods` folder instead of renaming and copying the `raw` folder.
- Player menu completely reworked: access rights are shown directly in the player list, options reordered, menu returns to the parent after kicking a player.
- Player verification reworked: XUID roles are cached once per connect and stored as a salted one-way hash instead of Vigenère encoding; `hasher.py` replaces `encoder.py` for generating the hashes.
- SnD time extension runs in its own level thread and can be toggled.
- Menu title no longer shows a version number.
- Perk Selector covers all 15 pro perks.
- SAM Turret is given directly.
- Trickshot loadout updated.

### Added

- Silinium stubs for PS3 (`silinium/` overlay).
- Access Menu (host only) to manage a player's menu access.
- Killstreaks: Attack Helicopter, Chopper Gunner, Attack Dogs and Gunship.
- Cut killstreaks Bomber and Supply Station revived: available in the Killstreak Selector and in care packages (including Hardline Pro rerolls), with a "Killstreak Earned" pop-up.
- More glitch weapons.
- Option to give / take a player's ability to revive other players.
- Option to switch a player to spectator.
- Reticle shape and color, clantag and emblem options, saved across respawns.
- Killcam is always shown at the end of an SnD round.
- `FEATURES.md`, `LICENSE`, `.editorconfig` and `.gitattributes`.

### Fixed

- Fatal error when the 15 weapon slots overflow.
- String overflow: menu text no longer exhausts the game's string limit.
- "None" camo choice was ignored and replaced with a random camo.
- Menu could be opened without rights; removed admins kept admin access.
- Multiple controller threads and binds clashing with other binds.
- Hide toggle not working in some modes or not persisting after respawn.
- Revive ability lost after a new SnD round; host unable to revive.
- Forfeit popup not disabled properly.
- Remaining lag when toggling unfair killstreaks (2.1 only partly fixed it).

### Removed

- Xbox 360 support: no xex / DashLaunch plugin install anymore, only PS3 and PC are supported.
- Misc weapons.
- `encoder.py` (replaced by `hasher.py`).

## [2.1] - 2021-05-03

Last release before this changelog was introduced. See the [GitHub releases](https://github.com/itacentury/CenturyPackageBO1/releases) for older versions.

[Unreleased]: https://github.com/itacentury/CenturyPackageBO1/compare/2.1...HEAD
[2.1]: https://github.com/itacentury/CenturyPackageBO1/releases/tag/2.1
