.PHONY: help

help: ## Print command list
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

_prepare:
	@git submodule update --init --recursive

bootstrap: _prepare dotfiles _bootstrap ## Bootstrap new machine

_bootstrap:
	@./install -c config/bootstrap.conf.yml

dotfiles: ## Update dotfiles
	@./install

code: ## Clone Repositories with ghq
	@./install -c config/code.conf.yml

brew: ## Install brew & cask packages
	@./install -c config/packages.conf.yml

tools: ## Install non-brew tools eg. tmux package manager
	@./install -c config/tmux.conf.yml

all: dotfiles bootstrap code brew tools ## Run all tasks at once
