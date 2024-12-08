-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Cmd + Enter = My custom keymap group
map("n", "<leader><enter>b", "<Cmd>Neotree toggle<CR>", { desc = "NeoTree toggle" })
