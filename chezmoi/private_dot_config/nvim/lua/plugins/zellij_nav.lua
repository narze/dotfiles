-- return {
--   {
--     "https://github.com/fresh2dev/zellij.vim",
--     -- Pin version to avoid breaking changes.
--     -- tag = '0.3.*',
--     lazy = false,
--     init = function()
--       -- Options:
--       -- vim.g.zelli_navigator_move_focus_or_tab = 1
--       vim.g.zellij_navigator_no_default_mappings = 1
--     end,
--     keys = {
--       { "<c-m>", "<cmd>ZellijNavigateLeft<cr>", { silent = true, desc = "navigate left or tab" } },
--       { "<c-n>", "<cmd>ZellijNavigateDown<cr>", { silent = true, desc = "navigate down" } },
--       { "<c-k>", "<cmd>ZellijNavigateUp<cr>", { silent = true, desc = "navigate up" } },
--       { "<c-l>", "<cmd>ZellijNavigateRight<cr>", { silent = true, desc = "navigate right or tab" } },
--     },
--   },
-- }

return {
  {
    "https://git.sr.ht/~swaits/zellij-nav.nvim",
    lazy = true,
    event = "VeryLazy",
    keys = {
      { "<c-m>", "<cmd>ZellijNavigateLeftTab<cr>", { silent = true, desc = "navigate left or tab" } },
      { "<c-n>", "<cmd>ZellijNavigateDown<cr>", { silent = true, desc = "navigate down" } },
      { "<c-k>", "<cmd>ZellijNavigateUp<cr>", { silent = true, desc = "navigate up" } },
      { "<c-l>", "<cmd>ZellijNavigateRightTab<cr>", { silent = true, desc = "navigate right or tab" } },
      {
        "<c-w>h",
        "<cmd>ZellijNavigateLeftTab<cr>",
        { remap = true, silent = true, desc = "(Zellij) navigate left or tab" },
      },
      { "<c-w>j", "<cmd>ZellijNavigateDown<cr>", { remap = true, silent = true, desc = "(Zellij) navigate down" } },
      { "<c-w>k", "<cmd>ZellijNavigateUp<cr>", { remap = true, silent = true, desc = "(Zellij) navigate up" } },
      { "<c-w>l", "<cmd>ZellijNavigateRightTab<cr>", { remap = true, silent = true, desc = "navigate right or tab" } },
    },
    opts = {},
  },
}
