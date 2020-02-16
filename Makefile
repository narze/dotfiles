.PHONY: help

help:
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

_sudo:
## Ask for the administrator password upfront
	@sudo -v

# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
	@while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

setup: dotfiles bootstrap ## Bootstrap new machine

bootstrap: _sudo
	@./install -c bootstrap.conf.yml

dotfiles: ## Update dotfiles
	@./install

code: ## Clone Repositories with ghq
	@./install -c code.conf.yml

brew: ## Install brew & cask packages
	@./install -c packages.conf.yml

all: dotfiles bootstrap code brew ## Run all tasks at once
