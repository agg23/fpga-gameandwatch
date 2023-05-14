export enum CPUType {
  sm5a,
  kb1013vk12,
  sm510,
  sm511,
  sm512,
  sm530,
  sm510_tiger,
  sm511_tiger1bit,
  sm511_tiger2bit,
}

export type Screen =
  | {
      type: "single";
      width: number;
      height: number;
    }
  | {
      type: "dual_vertical";

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
      type: "dual_horizontal";

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

export interface ConsoleSpecification {
  device: PresetDefinition;
}
