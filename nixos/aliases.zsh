alias gco='git checkout'
alias gb='git branch'
alias gs='git status'
alias gpcb='git push origin $(git rev-parse --abbrev-ref HEAD)'

function git() {
  if [[ $1 == clone && $# -ge 2 ]]; then
    local url=$2
    # expand foo/bar -> https://github.com/foo/bar.git (no protocol, no dots in host part)
    if [[ $url =~ ^[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+$ ]]; then
      url="https://github.com/${url%.git}.git"
      echo "Cloning $url" >&2
    fi
    command git clone "$url" "${@:3}"
  else
    command git "$@"
  fi
}

alias u='cd ..'
alias uu='cd ../..'
alias uuu='cd ../../..'
alias uuuu='cd ../../../..'
alias uuuuu='cd ../../../../..'
