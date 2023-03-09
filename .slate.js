slate.log("reloaded slate");

const pad = (object, width, direction = "left") =>
  direction == "left"
    ? (`${object}` + " ".repeat(width)).slice(0, width)
    : (" ".repeat(width) + `${object}`).slice(-width);

// TODO: currently length 12 is hardcoded, make this smarter if we add more prefixes
const blacklist_prefixes = new Set(["Find in page", "MenuBarCover"]);
const debugWindow = (window, label) => {
  const rect = window.rect();
  const left = rect.x;
  const width = rect.width;
  slate.log(
    `window: ` +
      pad(label, 10) +
      ` ` +
      pad(left, 5) +
      `, ` +
      pad(left + width, 5) +
      ` ` +
      pad(window.pid(), 10) +
      ` ` +
      pad(window.app().name(), 20) +
      ` ` +
      pad(window.title(), 30) +
      " "
  );
};

const hashString = (str) => {
  var hash = 0,
    i,
    chr;
  for (i = 0; i < str.length; i++) {
    chr = str.charCodeAt(i);
    hash = (hash << 5) - hash + chr;
    hash |= 0; // Convert to 32bit integer
  }
  return hash;
};

const hashWindow = (win) => {
  return hashString(
    JSON.stringify({
      title: win.title(),
      pid: win.pid(),
      appName: win.app().name(),
      x: win.rect().x,
      y: win.rect().y,
      width: win.rect().width,
      height: win.rect().height,
    })
  );
};

const sameRect = (rect, otherRect) => {
  return (
    rect.x == otherRect.x &&
    rect.y == otherRect.y &&
    rect.width == otherRect.width &&
    rect.height == otherRect.height
  );
};

const sameWindow = (win, otherWin) => {
  return (
    sameRect(win.rect(), otherWin.rect()) &&
    win.title() == otherWin.title() &&
    win.pid() == otherWin.pid() &&
    win.app().name() == otherWin.app().name()
  );
};

const windowSorter = (winA, winB) => {
  const xDelta = getCenterX(winA) - getCenterX(winB);
  const appNameDiff = hashString(winA.title()) - hashString(winB.title());
  const hashDelta = hashWindow(winA) - hashWindow(winB);
  if (xDelta < 0) return -1;
  else if (xDelta > 0) return 1;
  else {
    if (appNameDiff < 0) return -1;
    else if (appNameDiff > 0) return 1;
    else {
      if (hashDelta < 0) return -1;
      else return 1;
    }
  }
};

const validWindow = (win) => {
  const title = win.title();
  return (
    !win.isMinimizedOrHidden() &&
    title.length > 0 &&
    !blacklist_prefixes.has(title.substring(0, 12))
  );
};

const getCenterX = (win) => {
  const rect = win.rect();
  return rect.x + rect.width / 2;
};

const directionalFocus = (currentWin, direction) => {
  if (currentWin == null || !validWindow(currentWin)) {
    slate.log("debug: null currentWin");
    target = null;
    slate.eachApp((app) => {
      app.eachWindow((win) => {
        if (target == null && validWindow(win)) {
          target = win;
        }
      });
    });
  } else {
    debugWindow(currentWin, "-> current");
    var target = null;
    const windows = [];
    slate.eachApp((app) => {
      app.eachWindow((win) => {
        debugWindow(win, "        found window: ");
        if (validWindow(win) | sameWindow(win, currentWin)) {
          windows.push(win);
        }
      });
    });
    windows.sort(windowSorter);
    windows.forEach((win) => {
      slate.log(`debug:      ` + pad(win.app().name(), 20) + "");
    });
    if (direction == "left") {
      windows.reverse();
    }
    index = null;
    windows.forEach((win, i) => {
      if (sameWindow(win, currentWin)) {
        index = i;
      }
    });
    if (index != undefined && index + 1 < windows.length) {
      target = windows[index + 1];
    }
  }
  if (target != null) {
    debugWindow(target, "-> target");
    target.focus();
    return;
  }
  slate.log("didn't switch windows");
};

slate.bind("f16", function (win) {
  directionalFocus(win, "right");
});

slate.bind("f16:shift", function (win) {
  directionalFocus(win, "left");
});
