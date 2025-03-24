const config = [
  // links to be handled by finicky (for specific profiles) - see .finicky.js for config
  // --- personal
  { link: "https://www.youtube.com/playlist?list=WL", name: "Watch Later" },
  {
    name: "Youtube History",
    link: "https://www.youtube.com/feed/history",
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
    link: "https://home.personalcapital.com/page/login/app#/net-worth",
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
    name: "1337x",
    link: 'https://1337x.to/category-search/{argument name="query"}/Movies/1/',
  },
  {
    name: "Maps",
    link: "https://www.google.com/maps",
  },

  // --- work
  {
    name: "Dev",
    link: "http://localhost:3000/t/",
  },

  // links to send straight to chrome - use whatever the most recent chrome profile is
  {
    link: "chrome://settings/searchEngines",
    openWith: "Google Chrome",
    name: "Chrome Search Engines",
  },
  {
    name: "Chrome Extensions",
    link: "chrome://extensions",
    openWith: "Google Chrome",
  },
  {
    name: "Chrome History",
    link: "chrome://history/",
    openWith: "Google Chrome",
  },
  {
    name: "Branches",
    link: "https://github.com/gentrace/gentrace/branches",
    openWith: "Google Chrome",
  },
  {
    name: "PRs",
    link: "https://github.com/gentrace/gentrace/pulls?q=is%3Apr+author%3A%40me",
    openWith: "Google Chrome",
  },
  {
    name: "PR",
    link: 'https://github.com/gentrace/gentrace/pull/{argument name="pr"}',
    openWith: "Google Chrome",
  },

  // directories to open in finder
  {
    name: "Downloads",
    link: "~/Downloads/",
  },

  // directories to open in cursor
  {
    name: "Config",
    link: "~/.config/",
    openWith: "Cursor",
  },
  {
    name: "Gentrace",
    link: "~/code/gentrace/",
    openWith: "Cursor",
  },
  {
    name: "Gentrace Scripts",
    link: "~/code/gentrace-dev-shell-scripts/gentrace_aliases.sh",
    openWith: "Cursor",
  },
];

export default config;
