#!/bin/bash

# return to beginning of line
bind '"\C-o": "\C-k"'

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# PS1='\w > '
export PS1="\[\e[34m\]\w > \[\e[m\] "

#
# Global settings
#

export BROWSER="firefox"
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
  export DIFFPROG="nvim -d"
elif command -v vim >/dev/null 2>&1; then
  export EDITOR="vim"
  export DIFFPROG="vimdiff"
fi
export VISUAL="${EDITOR}"

#
# Set environment variables for programming languages
#

#Bun
export PATH="${HOME}/.bun/bin:${PATH}"

# fnm
FNM_PATH="$HOME/.fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$HOME/.fnm:$PATH"
  eval "$(fnm env)"
fi

# rust
if command -v cargo >/dev/null 2>&1; then
  if ! [[ "${PATH}" =~ :?${HOME}/.cargo/bin:? ]]; then
    export PATH="${HOME}/.cargo/bin:${PATH}"
  fi
fi

if command -v luarocks >/dev/null 2>&1; then
  if ! [[ "${PATH}" =~ :?${HOME}/.luarocks/bin:? ]]; then
    export PATH="${HOME}/.luarocks/bin:${PATH}"
  fi
fi

# npm
if command -v npm >/dev/null 2>&1; then
  export NPM_CONFIG_PREFIX="${HOME}/.npm"
  if ! [[ "${PATH}" =~ :?${HOME}/.npm/bin:? ]]; then
    export PATH="${HOME}/.npm/bin:${PATH}"
  fi
fi

# beet autocompletion
if command -v beet >/dev/null 2>&1; then
  if ! [ -f "/usr/share/bash-completion/completions/beet" ] &&
    ! [ -f "${HOME}/.local/share/bash-completion/completions/beet" ]; then
    eval "$(beet completion)"
  fi
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
# Set bash aliases
#

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

if command -v eza >/dev/null; then
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
  mapfile -t pkg < <(pacman -Qtdq)
  if [ "${#pkg}" -gt 0 ]; then
    sudo pacman -Rs --noconfirm "${pkg[@]}"
  fi
}

#
# Color terminal output
#

# color ls output based on filetype
eval "$(dircolors -b)"

# color the man pages
if command -v nvim >/dev/null 2>&1; then
  export MANPAGER='nvim +Man! --clean'
else
  export MANPAGER="less -R --use-color -Dd+r -Du+b -s -M +Gg"
  # export MANROFFOPT="-P -c"
fi

#zoxide
eval "$(zoxide init bash)"
#starship
eval "$(starship init bash)"

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
