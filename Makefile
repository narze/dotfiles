.PHONY: help

help: ## Print command list
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

_prepare:
	@git submodule update --init --recursive

bootstrap: _prepare dotfiles _bootstrap macos ## Bootstrap new machine

_bootstrap:
	@./install -c config/bootstrap.conf.yml

dotfiles: ## Update dotfiles
	@./install

macos: ## Run macos script
	@./etc/macos

code: ## Clone Repositories with ghq
	@./install -c config/code.conf.yml --plugin-dir dotbot-ghq

brew: ## Install brew & cask packages
	@./install -c config/packages.conf.yml

tools: ## Install non-brew tools eg. tmux package manager
	@./install -c config/tmux.conf.yml

asdf: ## Install asdf-vm
	@./install -c config/asdf-install.conf.yml
	@./install -c config/asdf.conf.yml --plugin-dir dotbot-asdf

sync: ## Sync local configuration from Google Drive, Dropbox, etc.
	@./install -c config/sync.conf.yml

update: ## Update everything
	@make _prepare
	@./install -c config/update.conf.yml

all: _prepare dotfiles _bootstrap code brew tools asdf sync ## Run all tasks at once
