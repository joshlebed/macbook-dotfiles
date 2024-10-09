import fs from "fs";
import { formatJSON } from "./utils.js";

// Path to the karabiner.json file
const karabinerConfigPath = "karabiner.json";

try {
  // Read the existing karabiner.json file
  const rawData = fs.readFileSync(karabinerConfigPath, "utf8");

  // Parse the JSON data
  const config = JSON.parse(rawData);

  // Use the shared formatJSON function with 2 spaces for indentation
  const formattedData = formatJSON(config);

  // Write the formatted data back to the file
  fs.writeFileSync(karabinerConfigPath, formattedData);

  console.log("Karabiner config has been formatted and saved successfully.");
} catch (error) {
  console.error(
    "An error occurred while formatting the Karabiner config:",
    error.message
  );
}
