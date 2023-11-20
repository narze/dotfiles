abbr - "cd -"
abbr .tmux "\$EDITOR ~/.tmux.conf.local"
abbr aa "arch -arm64 "
abbr ag "argocd"
abbr aliases "\$EDITOR ~/.config/zsh/config/00_aliases.zsh ; reload ; echo \"Aliases reloaded\""
abbr arst "asdf"
abbr ax "arch -x86_64 "
abbr b "bundle"
abbr be "bundle exec"
abbr bf "bh | fzy"
abbr bi "bundle install"
abbr blog "gq narze/monosor.com && git pull"
abbr br "brew"
abbr brci "brew install --cask"
abbr brewx "ax /usr/local/bin/brew"
abbr bri "brew install"
abbr brs "brew search"
abbr bss "bin/spring stop"
abbr c "cd ~/Code && ls"
abbr c. "code ."
abbr cd. "code --user-data-dir /tmp/code-data/ --disable-extensions ."
abbr cg "cargo"
abbr cl "clear"
abbr cm "chezmoi -k"
abbr cn "cd ~/Code/narze && ls"
abbr co "cd ~/Code/o*/ && ls"
abbr ct "cargo test"
abbr ctw "cargo watch -x test"
abbr cwd "pwd | pbcopy"
abbr d "docker"
abbr da "direnv allow"
abbr dc "docker-compose"
abbr ds "docker ps"
abbr dx "docker exec"
abbr ex "exercism"
abbr fixappleeventsbug "sudo killall -KILL appleeventsd"
abbr fsh-alias "fast-theme"
abbr funcs "\$EDITOR ~/.config/zsh/config/20_functions.zsh ; reload ; echo \"Aliases reloaded\""
abbr g "git"
abbr ga "git add"
abbr ga. "git add ."
abbr gaa "git add --all"
abbr gai "git add -i"
abbr gam "git commit --amend --no-edit"
abbr gb "git branch"
abbr gc "git commit"
abbr gca "git commit --amend"
abbr gcaa "git commit -a --amend"
abbr gcb '"git rev-parse --abbrev-ref HEAD | tr -d \"'
abbr gcl "git clone"
abbr gcln "git clean"
abbr gco "git checkout"
abbr gco- "git checkout -"
abbr gcob "git checkout -b"
abbr gcod "git checkout develop"
abbr gcom 'if git show-ref -q --heads main; git checkout main; else; git checkout master; end'
abbr gcos "git checkout staging"
abbr gd "git diff"
abbr gdc "git diff --name-only --diff-filter=U"
abbr gds "git diff --staged"
abbr gff "git flow feature"
abbr gfo "git fetch origin"
abbr gfr "git fetch && git rebase"
abbr gg "cd-gitroot"
abbr gl "git pull"
abbr gli "git ls-files -o -i --exclude-standard --directory | grep -v '\.DS_Store'"
abbr glog "git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
abbr glr "git pull --rebase"
abbr gm "git merge"
abbr gmd "git merge develop"
abbr gmm 'if git show-ref -q --heads main; git merge main; else; git merge master; end'
abbr gowd "cd \"\`pbpaste\`\""
abbr gp "git push"
abbr gpc "gh pr checkout"
abbr gpl "gh pr list"
abbr gpr "gh pr"
abbr gps "gh pr status"
abbr gpw "gh pr view -w"
abbr gq "ghq get -l"
abbr gr "git reset"
abbr grh "git reset HEAD"
abbr grm 'if git show-ref -q --heads main; git rebase main; else; git rebase master; end'
abbr grp "git rebase -p"
abbr grw "gh repo view -w"
abbr gs "git status -s -b && git log --oneline -n5 2>/dev/null || :"
abbr gst "git stash"
abbr gsub "git submodule update --init --recursive --remote"
abbr gu "gitupdate"
abbr h "helm"
abbr hdi "howdoi"
abbr history "omz_history"
abbr ip "curl ifconfig.me"
abbr jsc "/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Resources/jsc"
abbr k "kubectl"
abbr kaf "kubectl apply -f"
abbr kc "kubectx"
abbr kd "kubectl describe"
abbr kdcm "kubectl describe configmap"
abbr kdd "kubectl describe deployment"
abbr kz "kubectl delete"
abbr kzcj "kubectl delete cronjob"
abbr kzcm "kubectl delete configmap"
abbr kzd "kubectl delete deployment"
abbr kzds "kubectl delete daemonset"
abbr kzf "kubectl delete -f"
abbr kzi "kubectl delete ingress"
abbr kzno "kubectl delete node"
abbr kzns "kubectl delete namespace"
abbr kzp "kubectl delete pods"
abbr kzpvc "kubectl delete pvc"
abbr kzs "kubectl delete svc"
abbr kzsa "kubectl delete sa"
abbr kzsec "kubectl delete secret"
abbr kzss "kubectl delete statefulset"
abbr kdi "kubectl describe ingress"
abbr kdp "kubectl describe pods"
abbr kds "kubectl describe svc"
abbr kdsec "kubectl describe secret"
abbr ke "\$EDITOR ~/dotfiles/etc/karabiner.edn"
abbr ked "kubectl edit deployment"
abbr kei "kubectl edit ingress"
abbr kep "kubectl edit pods"
abbr kes "kubectl edit svc"
abbr kg "kubectl get"
abbr kga "kubectl get all"
abbr kgaa "kubectl get all --all-namespaces"
abbr kgd "kubectl get deployment"
abbr kgi "kubectl get ingress"
abbr kgp "kubectl get pods"
abbr kgpl "kgp -l"
abbr kgpn "kgp -n"
abbr kgpw "kgp --watch"
abbr kgs "kubectl get svc"
abbr kgsec "kubectl get secret"
abbr kgz "kubectl get secret"
abbr kl "kubectl logs"
abbr kl1h "kubectl logs --since 1h"
abbr kl1m "kubectl logs --since 1m"
abbr kl1s "kubectl logs --since 1s"
abbr klf "kubectl logs -f"
abbr klf1h "kubectl logs --since 1h -f"
abbr klf1m "kubectl logs --since 1m -f"
abbr klf1s "kubectl logs --since 1s -f"
abbr kn "kubens"
abbr kpf "kubectl port-forward"
abbr kx "kubectl exec"
abbr l "ls -la"
abbr ls "exa --icons"
abbr lt "cd ~/laptop"
abbr ltgl "cd ~/laptop && git pull"
abbr m "git commit -m"
abbr mj "gitmoji -c"
abbr mux "tmuxinator"
abbr nf "neofetch"
abbr o "open"
abbr o. "open ."
abbr p "git add -A -N && git add -p"
abbr please "sudo bash -c \"\$(fc -l -1 | cut -d \" \" -f 4-)\""
abbr qr "qrcode"
abbr r "bundle exec rails"
abbr rc "bundle exec rails console"
abbr rdm "bundle exec rake db:migrate"
abbr rdt "bundle exec rake db:test:load"
abbr redo "sudo \\!\\!"
abbr reload "exec \$SHELL -l"
abbr rge "bundle exec rails generate"
abbr rs "bundle exec rails server"
abbr run-help "man"
abbr s "git status -sb"
abbr sand "cd ~/Sandbox && ls"
abbr shopt ":"
abbr ss "bundle exec spring stop"
abbr t "task"
abbr te "touch-editor"
abbr tf "terraform"
abbr tg "terragrunt"
abbr tm "tmux"
alias tmux "direnv exec / tmux"
abbr tn "terminal-notifier"
abbr tnm "terminal-notifier -message"
abbr tw "/Users/noom/Downloads/twitch-cli_1.1.1_Darwin_x86_64/twitch"
abbr uuid "uuidgen | tr \"[:upper:]\" \"[:lower:]\""
abbr v "nvim"
abbr va "vagrant"
abbr vim "nvim"
abbr vl "vault"
abbr wa "watch "
abbr watch "watch "
abbr wh "which "
abbr which-command "whence"
abbr wiki "gq narze/knowledge"
abbr ya "yarn"
abbr yd "yarn dev"
abbr yr "yarn run"
abbr yt "yarn test"
abbr ytw "yarn test --watch"
abbr zd "cd \$(zq -i)"
abbr zs "zsh_stats"
abbr zshrc "\$EDITOR ~/.zshrc ; reload"
abbr zt "zerotier-cli"
