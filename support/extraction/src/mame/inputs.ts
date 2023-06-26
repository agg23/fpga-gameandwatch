import {
  Action,
  NamedAction,
  PlatformPortMapping,
  Port,
  UndfAction,
} from "./types";

const PORT_START_REGEX = /^\s*PORT_START\("(.*)"\)/;

/**
 * Captures bit, high/low active status, input, and optional name
 */
const PORT_BIT_REGEX =
  /PORT_BIT\(\s*([0-9A-Fx]+)\s*,\s*(.*?)\s*,\s*(.*?)\s*\).*(?:PORT_NAME\("(.*)"\))?/;

const PORT_CONFSETTING_REGEX = /PORT_CONFSETTING\(\s*([0-9A-Fx]+)\s*,/;

const PORT_INCLUDE_REGEX = /PORT_INCLUDE\(\s*(.*)\s*\)/;

const PORT_MODIFY_REGEX = /PORT_MODIFY\("(.*)"\)/;

type PortType =
  | {
      type: Exclude<Port["type"], "s">;
    }
  | {
      type: "s";
      index: number;
    };

export const parseInputs = (
  inputBody: string,
  deviceName: string
): PlatformPortMapping => {
  const lines = inputBody.trim().split("\n");

  let currentPort: Port | undefined = undefined;
  const ports: Port[] = [];

  // If set, this port includes port mapping from another console
  let portInclude: string | undefined = undefined;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    let match = line.match(PORT_START_REGEX);

    if (!match) {
      match = line.match(PORT_MODIFY_REGEX);
    }
    // Either PORT_START or PORT_MODIFY
    if (match) {
      // Example: PORT_START("IN.0")
      const name = match[1];

      if (currentPort) {
        ports.push(currentPort);
      }

      const portType = parsePortName(name, deviceName);

      if (portType) {
        switch (portType.type) {
          case "s": {
            currentPort = {
              ...portType,
              bitmap: [undefined, undefined, undefined, undefined],
            };
            break;
          }
          default: {
            currentPort = {
              ...portType,
              bit: undefined,
            };
            break;
          }
        }
      }
    }

    match = line.match(PORT_BIT_REGEX);
    if (match) {
      const [_, unparsedBit, unparsedActive, unparsedButton, portName] = match;

      const bit = parseInt(
        unparsedBit.startsWith("0x") ? unparsedBit.slice(2) : unparsedBit,
        16
      );

      const index = indexFromBit(bit);
      const activeHigh = unparsedActive === "IP_ACTIVE_HIGH";
      const button = parseButton(unparsedButton);

      if (!button) {
        console.log(
          `Unknown button action ${unparsedButton} for device ${deviceName}`
        );
        continue;
      }

      if (!currentPort) {
        console.log(
          `Attempted to add button ${line} without port to device ${deviceName}`
        );
        continue;
      }

      const namedAction: NamedAction = {
        action: button,
        activeLow: !activeHigh,
        name: portName,
      };

      if (currentPort.type === "s") {
        currentPort.bitmap[index] = namedAction;
      } else {
        // All other ports
        currentPort.bit = namedAction;
      }
    }

    match = line.match(PORT_CONFSETTING_REGEX);
    if (match) {
      // This is a cheat option. We want the default (the first option)
      const [_, unparsedBit] = match;

      const bit = parseInt(
        unparsedBit.startsWith("0x") ? unparsedBit.slice(2) : unparsedBit,
        16
      );

      const index = indexFromBit(bit);

      if (currentPort) {
        if (currentPort.type === "s") {
          if (!currentPort.bitmap[index]) {
            // No configured value for that port index. This is probably the first (default)
            const namedAction: NamedAction = {
              action: "unused",
              activeLow: false,
            };

            currentPort.bitmap[index] = namedAction;
          }
        } else {
          // Single bit port
          if (!currentPort.bit) {
            // No configured value for that port. This is probably the first (default)
            const namedAction: NamedAction = {
              action: "unused",
              // If bit is 1, the default setting is on/high
              activeLow: bit === 1,
            };

            currentPort.bit = namedAction;
          }
        }
      }
    }

    match = line.match(PORT_INCLUDE_REGEX);
    if (match) {
      portInclude = match[1].trim();
    }
  }

  if (currentPort) {
    ports.push(currentPort);
  }

  const filteredSortedPorts = ports
    .filter((p) => {
      // Strip empty S inputs
      if (p.type === "s" && p.bitmap.filter((b) => !!b).length === 0) {
        return false;
      }

      return true;
    })
    .sort((a, b) => {
      const portIndex = (port: Port): number => {
        switch (a.type) {
          case "s":
            return a.index;
          // S takes 0-7, start at 8
          case "b":
            return 8;
          case "ba":
            return 9;
          case "acl":
            return 10;
        }
      };

      return portIndex(a) - portIndex(b);
    });

  return {
    ports: filteredSortedPorts,
    include: portInclude,
  };
};

