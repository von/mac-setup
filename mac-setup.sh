#!/bin/sh
# Set up a Mac the way I like it
#
# Kudos:
# https://gist.github.com/brandonb927/3195465

######################################################################
#
# Configuration

HOSTNAME=""  # Default is not to set hostname

######################################################################

usage()
{
  cat <<-'END'
Usage: $0 [<options>]

Options:
  -h              Print help and exit.
  -H <hostname>   Set hostname
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

######################################################################
#
# Configuration commands

set_hostname() {
  _hostname=$1
  message "Setting hostname to ${_hostname}"
  sudo scutil --set ComputerName ${_hostname}
  sudo scutil --set HostName ${_hostname}
  sudo scutil --set LocalHostName ${_hostname}
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string ${_hostname}
}

expand_save_panels() {
  # Expand save and print panels by default
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
}

######################################################################

# Leading colon means silent errors, script will handle them
# Colon after a parameter, means that parameter has an argument in $OPTARG
while getopts ":hH:" opt; do
  case $opt in
    h) usage ; exit 0 ;;
    H) HOSTNAME=$OPTARG ;;
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

if test -n "${HOSTNAME}" ; then
  set_hostname ${HOSTNAME}
fi

install_homebrew
upgrade_homebrew

brew_install tmux
brew_install reattach-to-user-namespace --wrap-pbcopy-and-pbpaste
brew_install python
brew_install python3
brew_install swig
brew_install keychain
brew_install pass
brew_install git tig
brew_install wget
brew_install markdown
brew_install ctags-exuberant
brew_install gpg2
brew_install keybase
keybase config gpg gpg2
brew_install jrnl
brew_install mr
brew_install moreutils
brew_install vifm

# Overrides older version that comes with MacOSX
brew_install macvim --override-system-vim

install_cask

cask_install google-chrome
cask_install google-drive
cask_install skype
cask_install dropbox
cask_install android-file-transfer
cask_install totalfinder
cask_install wesnoth
cask_install firefox
cask_install sketchup

pip_install pyzmq
pip_install tornado
pip_install Jinja2
pip_install ipython
pip_install readline

# Upgrade pip to work with python3
pip3 install --upgrade pip

expand_save_panels

echo "Success."
exit 0
