-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Movement: shift hjkl one key right → jkl;
-- j=left, k=up (unchanged), l=down, ;=right
-- h is freed up for flash.nvim repeat f/t (was ;)
for _, mode in ipairs({ "n", "x", "o" }) do
  map(mode, "j", "h", { desc = "Left" })
  map(mode, ";", "l", { desc = "Right" })
end

-- Smart down on wrapped lines (matches LazyVim's default j behavior)
map({ "n", "x" }, "l", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map("o", "l", "j", { desc = "Down" })
