import { readFileSync, writeFileSync } from "fs";
import BitSet from "bitset";

const data = readFileSync("../../ROMs/Egg.gnw");

const output = [];

for (let i = 0x2f7700; i < 0x2f7700 + 0x16da0; i += 8) {
  const array = new Uint8Array([
    data[i],
    data[i + 1],
    data[i + 2],
    data[i + 3],
    data[i + 4],
    data[i + 5],
    data[i + 6],
    data[i + 7],
  ]);

  const set = new BitSet(array);

  const id = parseInt(set.slice(0, 9).toString(10), 10);

  const line = (id & 0x3c0) >> 6;
  const column = (id & 0x3c) >> 2;
  const row = id & 0x3;

  const idString = `${line}.${column}.${row}`;

  // TODO: This does not appear to work correctly
  const x = set.slice(10, 19).toString(10);
  const y = set.slice(20, 29).toString(10);
  const length = set.slice(30, 39).toString(10);

  output.push({
    id: `0x${id}`,
    idString,
    x,
    y,
    length,
  });
}

writeFileSync("dump.json", JSON.stringify(output));
