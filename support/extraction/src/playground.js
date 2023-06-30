// Tool for playing with the JSON
const { readFileSync } = require("fs");

const contents = readFileSync("manifest.json").toString();

const json = JSON.parse(contents);

let string = "";

for (const device of Object.keys(json)) {
  string += `${device}\n`;
}
console.log(string);
