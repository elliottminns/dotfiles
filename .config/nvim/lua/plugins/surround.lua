return {
  "kylechui/nvim-surround",
  version = "*", -- use latest stable
  event = "VeryLazy",
  config = function()
    require("nvim-surround").setup({})
  end,
}
