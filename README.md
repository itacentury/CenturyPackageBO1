# Century Package

<div style="display: flex;">
  <img src="https://github.com/user-attachments/assets/87da4684-e476-4850-b600-72f0e90f33d8" width="45%">
  <img src="https://github.com/user-attachments/assets/6a167a47-2b62-43e4-a334-3beb8c607693" width="45%">
</div>

## Introduction

This works on `PS3` and `PC` and thanks to `@iMCSx` you are able to connect to other players!

This menu / mod aims to provide a non-gamebreaking experience in regular multiplayer to allow trickshotters and snipers to have an easier and fun time. It also includes general quality of life updates!

## Installation

### PS3

It is advised to use `The Century Package` in combination with [Silinium](https://github.com/itacentury/silinium). For detailed install instructions visit the `Silinium` repository. Folder structure should look like this:

```
/dev_hdd0/
└── tmp/
    ├── Silinium.sprx
    └── Silinium/
        └── mp/
            ├── CenturyPackageBO1.mod
            └── CenturyPackageBO1/
                └── maps/
                    └── mp/
                        ├── _laststand.gsc
                        ├── _tacticalinsertion.gsc
                        └── gametypes/
                            ├── _clientids.gsc
                            ├── _supplydrop.gsc
                            ├── hud.gsc
                            ├── init.gsc
                            ├── main_functions.gsc
                            ├── menu.gsc
                            ├── rights_management.gsc
                            ├── string_utils.gsc
                            ├── stubs.gsc
                            ├── utils.gsc
                            └── submenus/
                                ├── class_functions.gsc
                                ├── dev_functions.gsc
                                ├── lobby_functions.gsc
                                ├── player_functions.gsc
                                ├── self_functions.gsc
                                └── team_functions.gsc
```

1. Copy the repo's `maps` folder into `/dev_hdd0/tmp/Silinium/mp/CenturyPackageBO1/` and create an empty file `CenturyPackageBO1.mod` in `/dev_hdd0/tmp/Silinium/mp/`.
2. Place `Silinium.sprx` in `/dev_hdd0/tmp/`.
3. Place the `EBOOT.BIN` (see the `Silinium` repository) as usual in your game folder `USRDIR`.

### PC

1. `git clone https://github.com/itacentury/CenturyPackageBO1.git mp_CenturyPackageBO1` inside the `mods` folder of your Black Ops installation directory.
2. Launch the mod `mp_CenturyPackageBO1` inside the game.

## Usage

- Open menu: `Ads` + `Dpad down`
- Select option: `Jump`
- Return / close menu: `Knife`
- Scroll in menu: `Dpad up` / `down`
- Revive team bind (SnD only): `Crouch` & `Dpad Left`

## Features

See the [FEATURES.md](FEATURES.md) file for a list of all features.

## Credits

See the [CREDITS.md](CREDITS.md) file for a list of all credits.

## Contact

If you have any questions, you can message me on Twitter/X: [@Zxckerschlecken](https://twitter.com/Zxckerschlecken)
