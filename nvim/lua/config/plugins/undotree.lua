return {
	"mbbill/undotree",
	cmd = "UndotreeToggle", -- loads only when needed
	keys = {
		{ "<leader>u", "<cmd>UndotreeToggle<CR>", desc = "Toggle Undotree" },
	},
	config = function()
		-- Optional: customize Undotree settings
		vim.g.undotree_WindowLayout = 2 -- vertical split
		vim.g.undotree_SetFocusWhenToggle = 1
	end,
}
