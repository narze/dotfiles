#!/bin/sh

cat <<EOF >/tmp/chezmoi-utils.sh
#!/bin/sh

# Ansi color code variables
export red="\e[0;91m"
export blue="\e[0;94m"
export expand_bg="\e[K"
export blue_bg="\e[0;104m\${expand_bg}"
export red_bg="\e[0;101m\${expand_bg}"
export green_bg="\e[0;102m\${expand_bg}"
export green="\e[0;92m"
export white="\e[0;97m"
export bold="\e[1m"
export uline="\e[4m"
export reset="\e[0m"
EOF
