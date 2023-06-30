# Game and Watch for FPGAs

![Promo Image](../assets/promo.jpg)

This core is an original creation by [@agg23](https://github.com/agg23). It is based strongly on the original documentation for the Game and Watch CPU (see [Documentation Overview](docs/overview.md)), but additional supported CPUs in the core (like the SM5a) are based entirely on MAME's implementation. I have tried to accurately transcribe and rewrite the existing documentation and MAME's code into a more understandable, fewer error form. The Pocket platform icon was created by Random11. See [Licensing](#licensing) for more information.

Currently supported platforms are the Analogue Pocket and MiSTer.

## Installation Instructions

See [Platform Installation Instructions](docs/platform_installation.md) for platform-specific instructions on how to install the core.

## Generating ROMs

A tool is provided to generate ROMs from MAME ROMs for all of the supported devices. See [ROM Generator](docs/rom_generator.md) for more information about generating the ROMs.

## Supported Systems

The Game and Watch (and related) series of devices used varied hardware for each device. The currently supported CPUs are:
* SM510 - The "base" CPU the other's were based off of - Donkey Kong, Fire Attack, Mickey and Donald, etc
* SM510 (Tiger Variant) - Experimental - Street Fighter 2, Double Dragon, etc
* SM5a - Ball, Octopus, etc

The [ROM Generator](docs/rom_generator.md) will read the attached `manifest.json` file to determine what CPU is used by each game. You can manually look through this file yourself, or use the generator tool to determine if a game is supported at this time.

### Homebrew

For homebrew titles (I only know of [Bride and Squeeze](https://forums.atariage.com/topic/282578-two-new-homebrew-lcd-games-game-watch/)), you should rename the artwork and roms zips to have the `hbw_` prefix, and the name of the game. Thus Bride becomes `hbw_bride` and Squeeze becomes `hbw_squeeze`.

Squeeze does not run correctly due to having a completely different artwork design than any other core. [See #11 for more information](https://github.com/agg23/fpga-gameandwatch/issues/11#issuecomment-1614828078).

## Features

* 720 x 720 pixel resolution
* Ability to show inactive LCD segments with configurable opacity
* Deflicker on the LCD
* VSync after the deflicker has taken place

## Settings

* `Show Inactive LCD` - LCD segments that are inactive (off) remain displayed. See `Inact. LCD Alpha`
* `Inact. LCD Alpha` - `Inactive LCD Alpha` - If `Show Inactive LCD` is on (or this setting is set on MiSTer), sets the opacity of the disabled segments. Defaults to approximately 5%, or 13/255.
* `Acc. LCD Timing` - `Accurate LCD timing` - By default, the Game and Watch's LCD pulses at 64hz, which is what drives the static LCD screen. However, due to lack of persistence of our modern LCDs, this just results in a bunch of flicker. Instead when this setting is disabled, the LCD data will be updated at 1000 Hz. Enabling this setting updates the LCD at 64 Hz.

## Core Docs

I've tried to be thorough with my design decisions and provide/update various supporting documents through the process. See the `/docs` folder, or start looking at the [Overview](docs/overview.md).

## Licensing

There are a lot of components to this project, and the licensing on them depends on where they came from and potentially how they're used.

| Contents                                                                                                                              | License |
| ------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| The main repo, all Game and Watch core code, all tools and tests, and the documentation (other than the original docs owned by Sharp) | MIT     |
| All Pocket platform code, Pocket `core_top.sv`, and any Pocket specific components (unless otherwise noted)                           | MIT     |
| All MiMiC/MiSTer platform code, MiSTer `core_top.sv`, and any MiSTer specific components (unless otherwise noted)                     | GPLv3   |