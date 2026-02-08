return {
  {'akinsho/toggleterm.nvim', version = "*", 
    config = function()
      local toggleterm = require("toggleterm")

      toggleterm.setup({
        -- Default config (used for <C-\>)
        open_mapping = [[<c-\>]],
        direction = 'horizontal',
        size = 15,
      })

      -- Helper to create terminals in different directions
      local Terminal = require("toggleterm.terminal").Terminal

      -- Vertical terminal
      local vertical_term = Terminal:new({
        direction = "vertical",
        size = 40,
        hidden = true,
      })

      -- Floating terminal
      local float_term = Terminal:new({
        direction = "float",
        hidden = true,
      })

      -- Tab terminal
      local tab_term = Terminal:new({
        direction = "tab",
        hidden = true,
      })

      -- Key mappings for custom terminals
      vim.keymap.set({"n", "t"}, "<leader>tv", function()
        -- Escape terminal mode if needed
        if vim.fn.mode() == "t" then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", false)
        end
        vertical_term:toggle()
      end, { desc = "Toggle Vertical Terminal" })

      vim.keymap.set({"n", "t"}, "<leader>tf", function()
        if vim.fn.mode() == "t" then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", false)
        end
        float_term:toggle()
      end, { desc = "Toggle Floating Terminal" })

      vim.keymap.set({"n", "t"}, "<leader>tt", function()
        if vim.fn.mode() == "t" then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", false)
        end
        tab_term:toggle()
      end, { desc = "Toggle Tab Terminal" })
    end 
  }
}
