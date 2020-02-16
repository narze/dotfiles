.PHONY: help

help:
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

_sudo:
# Ask for the administrator password upfront
	@sudo -n true || sudo -v

# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
	@while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

bootstrap: dotfiles _bootstrap ## Bootstrap new machine

_bootstrap: _sudo
	@./install -c bootstrap.conf.yml

dotfiles: ## Update dotfiles
	@./install

code: ## Clone Repositories with ghq
	@./install -c code.conf.yml

brew: ## Install brew & cask packages
	@./install -c packages.conf.yml

tools: ## Install non-brew tools eg. tmux package manager
	@./install -c tmux.conf.yml

all: dotfiles bootstrap code brew tools ## Run all tasks at once
