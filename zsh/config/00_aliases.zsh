# Git
# Use `hub` as our git wrapper:
#   http://defunkt.github.com/hub/
hub_path=$(which hub)
if (( $+commands[hub] ))
then
  alias git=$hub_path
fi

# The rest of my fun git aliases
alias g='git'
alias gfr='git fetch && git rebase'
alias glog="git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias gp='git push origin HEAD'
alias gd='git diff'
alias gc='git commit'
alias gca='git commit --amend'
alias gco='git checkout'
alias gcb='git copy-branch-name'
alias gb='git branch'
alias gs='say "Please use S for gods sake"'
alias s="git status -sb"

alias ga="git add"
alias ga.="git add ."
alias gaa="git add --all"
alias gai="git add -i"
alias gap="git add -p"
alias gcam="git add --all && git commit -m"
alias gcm="git commit -m"
alias gcaa="git commit -a --amend"
alias gco-="git checkout -"
alias gcob="git checkout -b"
alias gcom="git checkout master"
alias gcod="git checkout develop"
alias gcl="git clone"
alias gcln="git clean"
alias gdc="git diff --name-only --diff-filter=U"
alias gds="git diff --staged"
alias gff="git flow feature"
alias gfo="git fetch origin"
alias gp="git push"
gpuo() { git push -u origin $(git rev-parse --abbrev-ref HEAD) }
alias gmd="git merge develop"
alias grm="git rebase master"
alias gr="git reset"
alias grh="git reset HEAD"
alias grp="git rebase -p"
alias gl="git pull"
alias gli="git ls-files -o -i --exclude-standard --directory | grep -v '\.DS_Store'"

# Misc
alias -- -='cd -'
alias arst="asdf"
alias b="bundle exec"
alias be="bundle exec"
alias cl="clear"
alias c='cd ~/Code && ls'
alias c.="code ."
alias cwd='pwd | pbcopy'
f() {
	local dir
	dir=$(find ${1:-.} -path '*/\.*' -prune -o -type d -print 2> /dev/null | fzy) && cd "$dir"
}
alias finder="cd \"$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')\""
alias fixappleeventsbug='sudo killall -KILL appleeventsd'
alias fuck='eval $(thefuck $(fc -ln -1))'
alias gowd='cd "`pbpaste`"'
alias h='helm'
alias ip='curl ifconfig.me'
alias jsc='/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Resources/jsc'
alias sand='cd ~/Sandbox && ls'
alias k='kubectl'
alias l='ls -la'
alias lt='cd ~/laptop'
alias mc='maid clean -n'
alias mcf='maid clean'
alias mk='minikube'
alias mux='tmuxinator'
alias o.="open ."
alias o="open"
alias ox="open *.xcworkspace || open *.xcodeproj"
alias p='cd ~/Projects && ls'
alias please='sudo bash -c "$(fc -l -1 | cut -d " " -f 4-)"'
alias r="rails"
alias rc="rails console"
alias rg="rails generate"
alias rs="rails server"
alias rk="rake"
alias rkdm="rake db:migrate"
alias redo='sudo !!'
alias reload='exec $SHELL -l'
alias serve='python -m SimpleHTTPServer 8000'
alias v="nvim"
alias vim="nvim"
alias wa="watch "
alias watch="watch "
alias wk="cd ~/Workspaces && ls"

# Docker
alias d='docker'
alias dx='docker exec'
alias ds='docker ps'
alias dc='docker-compose'
alias dm='docker-machine'
