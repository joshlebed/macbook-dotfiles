// ~/.finicky.js

// eventually figure out how to make this more portable per machine
const personal = "Personal";
// const work = "Gentrace";
// const work = "Kepler";
const work = "Niteshift";

// browsers
const chrome = "Google Chrome";

// matches
const workMatches = [
  "*datadog*",
  "*localhost*",
  "*gentrace*",
  "*keru*",
  "*kepler*",
  "*graphite.dev*",
  "*niteshift.dev*",
  "*niteshift.local*",
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

// tracking params to strip
const removeExact = new Set([
  "fbclid", "gclid", "dclid", "gbraid", "wbraid", "msclkid", "ttclid",
  "twclid", "li_fat_id", "mkt_tok", "mc_cid", "mc_eid", "igsh", "si",
  "feature", "ref", "ref_src", "spm",
]);
const removePrefixes = ["utm_", "uta_", "ga_", "pk_", "vero_"];
const removeByValue = new Set(["share", "social", "social_media", "social_network"]);

export default {
  defaultBrowser: chrome,
  options: {
    checkForUpdates: true,
    logRequests: false,
    keepRunning: true,
    hideIcon: true,
  },
  rewrite: [
    {
      // Strip tracking/marketing params from all URLs
      match: () => true,
      url: (url) => {
        const keys = [...url.searchParams.keys()];
        for (const key of keys) {
          const k = key.toLowerCase();
          const v = (url.searchParams.get(key) || "").toLowerCase();
          const isExact = removeExact.has(k);
          const isPrefix = removePrefixes.some((p) => k.startsWith(p));
          const isValueNoise =
            (k === "source" || k === "src" || k === "medium") &&
            removeByValue.has(v);
          if (isExact || isPrefix || isValueNoise) {
            url.searchParams.delete(key);
          }
        }
        return url;
      },
    },
    {
      // Rewrite slack.com web URLs to slack:// deep links
      match: "*.slack.com/*",
      url: (url) => {
        const subdomain = url.host.slice(0, -".slack.com".length);
        if (subdomain === "app") {
          const pathMatch = url.pathname.match(
            /\/client\/(\w+)\/(\w+)(?:\/([\d.]+))?/
          );
          if (pathMatch) {
            const [, team, channel, message] = pathMatch;
            let search = `team=${team}&id=${channel}`;
            if (message) search += `&message=${message}`;
            return new URL(`slack://channel?${search}`);
          }
        }
        return url;
      },
    },
  ],
  handlers: [
    {
      match: (url) => url.protocol === "slack:",
      browser: "/Applications/Slack.app",
    },
    {
      match: workMatches,
      browser: `${chrome}:${work}`,
    },
    {
      match: personalMatches,
      browser: `${chrome}:${personal}`,
    },
    {
      match: (url, options) =>
        options.opener && workOpeners.includes(options.opener.name),
      browser: `${chrome}:${work}`,
    },
    {
      match: (url, options) =>
        options.opener && personalOpeners.includes(options.opener.name),
      browser: `${chrome}:${personal}`,
    },
  ],
};
