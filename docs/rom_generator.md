# ROM Generator

A tool for converting MAME 0.250 (though older versions probably work) ROMs into ROMs suitable for FPGAs, and particularly this core.

## Usage

Download the latest version of the ROM Generator, and select the correct folder for your platform. You will want to open a terminal window (or Command Prompt on Windows) in this location.

The tool has many options and features which you can explore by running:

```
fpga-gnw-romwgenerator --help
```

But most users will just want to generate any supported, installed ROMs they have, which you can do by running:

```
fpga-gnw-romwgenerator --mame-path [MAME path] --output-path [Output ROM path] supported
```

Make sure to replace the brackets with the actual paths to your files. The MAME path should be the folder that contains the `artwork` and `roms` folders.

You can also generate a single game, all of the games for a certain CPU, and more.

## General Structure

In order to turn MAME ROMs of separate formats and sizes into a unified 720x720 image (2x for the LCD layer) there is a lot of processing to be done. A rough list of the steps are:

1. Find MAME artwork and ROM files. Extract the zips to a temp folder
2. Open the `default.lay` file that represents the MAME layout. Parse the XML, and rank and choose the best layout option for us (trying to get rid of device overlays)
3. Scan through the layout, identifying the assets and their positions. Calculate the rescaled positions of the assets
4. Begin rendering the assets in the order they're listed. `screens` (which reference the SVG LCDs) are rendered to a separate buffer
   1. The SVG rendering process examines the SVG tree for `title` nodes. These titles contain the `x.y.z` segment identification values for the LCD. Maintain a map of node ids to segment ids
   2. Gather all SVG nodes matched to a given segment ID (there could be multiple occurances of that ID), and render then to a mock bitmap at the same size and position they will have in the final design
   3. Record what pixels are in the final rendered area
   4. Render the full SVG to a composite mask layer bitmap and mark down the pixel to segment ID mapping
5. Build up the format described in [Format](format.md)
   1. Scan through all pixels and use the pixel to segment ID mapping to build the mask data structure of contiguous spans
6. Save to output file

## Manifest

The manifest extractor (located at [support/extraction](../support/extraction)) reads the MAME `hh_sm510.cpp` device definition file that contains all SM510 related titles and converts it into a reliable, reusable format. Use is very simple, run:

```
npm run build [Path to hh_sm510.cpp]
```

This will create a `manifest.json` file with every SM510 title supported by MAME. You can use this in the ROM Generator by putting it alongside the executable, or by passing the `--manifest-path` argument