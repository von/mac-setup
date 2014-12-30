#!/bin/sh

######################################################################
#
# Configuration

# Home brew formula to install
FORMULA="\
  tmux \
  python \
  python3 \
  swig \
  keychain \
  pass \
  git tig \
  wget \
  markdown \
  ctags-exuberant \
  gpg2 \
  jrnl \
  mr \
  moreutils \
  vifm \
  "

CASKS="\
  google-chrome \
  google-drive \
  skype \
  dropbox \
  android-file-transfer \
  totalfinder \
  wesnoth \
  firefox \
  "

PIP_PACKAGES="\
  pyzmq \
  tornado \
  Jinja2 \
  ipython \
  readline \
  "
######################################################################

usage()
{
  cat <<-'END'
Usage: $0 [<options>]

Options:
  -h              Print help and exit.
END
}

######################################################################
#
# Binaries

BREW="brew"
PIP="pip"
RUBY="ruby"
SUDO="sudo"

######################################################################
#
# Determine MacOSX version

OSX_VERSION=$(sw_vers | grep ProductVersion | cut -f 2)

######################################################################
#
# Brew helper functions

brew_installed() {
  # Return 0 if forumula installed, 1 otherwise
  # Arguments: forumula
  _formula=${1}
  ${BREW} list ${_formula} >/dev/null 2>&1 && return 0
  return 1
}

brew_install() {
  # Install formula if not already installed
  # Arguments: forumla [<options>]
  _formula=$1
  message "Installing brew formula \"${@}\""
  brew_installed ${_formula} && return 0
  ${BREW} install ${_formula} "${@}"
}

cask_installed() {
  # Return 0 if cask forumula installed, 1 otherwise
  # Arguments: forumula
  _formula=${1}
  ${BREW} cask list ${_formula} >/dev/null 2>&1 && return 0
  return 1
}

cask_install() {
  # Install cask formula if not already installed
  # Arguments: forumla [<options>]
  _formula=$1
  message "Installing cask formula \"${@}\""
  cask_installed ${_formula} && return 0
  ${BREW} cask install ${_formula} "${@}"
}

######################################################################
#
# PIP helper functions

pip_installed() {
  # Return 0 if python package installed, 1 otherwise
  # Arguments: package
  _package=${1}
  ${PIP} freeze | grep ${_package} >/dev/null 2>&1 && return 0
  return 1
}

pip_install() {
  _package=$1
  message "Installing python package \"${@}\""
  pip_installed ${_package} && return 0
  ${PIP} install ${package}
}

######################################################################
#
# Top-level installation commands

install_homebrew() {
  # http://brew.sh
  command -v ${BREW} >/dev/null 2>&1 && return 0
  ${RUBY} -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  ${BREW} doctor
}

upgrade_homebrew() {
  echo "Updating homebrew"
  ${BREW} update
  ${BREW} upgrade
}

install_cask() {
  # http://caskroom.io/
  brew_install caskroom/cask/brew-cask
}

install_macvim() {
  # Overrides older version that comes with MacOSX
  brew_install macvim --override-system-vim
  echo "MacVim installed."
  echo "Note you may need to rebuild YouCompleteMe to pick up new python"
  echo "  libraries."
}

######################################################################

# Leading colon means silent errors, script will handle them
# Colon after a parameter, means that parameter has an argument in $OPTARG
while getopts ":h" opt; do
  case $opt in
    h) usage ; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
  esac
done

shift $(($OPTIND - 1))

######################################################################

message() {
  echo $*
}

debug() {
  echo $*
}

######################################################################

install_homebrew
upgrade_homebrew

for formula in ${FORMULA} ; do
  brew_install ${formula}
done

install_macvim

# For tmux
brew_install reattach-to-user-namespace --wrap-pbcopy-and-pbpaste

install_cask

for cask in ${CASKS} ; do
  cask_install ${cask}
done

for package in ${PIP_PACKAGES} ; do
  pip_install ${package}
done

# Upgrade pip to work with python3
pip3 install --upgrade pip

echo "Success."
exit 0
