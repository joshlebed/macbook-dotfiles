import { exec } from "child_process";
import fs from "fs";

const fname = "./karabiner.js";

const build = () => {
  exec("node karabiner-config-builder.js", (error, stdout, stderr) => {
    if (error) {
      console.log(`error: ${error.message}`);
      return;
    }
    if (stderr) {
      console.log(`stderr: ${stderr}`);
      return;
    }
    console.log(`stdout: ${stdout}`);
  });
};

console.log("initial build...");
build();
console.log("watching for changes...");

fs.watchFile(fname, (curr, prev) => {
  console.log("changes detected");
  build();
});
