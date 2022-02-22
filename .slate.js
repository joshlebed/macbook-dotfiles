const debug = true;
const bigDebug = false;

if (debug) slate.log("debug: reloaded");
const pad = (object, width, direction = "left") =>
  direction == "left"
    ? (`${object}` + " ".repeat(width)).slice(0, width)
    : (" ".repeat(width) + `${object}`).slice(-width);

const blacklist = ["Find in page*", "Bloomberg Anywhere"];
const debugWindow = (window, label) => {
  const rect = window.rect();
  const left = rect.x;
  const width = rect.width;
  const x = left + width / 2;
  if (debug)
    slate.log(
      `debug: ` +
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
    !blacklist.reduce(
      (result, regex) => result || title.match(regex) != null,
      false
    )
  );
};

const getCenterX = (win) => {
  const rect = win.rect();
  return rect.x + rect.width / 2;
};

const directionalFocus = (currentWin, direction) => {
  if (bigDebug) slate.log("running");
  if (currentWin == null) {
    if (debug) slate.log("debug: null currentWin");
    target = null;
    slate.eachApp((app) => {
      app.eachWindow((win) => {
        if (target == null && validWindow(win)) {
          target = win;
        }
      });
    });
  } else {
    if (debug) debugWindow(currentWin, "-> current");
    var target = null;
    const windows = [];
    slate.eachApp((app) => {
      app.eachWindow((win) => {
        if (validWindow(win)) {
          windows.push(win);

          // const x = getCenterX(win);
          // const xDiff = multiplier * (x - currentX);
          // const hashDiff =
          //   multiplier * (hashWindow(win) - hashWindow(currentWin));
          // // debugWindow(win, "  (maybe)");
          // // if (debug)
          // // slate.log("debug:     diff " + xDiff + " tiebreaker " + hashDiff);

          // slate.log(
          //   `debug:      ` +
          //     pad(win.app().name(), 20) +
          //     " xDiff:" +
          //     pad(xDiff, 6, "right") +
          //     " hashDiff:" +
          //     pad(hashDiff, 15, "right") +
          //     ""
          // );
          // if (xDiff >= 0 && xDiff < minXDiff) {
          //   if (xDiff > 0) {
          //     minXDiff = xDiff;
          //     minHashDiff = hashDiff;
          //     target = win;
          //   } else if (hashDiff > 0 && hashDiff < minHashDiff) {
          //     minXDiff = xDiff;
          //     minHashDiff = hashDiff;
          //     target = win;
          //   }
          // }
        }
      });
    });
    windows.sort(windowSorter);
    windows.forEach((win) => {
      if (debug) slate.log(`debug:      ` + pad(win.app().name(), 20) + "");
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
    if (debug) slate.log("debug: ");
    target.focus();
    if (bigDebug) slate.log("done!");
    return;
  }
  if (bigDebug) slate.log("done, no action");
};

slate.bind("f16", function (win) {
  directionalFocus(win, "right");
  // if (debug) slate.log("AAAAAAAAA");
});

slate.bind("f16:shift", function (win) {
  directionalFocus(win, "left");
  // if (debug) slate.log("BBBBBBBBB");
});
