#!/usr/bin/env bash

#
# References
#   Nice bash programming reference: http://www.binaryphile.com/bash/2018/09/22/approach-bash-like-a-developer-part-26-returning-values.html
#

source ../lib_sh/func.sh
source ../lib_sh/log.sh

#
# Dir
#

mkdir -p ~/lib
mkdir -p ~/dev

#
# asdf
#
# ref:
#   https://github.com/asdf-vm/asdf
#   https://asdf-vm.com/
#

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
PLUGINS=$( parse_install install_asdf )
for PLUGIN in $PLUGINS ; do
  info_ "asdf plugin add $PLUGIN"
  asdf plugin add $PLUGIN

  if [[ "$PLUGIN" == "nodejs" ]] ; then
    # ref: https://github.com/asdf-vm/asdf-nodejs#using-a-dedicated-openpgp-keyring
    info_ "installing NodeJS GPG Keys"
    export GNUPGHOME="${ASDF_DIR:-$HOME/.asdf}/keyrings/nodejs" && mkdir -p "$GNUPGHOME" && chmod 0700 "$GNUPGHOME"
    bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
  elif [[ "$PLUGIN" == "python" ]] ; then
    # ref: https://github.com/pyenv/pyenv/wiki/Common-build-problems
    info_ "installing pyenv dependencies"
    sudo apt-get install -uy make build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev libffi-dev liblzma-dev python-openssl git
  elif [[ "$PLUGIN" == "terraform" ]] ; then
    # appearently the terraform plugin needs unzip ¯\_(ツ)_/¯
    sudo apt-get install -uy unzip
  fi

  info_ "asdf install $PLUGIN latest"
  asdf install $PLUGIN latest

  info_ "asdf global $PLUGIN $( asdf latest $PLUGIN )"
  asdf global $PLUGIN "$( asdf latest $PLUGIN )"
done

#
# Cargo Packages
#
# To install rust traditionally:
#   `sh -s -- -y` ref: https://github.com/rust-lang/rustup/issues/297#issuecomment-589989163
#   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
#   source $HOME/.cargo/env

info_ "Parsing cargo packages from [$DIR/install_cargo]"
INSTALL_CARGO=$( parse_install "install_cargo" )
success "Parsed cargo packages [$INSTALL_CARGO]"

info_ "Installing cargo packages"
cargo install $INSTALL_CARGO
success "Installed cargo packages"

#
# Aptitude Packages
#

info_ "Parsing aptitude packages from [$DIR/install_apt]"
INSTALL_APT=$( parse_install "install_apt" )
success "Parsed aptitude packages [$INSTALL_APT]"

info_ "Installing aptitude packages"
# For non-interactive installation `... sudo DEBIAN_FRONTEND=noninteractive apt-get install ...`
sudo add-apt-repository ppa:kgilmer/speed-ricer ppa:agornostal/ulauncher
sudo apt-get update && sudo apt-get install -quy $INSTALL_APT
success "Installed aptitude packages"

#
# Snaps
#

info_ "Parsing snap packages from [$DIR/install_snap]"
INSTALL_SNAP=$( parse_install "install_snap" )
success "Parsed snap packages [$INSTALL_SNAP]"

info_ "Installing snap packages"
sudo snap install $INSTALL_SNAP
success "Installed snap packages"

#
# Special Snowflakes
#

# Install WRK
# ref: https://github.com/wg/wrk
# ref: https://github.com/wg/wrk/wiki/Installing-wrk-on-Linux
if [ -z $(which wrk) ] ; then 
  sudo apt-get install -yu build-essential libssl-dev git
  git clone https://github.com/wg/wrk.git $HOME/lib/wrk
  pushd $HOME/lib/wrk
  make
  sudo ln -sfn /usr/local/bin/wrk
  popd
else
  printf "wrk is already installed\n"
fi

# Docker
# ref: https://docs.docker.com/engine/install/ubuntu/
if [ -z $(which docker) ] ; then
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
  mv docker-credential-ecr-login /usr/local/bin
else
  printf "Docker is already installed\n"
fi

