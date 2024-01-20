# Editing
alias aliases='$EDITOR ~/.config/zsh/config/00_aliases.zsh ; reload ; echo "Aliases reloaded"'
alias funcs='$EDITOR ~/.config/zsh/config/20_functions.zsh ; reload ; echo "Aliases reloaded"'
alias ke='$EDITOR ~/dotfiles/etc/karabiner.edn'
alias zshrc='$EDITOR ~/.zshrc ; reload'
alias .tmux='$EDITOR ~/.tmux.conf.local'

# M1
alias aa='arch -arm64 '
alias ax='arch -x86_64 '
alias brewx='ax /usr/local/bin/brew'

# Git
alias g='git'
alias p="git add -A -N && git add -p"
alias s="git status -sb"
# Skips husky hooks
mn() {
  git commit -m "$*" --no-verify
}
alias gam="git commit --amend --no-edit"
alias gp="git push"
alias gl="git pull"
alias gr="git reset"
alias gff="git flow feature"
alias gg="cd-gitroot"
alias mj="gitmoji -c"
alias gm="git merge"
alias gmm="if git show-ref -q --heads main; then; git merge main; else; git merge master; fi"
alias gps="gh pr status"
alias gpc="gh pr checkout"
alias gpl="gh pr list"
alias gpm="gh pr list --author '@me'"
alias gfr='git fetch && git rebase'
alias glog="git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias gd='git diff'
alias gc='git commit'
alias gca='git commit --amend'
alias gco='git checkout'
alias gcb='git rev-parse --abbrev-ref HEAD | tr -d "\n" | pbcopy'
alias gcos='git checkout staging'
alias gb='git branch'
alias ga="git add"
alias ga.="git add ."
alias gaa="git add --all"
alias gai="git add -i"
alias gs="git stash"
alias gsp="git stash pop"
gcam() {
  git add --all && git commit -m "$*"
}
alias gcaa="git commit -a --amend"
alias gco-="git checkout -"
alias gcob="git checkout -b"
alias gcom="if git show-ref -q --heads main; then; git checkout main; else; git checkout master; fi"
alias gcod="git checkout develop"
alias gcl="git clone"
alias gcln="git clean"
alias gdc="git diff --name-only --diff-filter=U"
alias gds="git diff --staged"
alias gfo="git fetch origin"
alias gpr="gh pr"
alias gq="ghq get -l"
gqe() { ghq get -l eventpop/$* }
gqn() { ghq get -l narze/$* }
gpuo() { git push -u origin $(git rev-parse --abbrev-ref HEAD) }
alias gmd="git merge develop"
alias grm="if git show-ref -q --heads main; then; git rebase main; else; git rebase master; fi"
alias grh="git reset HEAD"
alias grp="git rebase -p"
alias gpw="gh pr view -w"
alias grw="gh repo view -w"
alias gsub="git submodule update --init --recursive --remote"
alias gli="git ls-files -o -i --exclude-standard --directory | grep -v '\.DS_Store'"
alias glr="git pull --rebase"

# Ruby/Rails
alias rdm="bundle exec rake db:migrate"
alias rdt="bundle exec rake db:test:load"
alias ss="bundle exec spring stop"

# Rust
alias cg="cargo"
alias ct="cargo test"
alias ctw="cargo watch -x test"

# Misc
alias -- -='cd -'
alias a="asdf"
alias arst="asdf"
alias b="bundle"
alias be="bundle exec"
alias bi="bundle install"
alias bf="bh | fzy"
alias blog='gq narze/monosor.com && git pull'
alias br="brew"
alias brci="brew install --cask"
alias bri="brew install"
alias brs="brew search"
alias bz="blitz"
alias cl="clear"
alias c='cd ~/Code && ls'
alias c.="code ."
alias cd.="code --user-data-dir /tmp/code-data/ --disable-extensions ."
# alias c.="RUBYOPT=--jit code ."
alias cn='cd ~/Code/narze && ls'
alias co="RUBYOPT=--jit code"
alias cwd='pwd | pbcopy'
f() {
	local dir
	dir=$(find ${1:-.} -path '*/\.*' -prune -o -type d -print 2> /dev/null | fzy) && cd "$dir"
}
# This command is slow! (100ms)
# alias finder="cd \"$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')\""
alias bss='bin/spring stop'
alias da='direnv allow'
alias de='direnv edit'
alias ex='exercism'
alias fixappleeventsbug='sudo killall -KILL appleeventsd'
alias gowd='cd "`pbpaste`"'
alias gu="gitupdate"
alias h='helm'
alias hdi='howdoi'
alias ip='curl ifconfig.me'
alias jsc='/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Resources/jsc'
alias qr='qrcode'
alias sand='cd ~/Sandbox && ls'
alias l='eza -la --icons'
alias lt='cd ~/laptop'
alias ltgl='cd ~/laptop && git pull'
alias mk='minikube'
alias mux='tmuxinator'
alias nf='neofetch'
alias o.="open ."
alias o="open"
alias please='sudo bash -c "$(fc -l -1 | cut -d " " -f 4-)"'
alias postmaster='rm ~/Library/Application\ Support/Postgres/var-12/postmaster.pid'
alias r="bundle exec rails"
alias rc="bundle exec rails console"
alias rge="bundle exec rails generate"
alias rs="bundle exec rails server"
alias redo='sudo !!'
alias reload='exec $SHELL -l'
# alias serve='python -m SimpleHTTPServer 8000'
alias t=touch-safe
alias te=touch-editor
alias tg=terragrunt
alias tf=terraform
alias tm=tmux
alias tmux="direnv exec / tmux"
alias tn='terminal-notifier'
alias tnm='terminal-notifier -message'
alias uuid='uuidgen | tr "[:upper:]" "[:lower:]"'
alias v="nvim"
alias vim="nvim"
alias nv="nvim"
alias va="vagrant"
alias vl="vault"
alias wa="watch "
alias watch="watch "
alias wh="which "
alias wiki="gq narze/knowledge"
alias ya='yarn'
alias yd='yarn dev'
alias yr='yarn run'
alias yt='yarn test'
alias ytw='yarn test --watch'
alias zd='cd $(zq -i)'
alias zt="zerotier-cli"
alias zs='zsh_stats'

# Docker & Kubernetes
alias d='docker'
alias dx='docker exec'
alias ds='docker ps'
alias dc='docker-compose'
alias k='kubectl'
alias kc='kubectx'
alias kn='kubens'
alias kg='kubectl get'
alias kgj='kubectl get job'
alias kgn='kubectl get node'
alias kgz='kubectl get secret'
alias kd='kubectl describe'
alias kx='kubectl exec'

# Unused aliases
ua() {
  one_alphabet_aliases=$(alias | gsed -E 's/=.*//g' | gsed -E '/^.{1}$/!d' | sort)
  alphas=$(echo "qwfpgjluy:[]arstdhneio'zxcvbkm,./" | grep -o . | sort)
  unused_aliases=$(comm -23 <(echo $alphas) <(echo $one_alphabet_aliases))
  echo "Unused aliases $(echo $unused_aliases | wc -l): "
  echo $unused_aliases | paste -s -d " " -
}
