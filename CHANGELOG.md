# Release notes

## 1.3.1 (November 25, 2026)

The zoom keys also work with Cmd or Control held down: Cmd-= and Cmd-- zoom in and out, and Cmd-0 goes back to fit, like they do in most Mac apps.

## 1.3.0 (November 25, 2026)

Added zoom. `+` and `-` zoom in and out in 1.5x steps, up to 32x. Drag with the mouse or use `I` `J` `K` `L` to move around while zoomed. `0`, Control-0, and Escape go back to fit, and Escape from fit still closes the image.

Zooming loads the full-resolution image in the background. Before this version, the app only ever held a screen-sized copy of each image.

## 1.2.0 (November 18, 2026)

Added the slideshow. `S` or Space starts and stops it, it loops at the end, and it always starts paused. The default is 4 seconds per image; `A` and `D` change that (1 to 99 seconds), and the app remembers the setting.

Moving the mouse shows a play / pause control in the lower right. `?` shows a sheet with all of the keyboard shortcuts.

## 1.1.0 (November 18, 2026)

Folders can be opened from Finder through right-click -> Services -> "Open in Fastest Slideshow." Finder does not offer "Open With" for folders, so the app registers a service instead.

Skipping 10 images flashes `+10` or `-10` over the image. Enter toggles full screen. The metadata sidebar shows caption, date, location, and keywords first. The app has an icon and an About panel.

## 1.0.0 (November 17, 2026)

First version: full-screen viewing of a folder or a single image, arrow keys and `J` / `K` to change images, Shift or Control to skip 10, `F` for full screen, and `I` for a metadata sidebar.
