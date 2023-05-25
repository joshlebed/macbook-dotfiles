// ~/.finicky.js

module.exports = {
  defaultBrowser: "Google Chrome",
  handlers: [
    {
      match: [
        "*federate?*", // match isenlink long urls
        "*IsenLink*", // match isenlink short urls
      ],
      browser: "Firefox",
    },
  ],
};
