#!/usr/bin/env bash
set -euo pipefail

XCODE_APP_EXPECTED="/Applications/Xcode.app"
XCODE_SELECT_EXPECTED="/Applications/Xcode.app/Contents/Developer"
MOZ_TREE_NAME="mozilla-unified"
BREW_PATH="/opt/homebrew/bin"

install_homebrew() {
    echo >&2 "Trying to install Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    PATH="$BREW_PATH:$PATH"
    export PATH
    echo >&2 "Homebrew should be installed."
}

check_homebrew() {
    if ! command -v brew >/dev/null 2>&1; then
        echo >&2 "Homebrew not detected."
        install_homebrew
    fi
}

check_xcode() {
    local xcode_path
    if ! [ -e "$XCODE_APP_EXPECTED" ]; then
        echo >&2 "Install Xcode from the app store first."
        return 1
    fi
    xcode_path="$(xcode-select -p)" || xcode_path=""
    if [ -z "$xcode_path" ] || ! [ "$xcode_path" = "$XCODE_SELECT_EXPECTED" ]; then
        echo >&2 "Xcode path needs changing."
        echo >&2 "Make sure Xcode is installed, then run:"
        echo >&2 "  sudo xcode-select --switch /Applications/Xcode.app"
        return 1
    fi

    echo >&2 "Now running Xcode initial setup. Please authenticate and follow"
    echo >&2 "the instructions to accept the license agreement, if needed."
    xcodebuild -runFirstLaunch
}

install_python(){
    echo >&2 "Installing Homebrew Python 3..."
    brew install python@3.11
}

check_python() {
    if ! command -v python3 >/dev/null 2>&1; then
        echo >&2 "python3 not detected."
        install_python
    fi
}

install_mercurial() {
    python3 -m pip install mercurial==6.1.4
}

check_mercurial() {
    if ! hg version >/dev/null 2>&1; then
        echo >&2 "Mercurial not found or properly configured"
        install_mercurial
    fi
}

ff_bootstrap() {
    if ! [ -e "$MOZ_TREE_NAME" ]; then
        rm -rf bootstrap.py
        curl https://hg.mozilla.org/mozilla-central/raw-file/default/python/mozboot/bin/bootstrap.py -O
        # Choice #2 is full build without artifacts
        python3 bootstrap.py --no-interactive --application-choice="Firefox for Desktop"
    else
        pushd "$MOZ_TREE_NAME"
        ./mach --no-interactive bootstrap --application-choice="Firefox for Desktop"
        popd
    fi
}

bad_tree() {
    echo >&2
    echo >&2 "Something unexpected happened. Most likely you can remove the"
    echo >&2 "source tree:"
    echo >&2 "  rm -rf $MOZ_TREE_NAME"
    echo >&2 "and try again."
    exit 1
}

main() {
    check_homebrew
    check_xcode
    check_python
    check_mercurial

    ff_bootstrap
    {
        pushd "$MOZ_TREE_NAME"
        ./mach clobber
        hg up -C central
        time ./mach build
        popd
    } || bad_tree
}

main "$@"
