#!/usr/bin/env bash
set -euo pipefail

XCODE_APP_EXPECTED="/Applications/Xcode.app"
XCODE_SELECT_EXPECTED="/Applications/Xcode.app/Contents/Developer"
MOZ_TREE_NAME="mozilla-unified"

check_homebrew() {
    if ! command -v brew; then
        echo >&2 "Homebrew not detected."
        return 1
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

install_homebrew() {
    echo >&2 "Trying to install Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo >&2 "Homebrew should be installed."
}

install_python() {
    local whichpython
    whichpython="$(command -v python3)" || whichpython=""
    if ! [ "$whichpython" = "/opt/homebrew/bin/python3" ]; then
        echo >&2 "Installing Homebrew Python 3..."
        brew install python@3.11
    fi
}

install_python_packages() {
    python3 -m pip install --user mercurial==6.1.4
}

check_mercurial() {
    if ! hg version >/dev/null 2>&1; then
        echo >&2 "Mercurial not found or properly configured"
        return 1
    fi
}

ff_bootstrap() {
    rm -rf bootstrap.py
    curl https://hg.mozilla.org/mozilla-central/raw-file/default/python/mozboot/bin/bootstrap.py -O
    python3 bootstrap.py --no-interactive
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
    # Try once to install homebrew for the user
    if ! check_homebrew; then
        install_homebrew
    fi

    PATH="$(check_homebrew):$PATH"
    export PATH

    check_xcode
    install_python
    install_python_packages
    check_mercurial

    ! [ -e "$MOZ_TREE_NAME" ] && ff_bootstrap
    pushd "$MOZ_TREE_NAME"
    # Remove the mozconfig which enables artifact builds by default.
    # To enable them again do:
    # cat >> $MOZ_TREE_NAME << EOF
    # ac_add_options --enable-artifact-builds
    # EOF
    {
        ./mach clobber
        hg up -C central
        rm -f "mozconfig"
        time ./mach build
    } || bad_tree
}

main "$@"
