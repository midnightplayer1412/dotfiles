local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Under vscode-neovim, VS Code owns the UI: Neovim's windows are never rendered
-- and insert mode never reaches Neovim. UI plugins draw into windows that get
-- torn down underneath them (telescope + neo-tree crash with "Invalid window id")
-- and completion/pairs plugins are simply dead. Allowlist the few that still work.
local vscode_allowlist = {
	["flash.nvim"] = true,
	["nvim-treesitter"] = true, -- flash's S / R modes need it
	["nvim-ts-autotag"] = true, -- treesitter dependency
}

require("lazy").setup({ { import = "config.plugins" }, { import = "config.plugins.lsp" } }, {
	defaults = {
		cond = function(plugin)
			if not vim.g.vscode then
				return true
			end
			return vscode_allowlist[plugin.name] or false
		end,
	},
})
