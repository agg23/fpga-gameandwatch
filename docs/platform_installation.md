# Platform-Specific Installation

* [ROMs](#roms)
* [Analogue Pocket](#analogue-pocket-1)
* [MiSTer](#mister-1)

## ROMs

ROMs must be generated from their MAME counterparts. See [ROM Generator](rom_generator.md) for more information.

----
### Analogue Pocket

All ROMs are placed in `/Assets/gameandwatch/common/`

----
### MiSTer

All ROMs are placed in `/games/Game and Watch/`

## Analogue Pocket

### Easy Mode

I highly recommend the updater tools by [@mattpannella](https://github.com/mattpannella), [@RetroDriven](https://github.com/RetroDriven), and [@neil-morrison44](https://github.com/neil-morrison44). Choose one of the following updaters:
* [Pocket Updater](https://github.com/RetroDriven/Pocket_Updater) - Windows only
* [Pocket Sync](https://github.com/neil-morrison44/pocket-sync) - Cross platform
* [Pocket Updater Utility](https://github.com/mattpannella/pocket-updater-utility) - Cross platform, command line only

Any of these will allow you to automatically download and install openFPGA cores onto your Analogue Pocket. Go donate to the creators if you can

----
### Manual Mode
Visit [Releases](https://github.com/agg23/fpga-gameandwatch/releases) and download the latest version of the core by clicking on the file named `agg23...-Pocket.zip`.

To install the core, copy the `Assets`, `Cores`, and `Platform` folders over to the root of your SD card. Please note that Finder on macOS automatically _replaces_ folders, rather than merging them like Windows does, so you have to manually merge the folders.

See [ROMs](#roms) to install the correct ROMs and have a booting core.

## MiSTer

### Easy Mode

#### Update All

Open the [Update All](https://github.com/theypsilon/Update_All_MiSTer) settings menu, the `Unofficial Cores` submenu, and enable `agg23's MiSTer Cores` from there. [Visit the Update All page](https://github.com/theypsilon/Update_All_MiSTer) for more information on how to set up the script

#### Downloader

You can manually add my cores to the [MiSTer Downloader](https://github.com/MiSTer-devel/Downloader_MiSTer) script to automatically fetch all of my cores on release.

To start receiving my cores, simply paste the following snippet at the bottom of your `downloader.ini`. This will add my database to the list of locations MiSTer Downloader checks for updates from:

```
; This allows you to continue to receive main MiSTer downloads
[distribution_mister]

[agg23_db]
db_url = 'https://github.com/agg23/mister-repository/raw/db/manifest.json'
```

### Manual Mode

Visit [Releases](https://github.com/agg23/fpga-gameandwatch/releases) and download the latest version of the core by clicking on the file named `agg23...-MiSTer.zip`.

To install the core, copy the `_Console` and `games` folders over to the root of your SD card. Please note that Finder on macOS automatically _replaces_ folders, rather than merging them like Windows does, so you have to manually merge the folders.

See [ROMs](#roms) to install the correct ROMs and have a booting core.