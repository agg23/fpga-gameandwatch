import { readFileSync, writeFileSync } from "fs";
import { createPreset } from "./mame/presets";
import {
  Metadata,
  PlatformPortMapping,
  PlatformSpecification,
} from "./mame/types";
import { collapseInputs, parseInputs } from "./mame/inputs";

const PORT_SETTINGS_REGEX =
  /INPUT_PORTS_START\(\s+(.*)\s+\)([\s\S]*?)INPUT_PORTS_END/;

const CLASS_DEF_REGEX = /class\s+(.*_state)\s+:[\s\S]*?};/g;

const CLASS_DEF_CONSTUCTOR_REGEX = /void\s+(.*)\(machine_config &config/g;

const SYS_DEF_REGEX =
  /SYST\(\s*([0-9\?]{4})\s*,\s*(.*?)?\s*,.*?,.*?,.*?,.*?,.*?,.*?,\s*"(.*?)"\s*,\s*"(.*?)"/g;

const INSTANCE_CONSTRUCTOR_REGEX_BUILDER = (
  stateName: string,
  deviceName: string
) =>
  new RegExp(
    `void\\s+${stateName}::${deviceName}\\(\\s*machine_config\\s+&\\s*config\\s*\\)\\s*{\\s*([\\s\\S]*?)\\s+}`
  );

// This tool is constructed out of ad-hoc regex instead of being a clear "select block of a single platform and parse"
// because the MAME code isn't really laid out in a nice way to do that. So we do the next best thing
const run = () => {
  const file = readFileSync("/Users/adam/Downloads/hh_sm510.cpp", "utf8");

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

  const consoles: {
    [name: string]: PlatformSpecification;
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

      consoles[device] = {
        device: preset,
        portMap: !!portMap
          ? portMap
          : {
              ports: [],
            },
        metadata: localMetadata,
      };
    }
  }

  writeFileSync("manifest.json", JSON.stringify(consoles, undefined, 4));
};

run();
