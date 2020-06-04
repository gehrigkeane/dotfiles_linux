#!/usr/bin/env bash

DIR="${BASH_SOURCE%/*}"

###############################################################################
# Meta
###############################################################################

RED=`tput setaf 1`
GREEN=`tput setaf 2`
MAGENTA=`tput setaf 5`
RESET=`tput sgr0`

error () {
  printf "${RED}[ERROR] $1${RESET}" >&2
}

info_ () {
  printf "${MAGENTA}[INFO] $1${RESET}"
}

success () {
  printf "${GREEN}[SUCCESS] $1${RESET}"
}

error_exit () {
  error "System Bootstrap Failed, please refer to line $(caller)\n" >&2
  exit 1
}

#trap error_exit ERR

parse_install () {
  #
  # Parse an _install_ file, and output a space delimited string to stdout
  #
  # Args: Expects exactly one argument whose value is an existing file
  #
  if [ $# != 1 ] ; then
    error "Please provide exactly one argument to an existing _install_ file\n"
    exit 1
  elif [ ! -f "$1" ] ; then
    error "Please ensure that $1 exists and is a file\n"
    exit 1
  fi

  # `awk '{$1=$1};1'` https://unix.stackexchange.com/a/205854
  PACKAGES=$( cat $1 | cut -d'#' -f1 | awk '{$1=$1};1' | tr '\n' ' ' )

  printf "$PACKAGES"
}

###############################################################################
# Install Packages
###############################################################################

#
# Create Dir(s)
#

mkdir -p ~/lib
mkdir -p ~/dev

#
# Install asdf
#
# ref:
#   https://github.com/asdf-vm/asdf
#   https://asdf-vm.com/
#

info_ "Install asdf plugins (Highly Recommended)?\n"
read -r -p "[y|N] " response
if [[ $response =~ (y|yes|Y) ]]; then
  # install pre-reqs + asdf according to linux install documentation
  sudo apt-get install -uy build-essential curl dirmngr git gpg
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf
  pushd ~/.asdf
  git checkout "$( git describe --abbrev=0 --tags )"
  popd

  # temporarily activate asdf
  # Note: terminal config file ~/.zshrc or ~/.bashrc should configure asdf according to asdf documentation
  . $HOME/.asdf/asdf.sh

  # iteratively install plugins and latest version
  PLUGINS=$( parse_install $DIR/package/install_asdf )
  for PLUGIN in $PLUGINS ; do
    info_ "asdf plugin add $PLUGIN\n"
    asdf plugin add $PLUGIN

    if [[ "$PLUGIN" == "java" ]] ; then
      info_ "installing java b/c it's hoopdy"
      asdf install java adopt-openjdk-13+33

    elif [[ "$PLUGIN" == "nodejs" ]] ; then
      # ref: https://github.com/asdf-vm/asdf-nodejs#using-a-dedicated-openpgp-keyring
      info_ "installing NodeJS GPG Keys\n"
      export GNUPGHOME="${ASDF_DIR:-$HOME/.asdf}/keyrings/nodejs" && mkdir -p "$GNUPGHOME" && chmod 0700 "$GNUPGHOME"
      bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring

    elif [[ "$PLUGIN" == "python" ]] ; then
      # ref: https://github.com/pyenv/pyenv/wiki/Common-build-problems
      info_ "installing pyenv dependencies\n"
      sudo apt-get install -uy make build-essential libssl-dev zlib1g-dev libbz2-dev \
      libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
      xz-utils tk-dev libffi-dev liblzma-dev python-openssl git

    elif [[ "$PLUGIN" == "terraform" ]] ; then
      # appearently the terraform plugin needs unzip ¯\_(ツ)_/¯
      sudo apt-get install -uy unzip
    fi

    info_ "asdf install $PLUGIN latest\n"
    asdf install $PLUGIN latest

    info_ "asdf global $PLUGIN $( asdf latest $PLUGIN )\n"
    asdf global $PLUGIN "$( asdf latest $PLUGIN )"
    
    success "ok\n"
  done

fi

#
# Cargo Packages
#
# To install rust traditionally:
#   `sh -s -- -y` ref: https://github.com/rust-lang/rustup/issues/297#issuecomment-589989163
#   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
#   source $HOME/.cargo/env

info_ "Install Cargo Packages (Highly Recommended)?\n"
read -r -p "[y|N] " response
if [[ $response =~ (y|yes|Y) ]]; then
  INSTALL_CARGO_FILE=$DIR/package/install_cargo

  info_ "Parsing cargo packages from [$INSTALL_CARGO_FILE]\n"
  INSTALL_CARGO=$( parse_install "$INSTALL_CARGO_FILE" )
  success "Parsed cargo packages [$INSTALL_CARGO]\n"

  info_ "Installing cargo packages\n"
  cargo install $INSTALL_CARGO
  success "Installed cargo packages\n"

  # Copy binaries to /usr/local/bin
  info_ "Copying binaries to /usr/local/bin\n"
  BIN_DIR=$( asdf where rust )
  for BINARY in $INSTALL_CARGO ; do
    if [ $BINARY == "tealdeer" ] ; then
      BINARY="tldr"
    fi

    sudo cp $BIN_DIR/bin/$BINARY /usr/local/bin
  done
  
  success "ok\n"
fi

#
# Aptitude Packages
#

info_ "Install Apt Packages (Highly Recommended)?\n"
read -r -p "[y|N] " response
if [[ $response =~ (y|yes|Y) ]]; then
  INSTALL_APT_FILE=$DIR/package/install_apt

  info_ "Parsing aptitude packages from [$INSTALL_APT_FILE]\n"
  INSTALL_APT=$( parse_install "$INSTALL_APT_FILE" )
  success "Parsed aptitude packages [$INSTALL_APT]\n"

  info_ "Installing aptitude packages\n"
  sudo add-apt-repository -y ppa:kgilmer/speed-ricer
  sudo add-apt-repository -y ppa:agornostal/ulauncher
  # For non-interactive installation `... sudo DEBIAN_FRONTEND=noninteractive apt-get install ...`
  sudo apt-get update && sudo apt-get install -quy $INSTALL_APT
  
  success "ok\n"
fi

#
# Snaps
#

info_ "Install Snap Packages (Highly Recommended)?\n"
read -r -p "[y|N] " response
if [[ $response =~ (y|yes|Y) ]]; then
  INSTALL_SNAP_FILE=$DIR/package/install_snap
  INSTALL_SNAPC_FILE=$DIR/package/install_snap_classic

  info_ "Parsing snap packages from [$INSTALL_SNAP_FILE] and classic [$INSTALL_SNAPC_FILE]\n"
  INSTALL_SNAP=$( parse_install "$INSTALL_SNAP_FILE" )
  INSTALL_SNAPC=$( parse_install "$INSTALL_SNAPC_FILE" )
  success "Parsed snap packages [$INSTALL_SNAP] and classic [$INSTALL_SNAPC_FILE]\n"

  info_ "Installing snap packages\n"
  sudo snap install $INSTALL_SNAP
  sudo snap install --classic $INSTALL_SNAPC
  
  success "ok\n"
fi

#
# Special Snowflakes
#

#if [ ! -d "$HOME/lib/kitty" ] ; then
  info_ "Installing kitty\n"
  
  curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
  sudo ln -sfn $HOME/.local/kitty.app/bin/kitty /usr/local/bin/kitty

  success "ok\n"
#fi

# Install Powerline Fonts
if [ ! -d "$HOME/lib/powerline_fonts" ] ; then
  info_ "Installing powerline fonts\n"
  git clone https://github.com/powerline/fonts.git $HOME/lib/powerline_fonts
  pushd $HOME/lib/powerline_fonts
  ./install.sh
  popd
  
  success "ok\n"
else
  info_ "Powerline fonts already installed\n"
fi

# Install WRK
# ref: https://github.com/wg/wrk
# ref: https://github.com/wg/wrk/wiki/Installing-wrk-on-Linux
if [ ! -z $(which wrk) ] ; then
  info_ "Installing wrk\n"
  sudo apt-get install -yu build-essential libssl-dev git
  git clone https://github.com/wg/wrk.git $HOME/lib/wrk
  pushd $HOME/lib/wrk
  make
  sudo ln -sfn wrk /usr/local/bin/wrk
  popd
  
  success "ok\n"
else
  info_ "wrk is already installed\n"
fi

# Docker
# ref: https://docs.docker.com/engine/install/ubuntu/
if [ ! -z $(which docker) ] ; then
  info_ "Installing docker\n"
  sudo apt-get remove -y docker docker-engine docker.io containerd runc > /dev/null 2>&1
  sudo apt-get update && sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository \
     "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) \
     stable"
  sudo apt-get update && sudo -y apt-get install docker-ce docker-ce-cli containerd.io

  # ref: https://docs.docker.com/engine/install/linux-postinstall/
  sudo groupadd docker
  sudo usermod -aG docker $USER
  sudo systemctl enable docker

  # ref: https://github.com/awslabs/amazon-ecr-credential-helper/releases
  wget https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/0.4.0/linux-amd64/docker-credential-ecr-login
  sudo mv docker-credential-ecr-login /usr/local/bin
  
  success "ok\n"
else
  info_ "Docker is already installed\n"
fi

###############################################################################
# Bootstrap Shell Environment
###############################################################################

# We're going to use zinit instead of oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"

# set zsh as the user login shell
if [[ "$SHELL" != "/usr/bin/zsh" ]] ; then
  info_ "setting zsh as your shell (password required)\n"
  sudo bash -c 'echo "/usr/bin/zsh" >> /etc/shells'
  chsh -s /usr/bin/zsh

  success "ok\n"
fi

info_ "Dotfiles Setup\nsymlink ./homedir/* files in ~/ (these are the dotfiles)?\n"
read -r -p "[y|N] " response
if [[ $response =~ (y|yes|Y) ]] ; then
  info_ "creating symlinks for project dotfiles...\n"
  pushd homedir > /dev/null 2>&1
  now=$(date +"%Y.%m.%d.%H.%M.%S")

  for file in .*; do
    if [[ $file == "." || $file == ".." ]] ; then
      continue
    fi

    info_ "~/$file\n"
    target_dir=$HOME
    target_file=$file

    # special cases
    if [[ $file == ".kitty" ]] ; then
      mkdir -p $HOME/.config/kitty
      target_dir=$HOME/.config/kitty
      target_file=kitty.conf
    fi

    # if the target file exists:
    if [[ -e $target_dir/$target_file ]] ; then
      mkdir -p ~/.dotfiles_backup/$now
      mv $target_dir/$target_file ~/.dotfiles_backup/$now/$target_file
      info_ "backup saved as ~/.dotfiles_backup/$now/$target_file\n"
    fi
    
    # symlink might still exist
    unlink $target_dir/$target_file > /dev/null 2>&1
    # create the link
    ln -s ~/.dotfiles/homedir/$file $target_dir/$target_file
  done

  popd > /dev/null 2>&1
fi

info_ "VIM Setup\nDo you want to install vim plugins now?\n"
read -r -p "[y|N] " response
if [[ $response =~ (y|yes|Y) ]] ; then
  info_ "Installing vim plugins\n"
  # cmake is required to compile vim bundle YouCompleteMe
  vim +PluginInstall +qall > /dev/null 2>&1

  success "ok\n"
else
  success "skipped. Install by running :PluginInstall within vim\n"
fi
