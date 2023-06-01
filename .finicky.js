// ~/.finicky.js

module.exports = {
  defaultBrowser: "Google Chrome",
  handlers: [
    {
      match: [
        "*federate?*", // match isenlink long urls
        "*IsenLink*", // match isenlink short urls
        "*console.aws.amazon.com*", // aws console links
      ],
      browser: "Firefox",
    },
  ],
};
