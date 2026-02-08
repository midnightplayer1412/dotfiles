-- Register blade filetype
vim.filetype.add({
  pattern = {
    [".*%.blade%.php"] = "blade",
  },
})

return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  config = function()
    -- Register blade language
    vim.treesitter.language.register("blade", "blade")

    -- Manually attach highlighter for blade files
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "blade",
      callback = function(args)
        vim.treesitter.start(args.buf, "blade")
      end,
    })
  end,
}
