-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Sync yanked text to the system clipboard, but not deleted/changed text.
-- Pairs with `vim.opt.clipboard = ""` in options.lua.
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Sync yank (not delete/change) to the system clipboard",
  group = vim.api.nvim_create_augroup("sync_yank_to_clipboard", { clear = true }),
  callback = function()
    if vim.v.event.operator == "y" then
      vim.fn.setreg("+", vim.v.event.regcontents)
    end
  end,
})
