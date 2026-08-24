-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- LazyVim defaults to "unnamedplus", which syncs the system clipboard on
-- every yank AND delete/change. Turn that off here; a TextYankPost autocmd
-- in autocmds.lua syncs only actual yanks to the clipboard instead, so d/D
-- (and c/x) no longer clobber it.
vim.opt.clipboard = ""
