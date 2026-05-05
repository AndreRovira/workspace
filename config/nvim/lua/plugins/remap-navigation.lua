-- Override plugin-specific keybindings to match custom movement: j=left, k=up, l=down, ;=right

return {
  -- Snacks picker/explorer: remap navigation keys
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        -- Override default list keybindings for all pickers
        win = {
          list = {
            keys = {
              ["l"] = "list_down",
              ["k"] = "list_up",
              ["j"] = false,
            },
          },
        },
        sources = {
          explorer = {
            win = {
              list = {
                keys = {
                  -- l = move down in list (was j)
                  ["l"] = "list_down",
                  -- k = move up (unchanged)
                  ["k"] = "list_up",
                  -- ; = open/expand (was l)
                  [";"] = "confirm",
                  -- j = collapse/close dir (was h)
                  ["j"] = "explorer_close",
                  -- h = disabled (globally remapped to repeat f/t)
                  ["h"] = false,
                },
              },
            },
          },
        },
      },
    },
  },

  -- Neo-tree (in case user enables it as extra): remap navigation keys
  {
    "nvim-neo-tree/neo-tree.nvim",
    optional = true,
    opts = {
      window = {
        mappings = {
          ["h"] = "noop",
          ["j"] = "close_node",
          ["l"] = {
            function()
              vim.cmd("normal! j")
            end,
            desc = "Move down",
          },
          [";"] = "open",
        },
      },
    },
  },
}
