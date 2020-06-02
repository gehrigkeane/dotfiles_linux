#!/usr/bin/env bash

source ./lib_sh/func.sh
source ./lib_sh/log.sh

###############################################################################
# Ask for the administrator password upfront
###############################################################################
grep -q 'NOPASSWD:     ALL' /etc/sudoers.d/$LOGNAME > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "no suder file"
  sudo -v

  # Keep-alive: update existing sudo time stamp until the script has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

###############################################################################
# Install Packages
###############################################################################

./package/install.sh

###############################################################################
# Bootstrap Shell Environment
###############################################################################

# We're going to use zplugin instead of oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zplugin/master/doc/install.sh)"

# set zsh as the user login shell
if [[ "$SHELL" != "/usr/local/bin/zsh" ]]; then
  info_ "setting zsh as your shell (password required)"
  sudo bash -c 'echo "/usr/local/bin/zsh" >> /etc/shells'
  chsh -s /usr/local/bin/zsh
  success "ok"
fi

info_ "Dotfiles Setup"
read -r -p "symlink ./homedir/* files in ~/ (these are the dotfiles)? [y|N] " response
if [[ $response =~ (y|yes|Y) ]]; then
  info_ "creating symlinks for project dotfiles..."
  pushd homedir > /dev/null 2>&1
  now=$(date +"%Y.%m.%d.%H.%M.%S")

  for file in .*; do
    if [[ $file == "." || $file == ".." ]]; then
      continue
    fi
    info_ "~/$file"
    # if the file exists:
    if [[ -e ~/$file ]]; then
        mkdir -p ~/.dotfiles_backup/$now
        mv ~/$file ~/.dotfiles_backup/$now/$file
        echo "backup saved as ~/.dotfiles_backup/$now/$file"
    fi
    # symlink might still exist
    unlink ~/$file > /dev/null 2>&1
    # create the link
    ln -s ~/.dotfiles/homedir/$file ~/$file
    echo -en '\tlinked';ok
  done

  popd > /dev/null 2>&1
fi

info_ "VIM Setup"
read -r -p "Do you want to install vim plugins now? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  info_ "Installing vim plugins"
  # cmake is required to compile vim bundle YouCompleteMe
  vim +PluginInstall +qall > /dev/null 2>&1
  success "ok"
else
  success "skipped. Install by running :PluginInstall within vim"
fi
