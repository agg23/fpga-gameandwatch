import { readFileSync, writeFileSync } from "fs";
import { createPreset } from "./mame/presets";
import { PlatformPortMapping, PlatformSpecification } from "./mame/types";
import { collapseInputs, parseInputs } from "./mame/inputs";

const PORT_SETTINGS_REGEX =
  /INPUT_PORTS_START\(\s+(.*)\s+\)([\s\S]*?)INPUT_PORTS_END/;

const CLASS_DEF_REGEX = /class\s+(.*_state)\s+:[\s\S]*?};/g;

const CLASS_DEF_CONSTUCTOR_REGEX = /void\s+(.*)\(machine_config &config/g;

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
  //   const file = `static INPUT_PORTS_START( gnw_mario )
  // 	PORT_START("IN.0") // S1
  // 	PORT_BIT( 0x01, IP_ACTIVE_HIGH, IPT_JOYSTICKRIGHT_DOWN ) PORT_CHANGED_CB(input_changed)
  // 	PORT_BIT( 0x02, IP_ACTIVE_HIGH, IPT_JOYSTICKRIGHT_UP ) PORT_CHANGED_CB(input_changed)
  // 	PORT_BIT( 0x04, IP_ACTIVE_HIGH, IPT_JOYSTICKLEFT_UP ) PORT_CHANGED_CB(input_changed)
  // 	PORT_BIT( 0x08, IP_ACTIVE_HIGH, IPT_JOYSTICKLEFT_DOWN ) PORT_CHANGED_CB(input_changed)

  // 	PORT_START("IN.1") // S2
  // 	PORT_BIT( 0x01, IP_ACTIVE_HIGH, IPT_SELECT ) PORT_CHANGED_CB(input_changed) PORT_NAME("Time")
  // 	PORT_BIT( 0x02, IP_ACTIVE_HIGH, IPT_START2 ) PORT_CHANGED_CB(input_changed) PORT_NAME("Game B")
  // 	PORT_BIT( 0x04, IP_ACTIVE_HIGH, IPT_START1 ) PORT_CHANGED_CB(input_changed) PORT_NAME("Game A")
  // 	PORT_BIT( 0x08, IP_ACTIVE_HIGH, IPT_SERVICE2 ) PORT_CHANGED_CB(input_changed) PORT_NAME("Alarm")

  // 	PORT_START("ACL")
  // 	PORT_BIT( 0x01, IP_ACTIVE_HIGH, IPT_SERVICE1 ) PORT_CHANGED_CB(acl_button) PORT_NAME("ACL")

  // 	PORT_START("BA")
  // 	PORT_CONFNAME( 0x01, 0x01, "Increase Score (Cheat)") // factory test, unpopulated on PCB
  // 	PORT_CONFSETTING(    0x01, DEF_STR( Off ) )
  // 	PORT_CONFSETTING(    0x00, DEF_STR( On ) )

  // 	PORT_START("B")
  // 	PORT_CONFNAME( 0x01, 0x01, "Infinite Lives (Cheat)") // "
  // 	PORT_CONFSETTING(    0x01, DEF_STR( Off ) )
  // 	PORT_CONFSETTING(    0x00, DEF_STR( On ) )
  // INPUT_PORTS_END

  // // config

  // void gnw_mario_state::gnw_mario(machine_config &config)
  // {
  // 	sm510_dualh(config, 2258/2, 1440/2, 2261/2, 1440/2); // R mask option confirmed
  // }`;

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

      consoles[device] = {
        device: preset,
        portMap: !!portMap
          ? portMap
          : {
              ports: [],
            },
      };
    }
  }

  writeFileSync("output.json", JSON.stringify(consoles, undefined, 4));

  // const deviceStrings = [];
  // for (const match of file.matchAll(EXTRACT_BODY_REGEX)) {
  //   deviceStrings.push(match[0]);
  // }

  // if (names.length !== deviceStrings.length) {
  //   console.log(
  //     `Mismatch between device names (${names.length}) and extracted devices (${deviceStrings.length})`
  //   );
  //   // return;
  // }

  // for (let i = 0; i < names.length; i++) {
  //   const name = names[i];
  //   const deviceString = deviceStrings[i]!;

  //   const match = EXTRACT_NAME_REGEX.exec(deviceString);

  //   if (!match || match.length < 2) {
  //     console.log(`Block ${i}: Could not extract name. Expected ${name}`);

  //     console.log(deviceString);
  //     return;
  //   }

  //   if (match[1] !== name) {
  //     console.log(
  //       `Block ${i} had mismatch between expected name ${name} and found name ${match[1]}`
  //     );

  //     console.log(match, deviceString);

  //     return;
  //   }
  // }
};

run();
