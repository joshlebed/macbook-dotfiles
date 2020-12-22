import fs from "fs";
import config from "./karabiner.js";
import crypto from "crypto";

const data = JSON.stringify(config, null, 2);
const hash = crypto.createHash("md5").update(data).digest("hex");
console.log(hash);
fs.writeFileSync("karabiner.json", data);
