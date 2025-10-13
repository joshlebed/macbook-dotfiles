// ~/.finicky.js

// eventually figure out how to make this more portable per machine
const personal = "Personal";
// const work = "Gentrace";
// OVERRIDE WHILE NOT WORKING
const work = "Personal";

// browsers
const chrome = "Google Chrome";

// matches
const workMatches = [
  "*datadog*",
  "*localhost*",
  "*gentrace*",
  "*graphite.dev*",
];
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
  "*www.amazon.com*",
];

// openers
const workOpeners = ["Slack", "Microsoft Outlook", "Linear"];
const personalOpeners = ["Messages", "Messenger"];

export default {
  defaultBrowser: chrome,
  handlers: [
    {
      match: (url) => url.protocol === "slack",
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
      match: (url, options) => workOpeners.includes(options.opener.name),
      browser: { name: chrome, profile: work },
    },
    {
      match: (url, options) => personalOpeners.includes(options.opener.name),
      browser: { name: chrome, profile: personal },
    },
  ],
};
