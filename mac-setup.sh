#!/bin/sh
# Set up a Mac the way I like it. Subsequently upgrade all the software.
#
# Kudos:
# https://gist.github.com/brandonb927/3195465
#
# TODO: An upgrade of python requires a reinstall of MacVim

# Exit on any error
set -o errexit

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
  brew_installed ${_formula} && return 0
  message "Installing brew formula \"${@}\""
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
  cask_installed ${_formula} && return 0
  message "Installing cask formula \"${@}\""
  ${BREW} cask install ${_formula} "${@}"
}

######################################################################
#
# PIP helper functions

pip_installed() {
  # Return 0 if python package installed, 1 otherwise
  # Arguments: package
  _package=${1}
  ${PIP} freeze | grep -i ${_package} >/dev/null 2>&1 && return 0
  return 1
}

pip_install() {
  _package=$1
  if pip_installed ${_package} ; then
    message "Updating python package \"${@}\""
    ${PIP} install -U ${_package}
  else
    message "Installing python package \"${@}\""
    ${PIP} install ${_package}
  fi
}

# TODO: Sometimes this seems to just reinstall current version
pip_update() {
  echo "Updating pip"
  pip install --upgrade pip
}

######################################################################
#
# Top-level installation commands

install_homebrew() {
  # http://brew.sh
  command -v ${BREW} >/dev/null 2>&1 && return 0
  message "Installing Homebrew"
  sudo_init
  sudo chown -R ${USER} /usr/local
  ${RUBY} -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  ${BREW} doctor
}

upgrade_homebrew() {
  echo "Updating homebrew"
  ${BREW} update
  ${BREW} upgrade --all
  ${BREW} cleanup
}

install_cask() {
  # http://caskroom.io/
  brew_install caskroom/cask/brew-cask
}

######################################################################

sudo_init() {
  # Ask for the administrator password upfront and run a keep-alive to update
  # existing `sudo` time stamp until script has finished
  # Kudos: https://gist.github.com/brandonb927/3195465
  sudo -v
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

######################################################################
#
# Configuration commands

set_hostname() {
  _hostname=$1
  message "Setting hostname to ${_hostname}"
  sudo_init
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

finder_config() {
  # Display full POSIX path as Finder window title
  defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
}

######################################################################

message() {
  echo $*
}

debug() {
  echo $*
}

######################################################################

# Leading colon means silent errors, script will handle them
# Colon after a parameter, means that parameter has an argument in $OPTARG
while getopts ":hH:x" opt; do
  case $opt in
    h) usage ; exit 0 ;;
    H) HOSTNAME=$OPTARG ;;
    x) echo "Turning on tracing" ; set -x ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
  esac
done

shift $(($OPTIND - 1))

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
brew_install pinentry-mac
brew_install keybase
keybase config gpg gpg2
brew_install jrnl
brew_install mr
brew_install moreutils
brew_install vifm
brew_install libyaml
brew_install abcde flac

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
cask_install hipchat
cask_install picasa
cask_install spark  # http://www.shadowlab.org/Software/spark.php
cask_install plain-clip  # http://www.bluem.net/en/mac/plain-clip/
cask_install handbrake
cask_install handbrakecli
# The older logitech-harmony software requires the 'java' package
# and seems to be broken:
#     LSOpenURLsWithRole() failed with error -10810 
# The logitech-myharmony software works with the Harmony One, but not
# my older 880 remote,
cask_install logitech-myharmony
cask_install radiant-player  # Google music player

pip_update

pip_install pyzmq
pip_install tornado
pip_install Jinja2
pip_install ipython
pip_install readline
pip_install pythonpy  # https://github.com/Russell91/pythonpy/
pip_install percol  # https://github.com/mooz/percol
pip_install wget
pip_install colorama
pip_install uuid
pip_install pyCLI  # https://pythonhosted.org/pyCLI/
pip_install path.py  # https://github.com/jaraco/path.py
pip_install requests  # http://docs.python-requests.org/
pip_install pyyaml  # Requires libyaml

expand_save_panels

echo "Success."
exit 0
