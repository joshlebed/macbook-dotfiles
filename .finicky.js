// ~/.finicky.js

// eventually figure out how to make this more portable per machine
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
  "*1337x.to*",
  "*wellsfargo.com*",
  "*www.google.com/maps*",
  "*maps.google.com*",
  "*login.onemedical.com*",
  "*soundcloud.com*",
  "*sweetgreen.com*",
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
