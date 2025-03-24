// ~/.finicky.js

// profiles
const personal = "Default";
const work = "Profile 1";

// browsers
const chrome = "Google Chrome";

// matches
const workMatches = ["*datadog*", "*localhost*", "*gentrace*"];
const personalMatches = [
  "*www.americanexpress.com*",
  "*bankofamerica.com*",
  "*chase.com*",
  "*tdbank.com*",
  "*venmo.com*",
  "*personalcapital.com*",
  "*onlinebanking.tdbank.com*",
  "*youtube.com*",
];

// openers
const workOpeners = ["Slack", "Microsoft Outlook", "Linear"];
const personalOpeners = ["Messages", "Messenger"];

module.exports = {
  defaultBrowser: chrome,
  handlers: [
    {
      match: ({ url }) => url.protocol === "slack",
      browser: "/Applications/Slack.app",
    },
    {
      match: workMatches,
      browser: { name: chrome, profile: work },
    },
    {
      match: personalMatches,
      browser: { name: chrome, profile: personal },
    },
    {
      match: ({ opener }) => workOpeners.includes(opener.name),
      browser: { name: chrome, profile: work },
    },
    {
      match: ({ opener }) => personalOpeners.includes(opener.name),
      browser: { name: chrome, profile: personal },
    },
  ],
};
