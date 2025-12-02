// quickstart: quicklinks-dev
// see raycast/README.md for more instructions

// links to be handled by finicky (for specific profiles) - see .finicky.js for config

// --- personal
const personalLinks = [
  { link: "https://www.youtube.com/playlist?list=WL", name: "Watch Later" },
  {
    name: "Youtube History",
    link: "https://www.youtube.com/feed/history",
  },
  {
    name: "Youtube",
    link: "https://www.youtube.com/",
  },
  {
    name: "Soundcloud",
    link: "https://soundcloud.com/feed",
  },
  {
    name: "Sweetgreen",
    link: "https://order.sweetgreen.com/reorder",
  },
  {
    name: "Amex",
    link: "https://www.americanexpress.com/en-us/account/login",
  },
  {
    name: "BofA",
    link: "https://secure.bankofamerica.com/login/sign-in/signOnV2Screen.go",
  },
  {
    name: "Chase Bank",
    link: "https://secure.chase.com/web/auth/dashboard#/dashboard/index/index",
  },
  {
    name: "Net Worth",
    link: "https://ira.empower-retirement.com",
  },
  {
    name: "Budget",
    link: "https://home.personalcapital.com/page/login/app#/all-transactions/CREDIT_CARD",
  },
  {
    name: "TD Bank",
    link: "https://onlinebanking.tdbank.com/#/authentication/login",
  },
  {
    name: "Venmo",
    link: "https://id.venmo.com/signin",
  },
  {
    name: "Wells Fargo",
    link: "https://connect.secure.wellsfargo.com/auth/login/present?origin=cob",
  },
  {
    name: "1337x pirate",
    link: 'https://1337x.to/category-search/{argument name="query"}/Movies/1/',
  },
  {
    name: "Maps",
    link: "https://maps.google.com/",
  },
  {
    name: "One Medical",
    link: "https://login.onemedical.com/login",
  },
  {
    name: "Amazon",
    link: "https://www.amazon.com/",
  },
];

// --- work
const workLinks = [
  {
    name: "Dev",
    link: "http://localhost:3000/t/",
  },
  {
    name: "PRs",
    // link: "https://github.com/gentrace/gentrace/pulls?q=is%3Apr+author%3A%40me",
    // link: "https://github.com/StructifyAI/agent/pulls?q=is%3Apr+author%3A%40me",
    // link: "https://github.com/keru-ai/dev-runner/issues?q=is%3Apr+author%3Ajosh-kepler",
    link: "https://github.com/pulls?q=is%3Apr+org%3Akeru-ai+author%3Ajosh-kepler+",
  },
  {
    name: "Graphite",
    link: "https://app.graphite.dev/",
  },
];

// links to send straight to chrome - use whatever the most recent chrome profile is
const chromeLinks = [
  {
    link: "chrome://settings/searchEngines",
    name: "Chrome Search Engines",
  },
  {
    name: "Chrome Extensions",
    link: "chrome://extensions",
  },
  {
    name: "Chrome History",
    link: "chrome://history/",
  },
  {
    name: "Branches",
    link: "https://github.com/gentrace/gentrace/branches",
  },
  {
    name: "PR",
    link: 'https://github.com/gentrace/gentrace/pull/{argument name="pr"}',
  },
];

// directories to open in finder
const finderLinks = [
  {
    name: "Downloads",
    link: "~/Downloads/",
  },
  {
    name: "Soulseek",
    link: "~/Music/soulseek",
  },
];

// directories to open in cursor
const cursorLinks = [
  {
    name: "Config",
    link: "~/.config/",
  },
  {
    name: "Gentrace",
    link: "~/code/gentrace/",
  },
  {
    name: "Gentrace Scripts",
    link: "~/code/gentrace-dev-shell-scripts/gentrace_aliases.sh",
  },
  {
    name: "Libsync",
    link: "~/code/lib-sync/",
  },
];

const config = [
  ...personalLinks,
  ...workLinks,
  ...chromeLinks.map((link) => ({
    ...link,
    openWith: "Google Chrome",
  })),
  ...finderLinks,
  ...cursorLinks.map((link) => ({
    ...link,
    openWith: "Cursor",
  })),
];

export default config;
