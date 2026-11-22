# Brütal Legend render priority on Apple silicon

This launcher raises the Steam Mac port's `Render Thread` to scheduling priority 47 when the thread would otherwise run at a lower priority. macOS continues to schedule the thread. On the tested M2, the thread went from priority 3 to 47 and spent over 99.9% of its sampled CPU time on performance cores during a three-second in-game sample. The owner reported that the game ran better.

## Requirements

- An Apple silicon Mac with Rosetta support for this game. Verified on an M2 with macOS 27.0.1. Other Macs and macOS releases have not been tested.
- The Intel macOS Steam build of Brütal Legend, installed through Steam. Open Steam and sign in to an account with access to the game.
- Xcode or the Xcode Command Line Tools to compile the small Intel helper locally. To install the command-line tools, run `xcode-select --install` in Terminal.

See [Apple's Rosetta support information](https://support.apple.com/en-us/102527) for macOS compatibility.

## Launch

1. Clone or download this repository and keep its files together.
2. Quit the game if it is running and leave Steam open.
3. Double-click `Play Brütal Legend.command` in Finder, or run it from Terminal:

   ```sh
   ./'Play Brütal Legend.command'
   ```

The launcher builds the helper on first use and rebuilds it when its source or build script changes. The default Steam library and additional libraries registered in `libraryfolders.vdf` are searched automatically, including libraries on external drives. Standard Steam paths are resolved relative to the current user's home directory.

To check which copy it found without launching the game:

```sh
./'Play Brütal Legend.command' --print-game-path
```

For an unregistered library or to select a specific copy, give the launcher the path to the Steam game's `Buddha.app`. In Steam, use **Manage → Browse local files** to find it.

```sh
BRUTAL_LEGEND_APP="/Volumes/Games/Steam Library/steamapps/common/BrutalLegend/Buddha.app" \
  ./'Play Brütal Legend.command'
```

## How it works

`build.sh` compiles and ad-hoc signs an Intel dynamic library because the game runs as an Intel process under Rosetta. The launcher loads the library into that one game process using `DYLD_INSERT_LIBRARIES`. Steamworks uses the bundled `steam_appid.txt` in the working directory to recognize the direct launch. [Steamworks API documentation](https://partner.steamgames.com/doc/api/steam_api)

`render-priority.c` hooks the thread naming and scheduling calls. It raises the named render thread's normal scheduling priority when the thread starts and guards against later attempts to lower it. The launch log records the initial priority change, for example `Buddha Render Thread priority: 3 -> 47`.

The effect ends when the game quits. To use the original settings, start the game from Steam. The launcher uses the installed game and does not edit its files or change system scheduling settings. Steam overlay behavior with this direct launch has not been verified.
