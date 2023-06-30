import { readFileSync, writeFileSync } from "fs";
import { createPreset } from "./mame/presets";
import {
  Metadata,
  PlatformPortMapping,
  PlatformSpecification,
} from "./mame/types";
import { collapseInputs, parseInputs } from "./mame/inputs";
import { argv } from "process";
import { parseRom } from "./mame/roms";

const PORT_SETTINGS_REGEX =
  /INPUT_PORTS_START\(\s+(.*)\s+\)([\s\S]*?)INPUT_PORTS_END/;

const CLASS_DEF_REGEX = /class\s+(.*_state)\s+:[\s\S]*?};/g;

const CLASS_DEF_CONSTUCTOR_REGEX = /void\s+(.*)\(machine_config\s*&\s*.*?\)/g;

const SYS_DEF_REGEX =
  /SYST\(\s*([0-9\?]{4})\s*,\s*(.*?)?\s*,.*?,.*?,.*?,.*?,.*?,.*?,\s*"(.*?)"\s*,\s*"(.*?)"/g;

// Used to check if `inp_fixed_last` is called
const PUBLIC_CONSTRUCTOR_REGEX_BUILDER = (deviceName: string) =>
  new RegExp(`${deviceName}\\(.*?\\)\\s*:[\\s\\S]*?{([^}]*)}`);

const INSTANCE_CONSTRUCTOR_REGEX_BUILDER = (
  stateName: string,
  deviceName: string
) =>
  new RegExp(
    `void\\s+${stateName}::${deviceName}\\(\\s*machine_config\\s+&\\s*config\\s*\\)\\s*{\\s*([\\s\\S]*?)\\s+}`
  );

const homebrewTitles = {
  hbw_bride: { game: "gnw_dkjr", name: "Bride", year: "2018" },
  hbw_squeeze: { game: "gnw_mickdon", name: "Squeeze", year: "2018" },
};

// This tool is constructed out of ad-hoc regex instead of being a clear "select block of a single platform and parse"
// because the MAME code isn't really laid out in a nice way to do that. So we do the next best thing
const run = () => {
  const file = readFileSync(argv[2], "utf8");

  // Get all metadata
  let metadata: {
    [name: string]: Metadata;
  } = {};

  for (const match of file.matchAll(SYS_DEF_REGEX)) {
    const [_, year, id, company, name] = match;

    metadata[id] = {
      year,
      company,
      name,
    };
  }

  // Get all port bodies
  let ports: {
    [name: string]: PlatformPortMapping;
  } = {};
  const globalNames = new RegExp(PORT_SETTINGS_REGEX, "g");
  for (const match of file.matchAll(globalNames)) {
    const [_, name, body] = match;

    if (name in ports) {
      console.log(`Duplicate input definition for ${name}`);
      return;
    }

    const portMap = parseInputs(body, name);

    ports[name] = portMap;
  }

  ports = collapseInputs(ports);

  // Add grounded ports
  for (const deviceName of Object.keys(ports)) {
    const portMap = ports[deviceName];

    const constructorMatch = file.match(
      PUBLIC_CONSTRUCTOR_REGEX_BUILDER(`${deviceName}_state`)
    );

    if (constructorMatch) {
      const contents = constructorMatch[1].trim();

      if (contents === "inp_fixed_last();") {
        // Last named port is grounded
        if (portMap.ports.length != 0) {
          // Get last S port index
          for (let i = portMap.ports.length - 1; i >= 0; i--) {
            const port = portMap.ports[i];

            if (port.type === "s") {
              // This is the one
              portMap.groundLastIndex = i;
              break;
            }
          }
        }
      }
    }
  }

  const consoles: {
    [name: string]: PlatformSpecification;
  } = {};

  // Map from the SHA of the MAME ROM to the game name that "owns" it (it's named after)
  const romShas: {
    [romSha: string]: string[];
  } = {};

  // TODO: These names are very messy
  for (const match of file.matchAll(CLASS_DEF_REGEX)) {
    const [classDef, className] = match;

    const subdevices: string[] = [];
    for (const match of classDef.matchAll(CLASS_DEF_CONSTUCTOR_REGEX)) {
      subdevices.push(match[1]);
    }

    const stateName = className.endsWith("_state")
      ? className.slice(0, -6)
      : className;

    subdevices.sort((a, _) => {
      if (a === stateName) {
        return -1;
      } else {
        return 0;
      }
    });

    // Find the actual constructors
    for (const device of subdevices) {
      // Setup inputs
      let portMap: PlatformPortMapping | undefined;
      if (device in ports) {
        portMap = ports[device];
      } else if (stateName in ports) {
        portMap = ports[stateName];
      } else {
        console.log(
          `Constructor without an input ${device}, in class ${className}`
        );
      }

      // Find constructors
      let regex = INSTANCE_CONSTRUCTOR_REGEX_BUILDER(className, device);

      let match = file.match(regex);

      if (!match) {
        console.log(`Could not find constructor for device ${device}`);
        continue;
      }

      const preset = createPreset(match[1], device);

      if (!preset) {
        console.log(`Could not find preset for device ${device}`);
        continue;
      }

      const localMetadata = metadata[device];

      const rom = parseRom(file, device);

      if (!rom) {
        continue;
      }

      if (rom.rom.sha in romShas) {
        romShas[rom.rom.sha].push(device);
      } else {
        romShas[rom.rom.sha] = [device];
      }

      if (rom.melody) {
        if (rom.melody.sha in romShas) {
          romShas[rom.melody.sha].push(device);
        } else {
          romShas[rom.melody.sha] = [device];
        }
      }

      consoles[device] = {
        device: preset,
        portMap: !!portMap
          ? portMap
          : {
              ports: [],
            },
        metadata: localMetadata,
        rom: {
          rom: rom.rom.name,
          melody: rom.melody?.name,
          romHash: rom.rom.sha,
        },
      };
    }
  }

  for (const romSha of Object.keys(romShas)) {
    const games = romShas[romSha];

    const rootGame = games[0];

    for (let i = 1; i < games.length; i++) {
      const game = games[i];

      consoles[game].rom.romOwner = rootGame;
    }
  }

  // Homebrew pass
  for (const [homebrewTitle, { game: mameTitle, name, year }] of Object.entries(
    homebrewTitles
  )) {
    const existingConfig = consoles[mameTitle];

    if (!existingConfig) {
      console.log(
        `Could not find title entry "${mameTitle}" for homebrew ${homebrewTitle}`
      );
      continue;
    }

    const homebrewConfig = structuredClone(existingConfig);

    homebrewConfig.rom.romOwner = homebrewConfig.rom.romOwner ?? mameTitle;
    homebrewConfig.portMap.include =
      homebrewConfig.portMap.include ?? mameTitle;
    homebrewConfig.metadata = {
      year,
      company: "Homebrew",
      name,
    };

    consoles[homebrewTitle] = homebrewConfig;
  }

  writeFileSync("manifest.json", JSON.stringify(consoles, undefined, 4));
};

if (argv.length != 3) {
  console.log(`Received ${argv.length - 2} arguments. Expected 1\n`);
  console.log("Usage: node extract.js [hh_sm510.cpp path]");

  process.exit(1);
}

run();
