# ~/.zshenv: read by every zsh (scripts too), before .zprofile/.zshrc.
#
# Windows Terminal starts zsh with --login, so PortableGit's /etc/zsh/zprofile runs
# `emulate sh -c 'source /etc/profile'`. That script forks about ten times (cygpath x2,
# hostname, uname, `which zsh` and several `$(...)` globbing subshells), which costs
# ~200 ms on every new tab. GLOBAL_RCS off skips /etc/zprofile, /etc/zshrc, /etc/zlogin
# and /etc/zlogout; the block below builds the same environment with pure zsh.
# (/etc/zsh/zshenv was already read before this file; it only sets PROMPT.)
#
# Only the default MSYSTEM=MSYS, MSYS2_PATH_TYPE=inherit setup is reproduced. Anything
# else falls back to the real /etc/profile. After a PortableGit upgrade, compare
#   zsh -l -c env | sort      vs      zsh -o global_rcs -l -c env | sort
# to make sure /etc/profile hasn't gained anything new.

unsetopt global_rcs

if [[ -o login ]]; then
  if [[ ${MSYSTEM:-MSYS} != MSYS || ${MSYS2_PATH_TYPE:-inherit} != inherit ]]; then
    emulate sh -c 'source /etc/profile'
  else
    () {
      emulate -L zsh

      # /etc/msystem + /etc/msystem.d/MSYS ($CPUTYPE is what `uname -m` prints)
      export MSYSTEM=MSYS MSYSTEM_PREFIX=/usr MSYSTEM_CARCH=$CPUTYPE
      export MSYSTEM_CHOST=$CPUTYPE-pc-cygwin

      # /etc/profile
      export ORIGINAL_PATH=${ORIGINAL_PATH:-$PATH}
      PATH=/usr/local/bin:/usr/bin:/bin:/opt/bin${ORIGINAL_PATH:+:$ORIGINAL_PATH}
      export MANPATH=/usr/local/man:/usr/share/man:/usr/man:/share/man
      export INFOPATH=/usr/local/info:/usr/share/info:/usr/info:/share/info
      export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/share/pkgconfig:/lib/pkgconfig
      export CONFIG_SITE=/etc/config.site
      export ORIGINAL_TMP=${ORIGINAL_TMP:-$TMP} ORIGINAL_TEMP=${ORIGINAL_TEMP:-$TEMP}
      export TMP=${TMP//\\//} TEMP=${TEMP//\\//}    # what `cygpath -m` does to them
      [[ -d $TMPDIR || ! -d $TMP ]] || export TMPDIR=$TMP
      export HOSTNAME=${HOSTNAME:-$HOST} SHELL=/usr/bin/zsh USER

      # /etc/profile.d/env.sh and perlbin.sh
      PATH=$HOME/bin:$PATH
      local d
      for d in /usr/bin/site_perl /usr/lib/perl5/site_perl/bin /usr/bin/vendor_perl \
               /usr/lib/perl5/vendor_perl/bin /usr/bin/core_perl; do
        [[ -d $d ]] && PATH+=:$d
      done
      export PATH

      # /etc/profile.d/lang.sh (Windows normally provides LANG, so this never forks)
      [[ -n ${LC_ALL:-${LC_CTYPE:-$LANG}} ]] || export LANG=$(/usr/bin/locale -uU)
    }
  fi
fi
