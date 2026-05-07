return {
  {
    "bjarneo/vantablack.nvim",
    config = function()
      require("vantablack").setup({
        transparent = true,
        styles = {
          sidebars = "transparent",
          floats = "transparent",
        },
        colors = {
          bg = "#0d0d0d",
          bg_dark = "#0d0d0d",
          bg_dark1 = "#0d0d0d",
          bg_highlight = "#1a1a1a",
          blue = "#3584e4",
          blue0 = "#3584e4",
          blue1 = "#3584e4",
          blue2 = "#3584e4",
          blue5 = "#7f8c8d",
          blue6 = "#3584e4",
          blue7 = "#3584e4",
          comment = "#7f8c8d",
          cyan = "#1abc9c",
          dark3 = "#1a1a1a",
          dark5 = "#7f8c8d",
          fg = "#ffffff",
          fg_dark = "#ecf0f1",
          fg_gutter = "#1a1a1a",
          green = "#2ecc71",
          green1 = "#2ecc71",
          green2 = "#2ecc71",
          magenta = "#9b59b6",
          magenta2 = "#9b59b6",
          orange = "#f39c12",
          purple = "#9b59b6",
          red = "#e74c3c",
          red1 = "#e74c3c",
          teal = "#1abc9c",
          terminal_black = "#1a1a1a",
          yellow = "#f39c12",
          special_char = "#3584e4",
        },
        on_colors = function(colors) end,
        on_highlights = function(highlights, colors) end,
      })
      vim.cmd("colorscheme vantablack")
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "vantablack",
    },
  },
}