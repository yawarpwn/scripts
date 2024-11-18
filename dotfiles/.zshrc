#!/bin/zsh

function delete_to_end() {
  zle kill-line
}

zle -N delete_to_end

bindkey '^O' delete_to_end

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# export BROWSER="firefox"
if command -v nvim > /dev/null 2>&1; then
  export EDITOR="nvim"
  export DIFFPROG="nvim -d"
elif command -v vim > /dev/null 2>&1; then
  export EDITOR="vim"
  export DIFFPROG="vimdiff"
fi
export VISUAL="${EDITOR}"


#
# Set environment variables for programming languages
#

#Neovim 
export PATH="$PATH:/opt/nvim-linux64/bin"

#Bun
export PATH="${HOME}/.bun/bin:${PATH}"

# rust
if command -v cargo > /dev/null 2>&1; then
  if ! [[ "${PATH}" =~ :?${HOME}/.cargo/bin:? ]]; then
    export PATH="${HOME}/.cargo/bin:${PATH}"
  fi
fi

# fnm
FNM_PATH="$HOME/.fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$HOME/.fnm:$PATH"
  eval "`fnm env`"
fi

# zsh
if [ -d ${HOME}/.local/share/zsh/site-functions ]; then
  fpath=(${HOME}/.local/share/zsh/site-functions "${fpath[@]}")
fi

# custom scripts
if ! [[ "${PATH}" =~ :?${HOME}/.scripts:? ]]; then
  export PATH="${HOME}/.scripts:${PATH}"
fi

# local executables
if ! [[ "${PATH}" =~ :?${HOME}/.local/bin:? ]]; then
  export PATH="${HOME}/.local/bin:${PATH}"
fi

# local libraries
if ! [[ "${LD_LIBRARY_PATH}" =~ :?/usr/local/lib:? ]]; then
  LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"
fi
if ! [[ "${LD_LIBRARY_PATH}" =~ :?${HOME}/.local/lib:? ]]; then
  LD_LIBRARY_PATH="${HOME}/.local/lib:${LD_LIBRARY_PATH}"
fi
export LD_LIBRARY_PATH

#
# Set zsh aliases
#

# if command -v nvim > /dev/null 2>&1; then
#   alias vi='nvim '
#   alias vim='nvim '
#   alias vimdiff='nvim -d '
# elif command -v vim > /dev/null 2>&1; then
#   alias vi='vim '
# fi

alias sudo='sudo '
alias visudo='EDITOR=${EDITOR} visudo '
alias scp='noglob scp'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias happymake='make -j$(nproc) && sudo make install'

#alias Dev
alias lazygit="TERM=xterm-256color command lazygit"
alias gg=lazygit
alias gl='git l --color | devmoji --log --color | less -rXF'
alias gs="git st"
alias gb="git checkout -b"
alias gc="git commit"
alias gpr="git pr checkout"
alias gm="git branch -l main | rg main > /dev/null 2>&1 && hub checkout main || hub checkout master"
alias gcp="git commit -p"
alias gpp="git push"
alias gp="git pull"



#files & Diectories
alias mv="mv -iv"
alias cp="cp -riv"
alias mkdir="mkdir -p"

if command -v eza >/dev/null;then
  alias ls='eza --color=always --icons --group-directories-first'
  alias la='eza --color=always --icons --group-directories-first --all'
  alias ll='eza --color=always --icons --group-directories-first --all --long'
  alias la='ls -lAh'
elif command -v exa >/dev/null; then
  alias ls='exa --color=always --icons --group-directories-first'
  alias la='exa --color=always --icons --group-directories-first --all'
  alias ll='exa --color=always --icons --group-directories-first --all --long'
  alias la='ls -lAh'
else
  alias ls='ls --color=always'
  alias la='ls --color=always'
  alias ll='ls --color=always'
  alias la='ls -lAh'
fi

function superupgrade {
  sudo sh -c 'pacman -Syu && paccache -r && paccache -ruk0'
}

function megapurge {
  sudo sh -c 'yes | pacman -Scc' &&
    sudo journalctl --rotate &&
    sudo journalctl --vacuum-time=1s &&
    pacdiff -s

  local pkg
  if pkg=("${(@f)$(pacman -Qtdq)}"); then
    sudo pacman -Rs --noconfirm "${pkg[@]}"
  fi
}

#
# Color terminal output
#

# color ls output based on filetype
eval "$(dircolors -b)"

# color the man pages
if command -v nvim > /dev/null 2>&1; then
  source ~/powerlevel10k/powerlevel10k.zsh-theme
  export MANPAGER='nvim +Man! --clean'
else
  export MANPAGER="less -R --use-color -Dd+r -Du+b -s -M +Gg"
  # export MANROFFOPT="-P -c"
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

#
# Add zsh plugins
#

include() {
  [[ -f "$1" ]] && source "$1"
}

# powerlevel10k
# include /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
source ~/powerlevel10k/powerlevel10k.zsh-theme
include ${HOME}/.p10k.zsh

# syntax highlighting
include /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
include /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
include /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

#zoxide
eval "$(zoxide init zsh)"
#starship
# eval "$(starship init zsh)"

unset -f include
autoload -U compinit && compinit


