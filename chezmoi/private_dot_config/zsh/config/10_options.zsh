# Awesome cd movements from zshkit
setopt autocd autopushd pushdminus pushdsilent pushdtohome cdablevars
DIRSTACKSIZE=5

# Enable extended globbing
setopt extendedglob

# Allow [ or ] whereever you want
unsetopt nomatch

# Treat `#` as the start of a comment in interactive shells too, so pasted
# snippets with comments don't error out on the comment lines
# https://unix.stackexchange.com/questions/33994/zsh-interpret-ignore-commands-beginning-with-as-comments
setopt interactivecomments
