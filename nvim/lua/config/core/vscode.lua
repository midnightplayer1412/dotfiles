-- Keymaps for when Neovim is embedded in VS Code (vscode-neovim).
--
-- Neovim's own windows, tabs and file tree have no visible UI here, so the
-- window/tab/Neotree maps in keymaps.lua are re-pointed at the equivalent
-- VS Code commands. Insert-mode maps (jk, <C-BS>) cannot work at all -- VS Code
-- handles typing and never forwards it -- so "jk" lives in settings.json under
-- "vscode-neovim.compositeKeys" instead.

local vscode = require("vscode")
local map = vim.keymap.set

local function action(name)
	return function()
		vscode.action(name)
	end
end

-- window management -> VS Code editor groups
map("n", "<leader>sv", action("workbench.action.splitEditorRight"), { desc = "Split editor right" })
map("n", "<leader>sh", action("workbench.action.splitEditorDown"), { desc = "Split editor down" })
map("n", "<leader>se", action("workbench.action.evenEditorWidths"), { desc = "Even editor widths" })
map("n", "<leader>sx", action("workbench.action.closeActiveEditor"), { desc = "Close editor" })

-- tabs -> VS Code editors
map("n", "<leader>to", action("workbench.action.files.newUntitledFile"), { desc = "New file" })
map("n", "<leader>tx", action("workbench.action.closeActiveEditor"), { desc = "Close editor" })
map("n", "<leader>tn", action("workbench.action.nextEditor"), { desc = "Next editor" })
map("n", "<leader>tp", action("workbench.action.previousEditor"), { desc = "Previous editor" })

-- file tree -> VS Code explorer
map("n", "<leader>ee", action("workbench.view.explorer"), { desc = "Focus explorer" })

-- LSP / navigation, which VS Code owns here
-- these mirror the Telescope maps in plugins/telescope.lua
map("n", "<leader>ff", action("workbench.action.quickOpen"), { desc = "Fuzzy find files in cwd" })
map("n", "<leader>fr", action("workbench.action.openRecent"), { desc = "Fuzzy find recent files" })
map("n", "<leader>fs", action("workbench.action.findInFiles"), { desc = "Find string in cwd" })
map("n", "<leader>fc", function()
	vscode.action("workbench.action.findInFiles", { args = { query = vim.fn.expand("<cword>") } })
end, { desc = "Find string under cursor in cwd" })
map("n", "gr", action("editor.action.goToReferences"), { desc = "Go to references" })
map("n", "<leader>rn", action("editor.action.rename"), { desc = "Rename symbol" })
map("n", "<leader>ca", action("editor.action.quickFix"), { desc = "Code action" })

-- <leader>w acts as <C-w> (keymaps.lua). That remap stays inside Neovim, so it
-- drives windows VS Code never renders and looks dead. The extension binds the
-- real Ctrl+W chords in its package.json; mirror that same table onto <leader>w.
local window_cmds = {
	h = "workbench.action.navigateLeft",
	j = "workbench.action.navigateDown",
	k = "workbench.action.navigateUp",
	l = "workbench.action.navigateRight",
	w = "workbench.action.focusNextGroup",
	s = "workbench.action.splitEditorDown",
	v = "workbench.action.splitEditorRight",
	q = "workbench.action.closeActiveEditor",
	c = "workbench.action.closeActiveEditor",
	["="] = "workbench.action.evenEditorWidths",
	["_"] = "workbench.action.toggleEditorWidths",
	["<"] = "workbench.action.decreaseViewWidth",
	[">"] = "workbench.action.increaseViewWidth",
	["+"] = "workbench.action.increaseViewHeight",
	["-"] = "workbench.action.decreaseViewHeight",
}

for key, cmd in pairs(window_cmds) do
	map("n", "<leader>w" .. key, action(cmd), { desc = "Window: " .. cmd:gsub("workbench%.action%.", "") })
end

-- arrow-key variants, matching the extension's Ctrl+W bindings
map("n", "<leader>w<Left>", action("workbench.action.navigateLeft"), { desc = "Window: navigateLeft" })
map("n", "<leader>w<Down>", action("workbench.action.navigateDown"), { desc = "Window: navigateDown" })
map("n", "<leader>w<Up>", action("workbench.action.navigateUp"), { desc = "Window: navigateUp" })
map("n", "<leader>w<Right>", action("workbench.action.navigateRight"), { desc = "Window: navigateRight" })

-- drop the bare <leader>w -> <C-w> fallback: uncovered keys would otherwise
-- still operate on Neovim's invisible window layout
pcall(vim.keymap.del, "n", "<leader>w")
