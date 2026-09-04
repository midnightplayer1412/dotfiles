require("config.core.options")
require("config.core.keymaps")

if vim.g.vscode then
	-- VSCode extension
	require("config.core.vscode")
end
