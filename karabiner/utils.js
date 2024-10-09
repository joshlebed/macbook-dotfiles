import stringify from "json-stable-stringify";
import jsonStringifyPrettyCompact from "json-stringify-pretty-compact";

export function formatJSON(data) {
  // First, use json-stable-stringify to sort the keys
  const stableJson = stringify(data);
  // Then, parse it back to an object and use json-stringify-pretty-compact for formatting
  return jsonStringifyPrettyCompact(JSON.parse(stableJson), {
    indent: 2,
    maxLength: 100,
  });
}
