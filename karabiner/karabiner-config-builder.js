import crypto from "crypto";
import fs from "fs";
import config from "./karabiner.js";
import { formatJSON } from "./utils.js";

const data = formatJSON(config);
const hash = crypto.createHash("md5").update(data).digest("hex");
console.log(hash);
fs.writeFileSync("karabiner.json", data);
