import { ROMName } from "./types";

const ROM_REGION_REGEX_BUILDER = (name: string) =>
  new RegExp(`ROM_START\\(\\s*${name}\\s*\\)([\\s\\S]*?)ROM_END`);

const ROM_DEFINITION_REGEX =
  /ROM_REGION\(.*?,\s*"maincpu(:melody)?"\s*,.*?\)\s*ROM_LOAD\(\s*"(.*?)"/gi;

export const parseRom = (
  content: string,
  deviceName: string
): ROMName | undefined => {
  const regex = ROM_REGION_REGEX_BUILDER(deviceName);

  const match = content.match(regex);

  if (!match) {
    console.log(`Could not find ROM block for device ${deviceName}`);
    return;
  }

  const body = match[1];

  let melodyName: string | undefined = undefined;
  let romName: string | undefined = undefined;

  for (const match of body.matchAll(ROM_DEFINITION_REGEX)) {
    const name = match[2];

    if (match[1] == ":melody") {
      if (!!melodyName) {
        console.log(`Melody ROM name is already set for ${deviceName}`);
        return;
      }

      melodyName = name;
    } else {
      if (!!romName) {
        console.log(`ROM name is already set for ${deviceName}`);
        return;
      }

      romName = name;
    }
  }

  if (!romName) {
    console.log(`Could not find ROM name for device ${deviceName}`);
    return;
  }

  return {
    rom: romName!,
    melody: melodyName,
  };
};
