let cachedWindowsHash = []
const ENABLE_BSP = false
const GAP = 4

function bsp(windows, offsetX, offsetY, width, height) {
  if (windows.length == 0) { return; }
  if (windows.length == 1) {
    // render full width
    window = windows.shift()

    frame = window.frame()

    frame.x = offsetX + GAP
    frame.y = offsetY + GAP
    frame.width = width - GAP*2
    frame.height = height - GAP*2
    window.setFrame(frame)

    return;
  }

  if (width >= height) {
    // Landscape : Divide by width
    window = windows.shift()

    frame = window.frame()

    frame.x = offsetX + GAP
    frame.y = offsetY + GAP
    frame.width = width / 2 - GAP*2
    frame.height = height - GAP*2
    window.setFrame(frame)

    return bsp(windows, offsetX + (width / 2), offsetY, (width / 2), height)
  } else {
    // Portrait :: Divide by height
    window = windows.shift()

    frame = window.frame()

    frame.x = offsetX + GAP
    frame.y = offsetY + GAP
    frame.width = width - GAP*2
    frame.height = height / 2 - GAP*2
    window.setFrame(frame)

    return bsp(windows, offsetX, offsetY + (height / 2), width, (height / 2))
  }
}

Key.on('left', [ 'control', 'shift' ], function () {
  const all_windows = Space.active().windows()
  let windows = all_windows.filter((w) => w.isVisible()).map((w) => w.title())
  Phoenix.log(all_windows.filter((w) => w.isVisible()).length)
  Phoenix.log(windows)
});

function applyBsp() {
  if (!ENABLE_BSP) { return }

  const all_windows = Space.active().windows()
  let windows = all_windows.filter((w) => w.isVisible())
  var screen = Screen.main().flippedVisibleFrame();

  bsp(windows, screen.x, screen.y, screen.width, screen.height)
}

Key.on('down', [ 'control', 'shift' ], applyBsp)
Key.on('up', [ 'control', 'shift' ], Phoenix.reload)

Key.on('right', [ 'control', 'shift' ], function () {
  var screen = Screen.main().flippedVisibleFrame();
  var window = Window.focused();

  if (window) {
    // window.setTopLeft({
    //   x: screen.x + (screen.width / 2) - (window.frame().width / 2),
    //   y: screen.y + (screen.height / 2) - (window.frame().height / 2)
    // });

    frame = window.frame()
    Phoenix.log(frame.x, frame.y)
    frame.x -= 2

    window.setFrame(frame)
  }
})

function debugWindow(w) {
  let f = w.frame()
  return JSON.stringify({ title: w.title(), name: w.app().name(), hash: w.hash(), x: f.x, y: f.y, w: f.width, h: f.height })
}
Event.on('windowDidMove', function (w) { Phoenix.log(`Window did move ${w.frame().x}, ${w.frame().y}`) });
Event.on('appDidLaunch', applyBsp);
Event.on('appDidActivate', applyBsp);
Event.on('windowDidClose', function(w) {
  if (cachedWindowsHash.indexOf(w.hash()) == -1) { return }
  Phoenix.log(w.app().name())
  Phoenix.log(cachedWindowsHash)
  Phoenix.log(debugWindow(w)) ; Phoenix.log("window close")
  applyBsp()
})

Event.on('windowDidOpen', function(w) {
  cachedWindowsHash = Space.active().windows().map((w) => w.hash())
  Phoenix.log(debugWindow(w))
  Phoenix.log("window open")
  Phoenix.log(cachedWindowsHash)
  applyBsp()
})

Event.on('windowDidResize', function (w) {
  Phoenix.log(`Window did resize ${w.frame().width} x ${w.frame().height}`)

  // const all_windows = Space.active().windows()
  // let windows = all_windows.filter((w) => w.isVisible())
  // var screen = Screen.main().flippedVisibleFrame();

  // bsp(windows, 0, 0, screen.width, screen.height)
  var screen = Screen.main().flippedVisibleFrame();

  // w.setTopLeft({
  //     x: screen.x + (screen.width / 2) - (w.frame().width / 2),
  //     y: screen.y + (screen.height / 2) - (w.frame().height / 2)
  //   });
});

Phoenix.log('Reloaded')
