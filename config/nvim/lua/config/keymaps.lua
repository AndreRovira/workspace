-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Custom movement keys: j=left, k=up, l=down, ;=right
-- Swap h and ; so: h=repeat-f/t-forward (was ;), ;=right (was l)
-- k=up is unchanged.

local modes = { "n", "v", "o", "x", "s" }

for _, mode in ipairs(modes) do
  -- Core movement remaps
  vim.keymap.set(mode, "j", "h", { noremap = true, desc = "Left" })
  vim.keymap.set(mode, "l", "j", { noremap = true, desc = "Down" })
  -- k stays as up (no remap needed)
  vim.keymap.set(mode, ";", "l", { noremap = true, desc = "Right" })

  -- h and ; swap: h gets ;'s old function, ; gets l's old function
  vim.keymap.set(mode, "h", ";", { noremap = true, desc = "Repeat f/t forward" })

  -- Shifted variants
  vim.keymap.set(mode, "J", "H", { noremap = true, desc = "Top of screen" })
  vim.keymap.set(mode, "L", "J", { noremap = true, desc = "Join lines" })
  vim.keymap.set(mode, "H", ",", { noremap = true, desc = "Repeat f/t backward" })
end

-- Window navigation: override LazyVim defaults to match new movement keys
vim.keymap.set("n", "<C-j>", "<C-w>h", { noremap = true, desc = "Go to left window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { noremap = true, desc = "Go to upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>j", { noremap = true, desc = "Go to lower window" })
-- Note: <C-;> doesn't work in most terminals, so we use <C-w>; as fallback
vim.keymap.set("n", "<C-w>;", "<C-w>l", { noremap = true, desc = "Go to right window" })

-- Move lines with Alt using new down/up keys (l=down, k=up)
vim.keymap.set("n", "<A-l>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move line down" })
vim.keymap.set("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move line up" })
vim.keymap.set("i", "<A-l>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move line down" })
vim.keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move line up" })
vim.keymap.set("v", "<A-l>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<A-k>", "<cmd>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move selection up" })

-- Disable LazyVim's default Alt-j/Alt-k move-line mappings so they don't conflict
vim.keymap.del("n", "<A-j>")
vim.keymap.del("i", "<A-j>")
vim.keymap.del("v", "<A-j>")
