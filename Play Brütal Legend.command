#!/bin/zsh
set -eu

launcher_dir=${0:A:h}
steam_root="$HOME/Library/Application Support/Steam"
app_id=225260
shim="$launcher_dir/render-priority.dylib"
log="$launcher_dir/last-launch.log"

vdf_values() {
    [[ -r "$2" ]] || return 0
    VDF_KEY="$1" /usr/bin/perl -ne '
        if (/^\s*"\Q$ENV{VDF_KEY}\E"\s+"((?:[^"\\]|\\.)*)"/) {
            my $value = $1;
            $value =~ s/\\(["\\])/$1/g;
            print "$value\n";
        }
    ' "$2"
}

find_game() {
    local library install_dir candidate
    while IFS= read -r library; do
        [[ -n "$library" ]] || continue
        install_dir="$(vdf_values installdir "$library/steamapps/appmanifest_$app_id.acf")"
        candidate="$library/steamapps/common/${install_dir:-BrutalLegend}/Buddha.app"
        if [[ -x "$candidate/Contents/MacOS/Buddha" ]]; then
            print -r -- "$candidate"
            return
        fi
    done < <(vdf_values path "$steam_root/steamapps/libraryfolders.vdf"; print -r -- "$steam_root")
}

if (( $# > 1 )) || [[ "${1:-}" != "" && "$1" != "--print-game-path" ]]; then
    print -u2 'Usage: Play Brütal Legend.command [--print-game-path]'
    exit 2
fi

game="${BRUTAL_LEGEND_APP:-$(find_game)}"
if [[ -z "$game" || ! -x "$game/Contents/MacOS/Buddha" ]]; then
    print -u2 'Brütal Legend was not found. Install the Steam Mac version or set BRUTAL_LEGEND_APP to the path to Buddha.app.'
    exit 1
fi
game=${game:A}
if [[ "${1:-}" == "--print-game-path" ]]; then
    print -r -- "$game"
    exit 0
fi
if /usr/bin/pgrep -qx Buddha; then
    print -u2 'Quit Brütal Legend before using this launcher.'
    exit 1
fi
if ! /usr/bin/pgrep -qx steam_osx; then
    print -u2 'Open Steam and sign in before using this launcher.'
    exit 1
fi
if [[ "$shim" == *:* ]]; then
    print -u2 'Move this folder to a path without colons so dyld can find the library.'
    exit 1
fi
if [[ ! -r "$shim" || "$launcher_dir/render-priority.c" -nt "$shim" || "$launcher_dir/build.sh" -nt "$shim" ]]; then
    "$launcher_dir/build.sh"
fi

cd "$launcher_dir"
exec /usr/bin/env SteamAppId="$app_id" SteamGameId="$app_id" \
    "DYLD_INSERT_LIBRARIES=$shim" "$game/Contents/MacOS/Buddha" 2>"$log"
