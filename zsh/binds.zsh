# Bind Ctrl + Left-Arrow to move back one word
#bindkey "^[[1;5D" backward-word
#bindkey "^[OD" backward-word

# Bind Ctrl + Right-Arrow to move forward one word
#bindkey "^[[1;5C" forward-word
#bindkey "^[OC" forward-word

bindkey "\e[1;5C" forward-word      # Ctrl + Right
bindkey "\e[1;5D" backward-word     # Ctrl + Left
bindkey "\e[3~" delete-char         # Delete
bindkey "^[[A" up-line-or-history   # Up Arrow
bindkey "^[[B" down-line-or-history # Down Arrow

# Ctrl + Home / Ctrl + End
bindkey "\e[1;5H" beginning-of-line
bindkey "\e[1;5F" end-of-line

# Ctrl + Delete (Delete word forward)
bindkey "\e[3;5~" kill-word

# Ctrl + Backspace (Delete word backward)
# Note: Since Alacritty is sending \u0017 (Ctrl+W) for Ctrl+Backspace, 
# standard backward-kill-word handles this automatically, but you can explicitly map it:
bindkey "^W" backward-kill-word
