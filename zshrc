#zmodload zsh/zprof

# Guiding rule for this file: under MSYS/Cygwin every fork() and every external
# program costs tens of milliseconds (much more when Windows has paged the shell
# out while you were in another window). Anything that runs per keystroke or per
# prompt must be pure zsh. See ~/.zshenv for the /etc/profile replacement.

# ---------------------------------------------------------------- p10k instant prompt
# Draws the cached prompt right away, so the tab is usable while the rest of this file
# loads. Must stay at the top; nothing below may print to the console or ask for input.
if [[ -r ${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh ]]; then
  source ${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh
fi

# ---------------------------------------------------------------- avoid forks in plugins
# p10k decides whether this is an SSH session with `who -m` (fork + exec, and a scan of
# every PATH directory to find `who`) on every start: 100-300 ms. It skips that when
# these are already set for the current TTY.
if [[ -n $SSH_CLIENT || -n $SSH_TTY || -n $SSH_CONNECTION ]]; then
  typeset -gix P9K_SSH=1
else
  typeset -gix P9K_SSH=0
fi
typeset -gx _P9K_SSH_TTY=$TTY

# Normally from /etc/profile.d/aliases.sh, which ~/.zshenv no longer sources.
alias ls='ls -F --color=auto --show-control-chars'
alias ll='ls -l'

# ---------------------------------------------------------------- autosuggestions
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_STRATEGY=(history)
# Async mode is NOT wanted here (it forks a subshell on every keystroke). The plugin
# turns it on by itself, so it gets unset after the plugins are loaded, below.

# ---------------------------------------------------------------- zephyr settings
zstyle ':zephyr:plugin:color' use-cache yes        # cache `dircolors` output instead of forking it on every start
zstyle ':zephyr:plugin:history' histsize 10000     # zephyr's default is 20000: smaller = cheaper suggestion lookups
zstyle ':zephyr:plugin:history' savehist 10000     # zephyr's default is 100000: smaller = cheaper history file rewrites

# ---------------------------------------------------------------- plugins (static bundle)
# Instead of running `antidote load` on every start, source a pre-generated bundle.
# It is regenerated automatically only when .zsh_plugins.txt is newer than it.
zsh_plugins=${ZDOTDIR:-$HOME}/.zsh_plugins
if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
  (source $HOME/.antidote/antidote.zsh && antidote bundle <${zsh_plugins}.txt >|${zsh_plugins}.zsh)
fi
fpath=($HOME/.antidote/functions $fpath)   # keeps the `antidote` command available (lazy-loaded)
autoload -Uz antidote
source ${zsh_plugins}.zsh
unset zsh_plugins

unset ZSH_AUTOSUGGEST_USE_ASYNC   # plain synchronous suggestions: no fork per keystroke

# ---------------------------------------------------------------- completion
# Runs after the bundle so zsh-completions' fpath entry is actually seen.
# Custom completions: drop `_command` files into ~/.zsh/completions, e.g.
#   glab completion -s zsh >| ~/.zsh/completions/_glab
_zfunc=$HOME/.zfunc
_zcompdir=$HOME/.zsh/completions
[[ -d $_zcompdir ]] || mkdir -p $_zcompdir
fpath=($_zcompdir $_zfunc $fpath)

autoload -Uz compinit
_zcompdump=${ZDOTDIR:-$HOME}/.zcompdump
# `compinit -C` never notices new completion files on its own, so rebuild the dump
# whenever a file was added to or removed from the folder since it was last built.
[[ $_zcompdir -nt $_zcompdump ]] && rm -f -- $_zcompdump $_zcompdump.zwc
compinit -C -d $_zcompdump
[[ $_zcompdump.zwc -nt $_zcompdump ]] || zcompile -R -- $_zcompdump.zwc $_zcompdump
unset _zcompdir _zcompdump _zfunc

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' verbose yes
zstyle ':completion:*:matches' -r 'yes'
zstyle ':completion:*:options' sort false
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:*:*:*:messages' format '%F{purple} -- %d --%f'
zstyle ':completion:*:*:*:*:warnings' format '%F{red}-- no matches found --%f'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# ---------------------------------------------------------------- prompt
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ---------------------------------------------------------------- fzf
# fzf's completion.zsh runs `binding=$(bindkey '^I')` (a forked subshell) to learn what
# Tab did before it took Tab over. Telling it up front skips the fork.
fzf_default_completion=expand-or-complete
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# ---------------------------------------------------------------- zcompile
# zsh loads file.zwc instead of parsing file when the .zwc is newer. Recompiled here
# only when a file changed; takes effect from the next shell on.
() {
  local f
  for f in ${ZDOTDIR:-$HOME}/.zshrc ${ZDOTDIR:-$HOME}/.zshenv ~/.p10k.zsh ~/.fzf.zsh \
           ${ZDOTDIR:-$HOME}/.zsh_plugins.zsh; do
    [[ -r $f && ! $f.zwc -nt $f ]] && zcompile -R -- $f.zwc $f 2>/dev/null
  done
}

# ---------------------------------------------------------------- Ctrl+L
# Same result as before (screen and scrollback cleared) without launching clear.exe.
function fast-clear-screen {
  print -n -- $'\e[3J'
  zle .clear-screen
}
zle -N fast-clear-screen
bindkey '^L' fast-clear-screen
#zprof
