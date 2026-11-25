# Fastest Slideshow

Fastest Slideshow is a native Mac image viewer that opens a folder of images full screen and gets out of the way. It decodes each image at screen resolution instead of full resolution, preloads the next and previous images, and uses a borderless window instead of a macOS full-screen Space, so there is no animation when it opens or when you change images.

It is one Swift file with no dependencies, and the download is about 130 KB. It requires an Apple Silicon Mac running macOS 13 or later.

## Download

Get the zip from the [latest release](https://github.com/ehcheng/fastest_slideshow/releases/latest). Unzip it and drag Fastest Slideshow into /Applications.

The app is signed with my Developer ID and notarized by Apple, so it opens without a Gatekeeper warning.

## Using it

Open a folder or an image (see "Opening from Finder" below, or launch the app and pick something in the Open dialog). The first image appears full screen, and the slideshow is paused until you start it.

If you open a single image, you get that image and can browse the rest of its folder. If you open a folder, you get the images directly inside it (subfolders are ignored).

| Key | What it does |
| --- | --- |
| Right / `J` | Next image (the last image rolls over to the first) |
| Left / `K` | Previous image (the first image rolls over to the last) |
| Shift or Control + Left / Right / `J` / `K` | Skip 10 images (flashes `+10` or `-10`) |
| `S` / Space | Play or pause the slideshow (it loops at the end) |
| `A` / `D` | Fewer / more seconds per image (default 4, remembered) |
| `+` / `=` / `-` (alone, or with Cmd or Control) | Zoom in / out |
| Drag, or `I` `J` `K` `L` | Move around while zoomed |
| `0` / Cmd-0 / Control-0 | Back to fit |
| `F` / Enter | Toggle full screen |
| `I` | Toggle the metadata sidebar |
| `?` | Show the list of shortcuts |
| Escape | Back to fit if zoomed; otherwise, close the image (the app keeps running) |
| Cmd-O / Cmd-Q | Open / quit |

`I`, `J`, and `K` do different things depending on zoom. When the image fits the window, `I` toggles the sidebar and `J` / `K` change images. Once you zoom in, `I` `J` `K` `L` scroll up, left, down, and right, and `0` or Escape gets you back to fit.

Zoom goes in 1.5x steps up to 32x and resets when you change images. The first time you zoom in on an image, the app loads the full-resolution file in the background and swaps it in, so a large file can look soft for a moment.

Moving the mouse shows a play / pause button in the lower right for 2 seconds. While the slideshow is playing, it also shows seconds per image with up and down arrows.

The metadata sidebar shows caption, date, location, and keywords at the top, followed by the rest of the metadata in the file.

Control + arrow keys are Mission Control shortcuts by default in macOS. If they switch Spaces instead of skipping 10 images, use Shift + arrow keys, or turn those shortcuts off in System Settings -> Keyboard -> Keyboard Shortcuts -> Mission Control.

## Opening from Finder

Finder does not offer "Open With" for folders, so the app registers a service instead. Right-click a folder -> Services (or Quick Actions) -> "Open in Fastest Slideshow." The service appears after the app is in /Applications and has been launched once. If it is missing, enable it in System Settings -> Keyboard -> Keyboard Shortcuts -> Services -> Files and Folders. You can give it a keyboard shortcut there, too.

For a single image, right-click -> Open With -> Fastest Slideshow (the service works for images as well).

To make Fastest Slideshow the default app for a type of image, select a file of that type in Finder, press Cmd-I (Get Info), choose Fastest Slideshow under "Open with," and click "Change All..." After that, double-clicking an image opens it full screen with the rest of its folder ready to browse. You have to do this once per file type (JPEG, HEIC, PNG, and so on).

You can also drag a folder or images onto the app icon in the Dock, or use Terminal:

```bash
open -a "Fastest Slideshow" /path/to/folder
```

If you prefer the Shortcuts app, make a new shortcut with the "Open File" action, set it to open "Shortcut Input" with Fastest Slideshow, and enable "Use as Quick Action" for Finder. It then shows up under right-click -> Quick Actions.

## Building from source

You need the Xcode command line tools. There is no Xcode project.

```bash
./build.sh            # ad-hoc signed, for the Mac you built it on
./build.sh --release  # Developer ID signed and notarized, for other Macs
```

The output is `builds/FastestSlideshow-<version>.zip`. `--release` reads signing credentials from `~/.vpm-signing.json` (`identity`, `appleId`, `password`, `teamId`), so you will need your own.

The version lives in `Info.plist` (`CFBundleShortVersionString` and `CFBundleVersion`). `make_icon.swift` generates the icon; its first line says how to run it. `publish.sh` uploads the zip to my server and will not be useful to anyone else.

There is a headless self-check that lists a folder, decodes an image, and prints its metadata:

```bash
B="build/Fastest Slideshow.app/Contents/MacOS/Fastest Slideshow"
"$B" --check /path/to/image-or-folder
```

## Release notes

See [CHANGELOG.md](CHANGELOG.md).