export const collapseInputs = (ports: {
  [name: string]: PlatformPortMapping;
}): {
  [name: string]: PlatformPortMapping;
} => {
  const collapsedPorts: {
    [name: string]: PlatformPortMapping;
  } = {};

  for (const [deviceName, port] of Object.entries(ports)) {
    if (port.include) {
      const flatPortMap: {
        [id: string]: Port;
      } = {};

      for (const innerPort of port.ports) {
        const name = nameInnerPort(innerPort);

        flatPortMap[name] = innerPort;
      }

      const includedPort = ports[port.include];

      if (!includedPort) {
        console.log(
          `Could not find included port ${port.include} from device ${deviceName}`
        );
        continue;
      }

      if (includedPort.include) {
        console.log(
          `Included port ${port.include} from device ${deviceName} includes another port`
        );
      }

      for (const innerPort of includedPort.ports) {
        const name = nameInnerPort(innerPort);

        const existingPort = flatPortMap[name];
        if (existingPort) {
          // Both definitions have this port. We need to merge
          if (innerPort.type === "s" && existingPort.type === "s") {
            // Second check to satisfy TS
            for (let i = 0; i < 3; i++) {
              const newBit = innerPort.bitmap[i];
              const existingBit = existingPort.bitmap[i];

              if (existingBit) {
                existingPort.bitmap[i] = existingBit;
              } else {
                existingPort.bitmap[i] = newBit;
              }
            }
          } else {
            if (
              innerPort.type !== "s" &&
              existingPort.type !== "s" &&
              !existingPort.bit
            ) {
              existingPort.bit = innerPort.bit;
            }
          }
        } else {
          // Def only on parent, copy it over
          flatPortMap[name] = innerPort;
        }
      }

      collapsedPorts[deviceName] = {
        ...port,
        ports: [...Object.values(flatPortMap)],
      };
    } else {
      collapsedPorts[deviceName] = port;
    }
  }

  return collapsedPorts;
};

const nameInnerPort = (port: Port): string => {
  if (port.type === "s") {
    return `s${port.index}`;
  }

  return port.type;
};

const parseButton = (button: string): Action | undefined => {
  switch (button) {
    case "IPT_JOYSTICK_UP":
      return "joyUp";
    case "IPT_JOYSTICK_DOWN":
      return "joyDown";
    case "IPT_JOYSTICK_LEFT":
      return "joyLeft";
    case "IPT_JOYSTICK_RIGHT":
      return "joyRight";

    case "IPT_JOYSTICKLEFT_UP":
      return "leftJoyUp";
    case "IPT_JOYSTICKLEFT_DOWN":
      return "leftJoyDown";
    case "IPT_JOYSTICKLEFT_LEFT":
      return "leftJoyLeft";
    case "IPT_JOYSTICKLEFT_RIGHT":
      return "leftJoyRight";

    case "IPT_JOYSTICKRIGHT_UP":
      return "rightJoyUp";
    case "IPT_JOYSTICKRIGHT_DOWN":
      return "rightJoyDown";
    case "IPT_JOYSTICKRIGHT_LEFT":
      return "rightJoyLeft";
    case "IPT_JOYSTICKRIGHT_RIGHT":
      return "rightJoyRight";

    case "IPT_BUTTON1":
      return "button1";
    case "IPT_BUTTON2":
      return "button2";
    case "IPT_BUTTON3":
      return "button3";
    case "IPT_BUTTON4":
      return "button4";
    case "IPT_BUTTON5":
      return "button5";
    case "IPT_BUTTON6":
      return "button6";
    case "IPT_BUTTON7":
      return "button7";
    case "IPT_BUTTON8":
      return "button8";

    case "IPT_START":
    case "IPT_START1":
      return "start1";
    case "IPT_START2":
      return "start2";

    case "IPT_SELECT":
      return "select";

    case "IPT_SERVICE1":
      return "service1";
    case "IPT_SERVICE2":
      return "service2";

    case "IPT_VOLUME_DOWN":
      return "volumeDown";
    case "IPT_POWER_ON":
      return "powerOn";
    case "IPT_POWER_OFF":
      return "powerOff";

    // Keypad is not supported
    case "IPT_KEYPAD":
      return "keypad";

    // Custom cannot be handled in an automated way
    case "IPT_CUSTOM":
      return "custom";

    case "IPT_UNUSED":
      return "unused";
  }

  return undefined;
};

const parsePortName = (
  name: string,
  deviceName: string
): PortType | undefined => {
  if (name.startsWith("IN.")) {
    // S input mapping
    return {
      type: "s",
      index: parseInt(name.slice(3)),
    };
  } else if (name === "ACL") {
    // ACL
    return { type: "acl" };
  } else if (name === "B") {
    // B input
    return { type: "b" };
  } else if (name === "BA") {
    // BA input
    return { type: "ba" };
  }
  if (name === "FAKE") {
    // Silently skip
  } else {
    console.log(`Unknown port ${name} for device ${deviceName}`);
  }

  return undefined;
};

const indexFromBit = (bit: number): number => {
  let value = bit;

  for (let count = 0; count < 4; count++) {
    if (value & 0x1) {
      return count;
    }

    value = value >> 1;
  }

  return 3;
};
