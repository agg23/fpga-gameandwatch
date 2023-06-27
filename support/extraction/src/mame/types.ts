export type CPUType =
  | "sm5a"
  | "kb1013vk12"
  | "sm510"
  | "sm511"
  | "sm512"
  | "sm530"
  | "sm510_tiger"
  | "sm511_tiger1bit"
  | "sm511_tiger2bit";

export type Screen =
  | {
      type: "single";
      width: number;
      height: number;
    }
  | {
      type: "dualVertical";

      top: {
        width: number;
        height: number;
      };

      bottom: {
        width: number;
        height: number;
      };
    }
  | {
      type: "dualHorizontal";

      left: {
        width: number;
        height: number;
      };

      right: {
        width: number;
        height: number;
      };
    };

export interface PresetDefinition {
  cpu: CPUType;

  screen: Screen;
}

export interface PlatformSpecification {
  device: PresetDefinition;
  portMap: PlatformPortMapping;
  metadata: Metadata;
  rom: ROMName;
}

export interface ROMName {
  rom: string;
  melody: string | undefined;
  romOwner?: string;
  romHash: string;
}

export interface Metadata {
  year: string;
  company: string;
  name: string;
}

/* Inputs */

export type Action =
  | "joyUp"
  | "joyDown"
  | "joyLeft"
  | "joyRight"
  | "leftJoyUp"
  | "leftJoyDown"
  | "leftJoyLeft"
  | "leftJoyRight"
  | "rightJoyUp"
  | "rightJoyDown"
  | "rightJoyLeft"
  | "rightJoyRight"
  | "button1"
  | "button2"
  | "button3"
  | "button4"
  | "button5"
  | "button6"
  | "button7"
  | "button8"
  | "select"
  | "start1"
  | "start2"
  | "service1"
  | "service2"
  | "volumeDown"
  | "powerOn"
  | "powerOff"
  // Keypad is not supported
  | "keypad"
  | "custom"
  | "unused";

export interface NamedAction {
  action: Action;
  activeLow: boolean;
  name?: string;
}

export type UndfAction = NamedAction | undefined;

export type Port =
  | {
      type: "s";
      /**
       * IN.#
       */
      index: number;

      bitmap: [UndfAction, UndfAction, UndfAction, UndfAction];
    }
  | {
      type: "acl" | "b" | "ba";

      bit: UndfAction;
    };

export interface PlatformPortMapping {
  ports: Port[];
  include?: string;
  groundLastIndex?: number;
}
