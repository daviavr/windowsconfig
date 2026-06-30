USER=$(id -un)

export GIT_PS1_SHOWDIRTYSTATE=0
export GIT_PS1_SHOWUNTRACKEDFILES=0
export GIT_PS1_SHOWUPSTREAM="none"

#export MSYS_NO_PATHCONV=1
export MSYS="winsymlinks:native nodosfilewarning"

export CYGWIN="winsymlinks:native"

shopt -s histappend

osc7_cwd_report() {
    printf '\e]7;file:///%s\a' "$(cygpath -m "$PWD")"
}

case " ${PROMPT_COMMAND[*]} " in
    *osc7_cwd_report*) ;;
    *) PROMPT_COMMAND+=(osc7_cwd_report) ;;
esac

case ";$PROMPT_COMMAND;" in
    *";history -a;"*) ;;
    *) PROMPT_COMMAND="history -a; history -n; $PROMPT_COMMAND" ;;
esac

[[ $- == *i* ]] && source ~/blobs/blesh/ble.sh --attach=none

[[ ${BLE_VERSION-} ]] && ble-attach

