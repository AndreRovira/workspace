-- Remap plugin keybindings to match jkl; movement layout
-- j=left, k=up, l=down, ;=right, h=repeat f/t
return {
  -- flash.nvim: use h for repeat f/t (since ; is now "right")
  {
    "folke/flash.nvim",
    opts = {
      modes = {
        char = {
          -- flash reads this table as {trigger => lhs}: a *positional* entry means
          -- "map this key to itself", a *string* key means "map flash's <key> motion
          -- onto this other lhs". Only f/F/t/T/;/, are ever consulted, so a bare
          -- "h" in the list is silently dropped -- the remap has to be [";"] = "h".
          -- The list part must stay as long as flash's default (6 entries), because
          -- vim.tbl_deep_extend merges lists index-by-index: a shorter list would
          -- leak flash's default ";" back in and fight the [";"] entry.
          keys = { "f", "F", "t", "T", ",", "h", [";"] = "h" },
        },
      },
    },
  },

  -- snacks.nvim: remap picker + explorer keys
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        win = {
          -- input window (e.g. file finder search box in normal mode)
          input = {
            keys = {
              ["l"] = "list_down",
              ["j"] = false,
            },
          },
          -- list window (all pickers)
          list = {
            keys = {
              ["l"] = "list_down",
              ["j"] = false,
            },
          },
        },
        sources = {
          explorer = {
            win = {
              list = {
                keys = {
                  [";"] = "confirm", -- right = open/expand (was l)
                  ["j"] = "explorer_close", -- left = close/collapse (was h)
                  ["l"] = "list_down", -- down (was j)
                  ["h"] = false, -- clear (was explorer_close)
                },
              },
            },
          },
        },
      },
    },
  },

  -- neo-tree: only applies if the LazyVim editor.neo-tree extra is ever enabled
  {
    "nvim-neo-tree/neo-tree.nvim",
    optional = true,
    opts = {
      window = {
        mappings = {
          ["h"] = "noop", -- freed for flash repeat f/t (was close_node)
          ["j"] = "close_node", -- left = collapse
          ["l"] = {
            function()
              vim.cmd("normal! j")
            end,
            desc = "Move down",
          },
          [";"] = "open", -- right = open/expand
        },
      },
    },
  },
}
