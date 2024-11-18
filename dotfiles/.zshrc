#!/bin/zsh

#
# ~/.zshrc
#

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#
# Global settings
#

# export BROWSER="firefox"
if command -v nvim > /dev/null 2>&1; then
  export EDITOR="nvim"
  export DIFFPROG="nvim -d"
elif command -v vim > /dev/null 2>&1; then
  export EDITOR="vim"
  export DIFFPROG="vimdiff"
fi
export VISUAL="${EDITOR}"

export PATH="${HOME}/.bun/bin:${PATH}"

#
# Set environment variables for programming languages
#

# go
if command -v go > /dev/null 2>&1; then
  export GOPATH="${HOME}/.go"
  if ! [[ "${PATH}" =~ :?${GOPATH}:? ]]; then
    export PATH="${GOPATH}/bin:${PATH}"
  fi
fi

# ruby
if command -v ruby > /dev/null 2>&1; then
  GEM_HOME=$(gem env user_gemhome)
  export GEM_HOME
  if ! [[ "${PATH}" =~ :?${GEM_HOME}/bin:? ]]; then
    PATH="${GEM_HOME}/bin:${PATH}"
    export PATH
  fi
fi

# rust
if command -v cargo > /dev/null 2>&1; then
  if ! [[ "${PATH}" =~ :?${HOME}/.cargo/bin:? ]]; then
    export PATH="${HOME}/.cargo/bin:${PATH}"
  fi
fi

# npm
if command -v npm > /dev/null 2>&1; then
  export NPM_CONFIG_PREFIX="${HOME}/.npm"
  if ! [[ "${PATH}" =~ :?${HOME}/.npm/bin:? ]]; then
    export PATH="${HOME}/.npm/bin:${PATH}"
  fi
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

if command -v nvim > /dev/null 2>&1; then
  alias vi='nvim '
  alias vim='nvim '
  alias vimdiff='nvim -d '
elif command -v vim > /dev/null 2>&1; then
  alias vi='vim '
fi
alias sudo='sudo '
alias visudo='EDITOR=${EDITOR} visudo '
alias scp='noglob scp'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias happymake='make -j$(nproc) && sudo make install'

#alias Dev
alias lazygit="TERM=xterm-256color command lazygit"
alias gg=lazygit

#files & Diectories
alias mv="mv -iv"
alias cp="cp -riv"
alias mkdir="mkdir -p"
alias ls='eza --color=always --icons --group-directories-first'
alias la='eza --color=always --icons --group-directories-first --all'
alias ll='eza --color=always --icons --group-directories-first --all --long'
alias la='ls -lAh'

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

function make_silent {
  if command -v "${1}" > /dev/null 2>&1; then
    local cmd
    local bin
    bin="$(which "${1}")"
    cmd="function ${1} { local cmd=\"(${bin} \${@:q} > /dev/null 2>&1 &!)\"; eval \"\${cmd}\"; }"
    eval "${cmd}"
  fi
}

function run_silent {
  if command -v "${1}" > /dev/null 2>&1; then
    local bin="${1}"
    local args=(${@:2})
    (${bin} ${args[@]} > /dev/null 2>&1 &!);
  fi
}

make_silent ebook-viewer
make_silent eog
make_silent evince
make_silent feh
make_silent firefox
make_silent gimp
make_silent gitg
make_silent gitk
make_silent gwenview
make_silent inkscape
make_silent krita
make_silent okular

unset -f make_silent

if { command -v yt-dlp && ! command -v youtube-dl; } > /dev/null 2>&1; then
  alias youtube-dl='yt-dlp '
fi


#
# Color terminal output
#

# color ls output based on filetype
eval "$(dircolors -b)"

# color the man pages
if command -v nvim > /dev/null 2>&1; then
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
include /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
include ${HOME}/.p10k.zsh

# syntax highlighting
include /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
include /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
include /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

#zoxide
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

unset -f include
autoload -U compinit && compinit
