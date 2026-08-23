return {
  "epwalsh/obsidian.nvim",
  version = "*",  -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  opts = {
    workspaces = {
      {
        name = "pentest-wiki",
        path = "~/pentest-wiki",
      },
    },
    -- Optional: Configure how links are generated
    preferred_link_style = "wiki",
    
    -- Map your Nerd Font icons to specific tags or filetypes
    ui = {
      enable = true, 
      hl_groups = {
        ObsidianExtLinkIcon = { fg = "#c792ea" },
        ObsidianRefText = { underline = true, fg = "#c792ea" },
      },
    },
  },
}
