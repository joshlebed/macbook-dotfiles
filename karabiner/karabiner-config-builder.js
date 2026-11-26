import crypto from "crypto";
import fs from "fs";
import config from "./karabiner.js";
import { formatJSON } from "./utils.js";

const out = "karabiner.json";
const data = formatJSON(config);

// --check: verify the output matches what karabiner.js generates; write nothing.
if (process.argv.includes("--check")) {
  const current = fs.existsSync(out) ? fs.readFileSync(out, "utf8") : null;
  if (current !== data) {
    console.error(`out of date: karabiner/${out}`);
    console.error("run `make karabiner`");
    process.exit(1);
  }
  console.log(`${out} up to date`);
  process.exit(0);
}

const hash = crypto.createHash("md5").update(data).digest("hex");
console.log(hash);
fs.writeFileSync(out, data);
