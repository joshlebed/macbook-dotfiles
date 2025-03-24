// ~/.finicky.js
import { personalProfile, workProfile } from "./.finicky_env_constants.js";

// profiles
// if these need to change eventually, import them from a .env/.js/.json that can be gitignored and controlled per machine
const personal = personalProfile;
const work = workProfile;

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
