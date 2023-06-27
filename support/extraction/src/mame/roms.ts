const ROM_REGION_REGEX_BUILDER = (name: string) =>
  new RegExp(`ROM_START\\(\\s*${name}\\s*\\)([\\s\\S]*?)ROM_END`);

const ROM_DEFINITION_REGEX =
  /ROM_REGION\(.*?,\s*"maincpu(:melody)?"\s*,.*?\)\s*ROM_LOAD\(\s*"(.*?)".*?SHA1\((.*?)\)/gi;

type ROMSha = {
  name: string;
  sha: string;
};

export const parseRom = (
  content: string,
  deviceName: string
):
  | {
      rom: ROMSha;
      melody: ROMSha | undefined;
    }
  | undefined => {
  const regex = ROM_REGION_REGEX_BUILDER(deviceName);

  const match = content.match(regex);

  if (!match) {
    console.log(`Could not find ROM block for device ${deviceName}`);
    return;
  }

  const body = match[1];

  let melody: ROMSha | undefined = undefined;
  let rom: ROMSha | undefined = undefined;

  for (const match of body.matchAll(ROM_DEFINITION_REGEX)) {
    const name = match[2];
    const sha = match[3];

    if (match[1] == ":melody") {
      if (!!melody) {
        console.log(`Melody ROM name is already set for ${deviceName}`);
        return;
      }

      melody = {
        name,
        sha,
      };
    } else {
      if (!!rom) {
        console.log(`ROM name is already set for ${deviceName}`);
        return;
      }

      rom = { name, sha };
    }
  }

  if (!rom) {
    console.log(`Could not find ROM name for device ${deviceName}`);
    return;
  }

  return {
    rom,
    melody,
  };
};
