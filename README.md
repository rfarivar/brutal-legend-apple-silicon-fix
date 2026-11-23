# Brütal Legend — Apple Silicon Performance Fix

**A small, open-source workaround for severe frame-rate problems in the Steam Mac version of Brütal Legend on Apple Silicon.** It changes the scheduling priority of the game's render thread without modifying the game installation.

> **Tested result:** On an M2 Mac running macOS 27.0.1, the unmodified game ran poorly even with resolution and graphics settings reduced to minimum. With this launcher, gameplay became smooth at maximum graphics settings. This is a user-observed improvement, not a measured FPS benchmark. Other configurations have not yet been tested.

## The problem

The Mac port can exhibit unexpectedly low frame rates on Apple Silicon. Lowering the resolution and graphics quality may make the game look worse **without improving performance**.

During investigation on an M2 Mac:

- The four **efficiency cores** were heavily active while the **performance cores** were largely idle.
- GPU utilization hovered around **30%**, despite the poor frame rate.
- Reducing resolution and disabling graphics options did not resolve the issue.
- The game's thread named `Render Thread` had a scheduling priority of **3**.

After raising that specific thread's priority to **47**, the performance cores became active, and the game played smoothly even with graphics settings at maximum. In a separate three-second in-game CPU sample, the render thread spent **over 99.9%** of its sampled CPU time on performance cores.

**Interpretation:** The evidence points to render-thread scheduling as the performance bottleneck on the tested machine. It does not yet establish why the original priority was selected or whether all Apple Silicon Macs are affected.

## Quick start

### Requirements

- An Apple Silicon Mac with Rosetta support. **Verified:** M2, macOS 27.0.1.
- The **Mac version of Brütal Legend from Steam**, installed and available to your signed-in Steam account.
- Xcode or **Xcode Command Line Tools**, used to compile the helper locally.

To install the command-line tools if needed:

```sh
xcode-select --install
```

See [Apple's Rosetta documentation](https://support.apple.com/en-us/102527) for compatibility information.

### Run the fix

1. Clone or download this repository, keeping its files together.
2. Open Steam, sign in, and make sure Brütal Legend is **not** already running.
3. Double-click **`Play Brütal Legend.command`** in Finder, or run:

   ```sh
   ./'Play Brütal Legend.command'
   ```

The launcher locates the installed Steam game, builds and ad-hoc signs the small Intel helper on first use, then starts the game with the fix applied. It rebuilds the helper if `render-priority.c` or `build.sh` changes.

**To play without the fix:** quit the game and launch it normally from Steam. Nothing is permanently installed or patched.

## Finding the Steam installation

The launcher searches the default Steam location and additional Steam library folders registered in `libraryfolders.vdf`, including libraries on external drives.

To display the detected game path without starting it:

```sh
./'Play Brütal Legend.command' --print-game-path
```

If the game is in an unregistered location, specify its `Buddha.app` path. You can find that app in Steam using **Manage → Browse local files**.

```sh
BRUTAL_LEGEND_APP="/Volumes/Games/Steam Library/steamapps/common/BrutalLegend/Buddha.app" \
  ./'Play Brütal Legend.command'
```

## How it works

The game's executable is named `Buddha`. The workaround targets its thread named **`Render Thread`**, rather than increasing the priority of the entire game.

1. `build.sh` compiles `render-priority.c` into an **x86_64 dynamic library** and ad-hoc signs it for loading into the Intel game process running under Rosetta.
2. The launcher starts the installed executable with `DYLD_INSERT_LIBRARIES`, injecting that library **only for this launch**.
3. The library uses Mach-O `__interpose` to intercept `pthread_setname_np` and `pthread_setschedparam`.
4. When it identifies the named render thread using normal scheduling (`SCHED_OTHER`), it boosts scheduling priority up to **47** and intercepts later attempts to lower that priority.

The launch log can show a successful adjustment such as:

```text
Buddha Render Thread priority: 3 -> 47
```

macOS still decides which CPU core executes the thread; this workaround **does not pin threads to particular cores**. The observed shift onto performance cores is an outcome on the tested M2, not an explicit CPU-affinity setting.

For Steamworks initialization, the launcher uses the included `steam_appid.txt` and sets Steam app/game IDs for the direct game launch. See the [Steamworks API documentation](https://partner.steamgames.com/doc/api/steam_api).

## Safety, limitations, and troubleshooting

- **No game-file modifications:** The workaround uses the existing Steam installation and does not change system-wide scheduling preferences.
- **Reversible:** The changes apply only to the game process launched with this script and disappear when it exits.
- **Build from source:** The helper is compiled locally, so its implementation can be inspected before use.
- **Compatibility is not guaranteed:** Only the M2/macOS 27.0.1 combination has been verified. Updates to macOS, Steam, or the game could affect the workaround.
- **Steam overlay:** Behavior with direct launching has not been verified.
- **Game not found:** Confirm the Mac version is installed; use `--print-game-path` or set `BRUTAL_LEGEND_APP`.
- **Game already running:** Quit the original game before launching this version.
- **Steam not detected:** Open Steam and sign in first.
- **Build fails:** Confirm Xcode Command Line Tools are installed.

The launcher writes the game's standard error output to `last-launch.log` in the repository directory. Review the log before sharing it publicly; software logs can include personal information.

## Help validate it

If you try this on another Apple Silicon Mac, a report or issue with your **Mac model, macOS version, game version, and observed performance before/after** would be useful. Quantitative FPS or frame-time measurements are especially welcome. Please distinguish measured results from visual impressions.

## Attribution

Developed and tested by **Reza Farivar**, with coding assistance from OpenAI Codex.

## License

This project is released under the MIT License. See LICENSE for details.

Brütal Legend is the property of its respective rights holders. This project is an independent community workaround and is not affiliated with Double Fine Productions.
