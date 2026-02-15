return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"neovim/nvim-lspconfig",
		"hrsh7th/cmp-nvim-lsp",
		{ "folke/neodev.nvim", opts = {} },
	},
	event = { "BufReadPre", "BufNewFile" },
	build = ":MasonUpdate",
	config = function()
		-- 1. Setup completion capabilities
		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- 2. Configure LSP servers using vim.lsp.config() (new API)

    vim.lsp.config("qmlls", {
      capabilities = capabilities,
      settings = {
        -- This tells the LSP where to look for Quickshell & Qt modules
        qml = {
          importPaths = {
            "/usr/lib/qt6/qml",
            "/usr/lib/quickshell",
            "./",
          },
        },
      },
    })

		-- Lua
		vim.lsp.config("lua_ls", {
			capabilities = capabilities,
			settings = {
				Lua = {
					diagnostics = { globals = { "vim" } },
					workspace = {
						library = vim.api.nvim_get_runtime_file("", true),
						checkThirdParty = false,
					},
				},
			},
		})

		-- PHP / Laravel
		vim.lsp.config("intelephense", {
			capabilities = capabilities,
			settings = {
				intelephense = {
					files = {
						associations = { "*.php", "*.blade.php" },
					},
					environment = {
						includePaths = { "vendor" },
					},
				},
			},
		})

		-- HTML / Blade
		vim.lsp.config("html", {
			capabilities = capabilities,
			filetypes = { "html", "blade" },
		})

		-- Emmet for Blade & HTML
		vim.lsp.config("emmet_ls", {
			capabilities = capabilities,
			filetypes = {
				"html",
				"blade",
				"css",
				"javascriptreact",
				"typescriptreact",
				"svelte",
			},
		})

		-- CSS
		vim.lsp.config("cssls", {
			capabilities = capabilities,
		})

		-- TypeScript
		vim.lsp.config("ts_ls", {
			capabilities = capabilities,
		})

		-- Python
		vim.lsp.config("pyright", {
			capabilities = capabilities,
		})

		-- C/C++
		vim.lsp.config("clangd", {
			capabilities = capabilities,
		})

		-- 3. Setup mason
		local mason = require("mason")
		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		-- 4. Setup mason-lspconfig (with automatic_enable)
		local has_mason_lspconfig, mason_lspconfig = pcall(require, "mason-lspconfig")
		if not has_mason_lspconfig then
			vim.notify("mason-lspconfig not found! Please run :Lazy sync", vim.log.levels.ERROR)
			return
		end

		mason_lspconfig.setup({
			ensure_installed = {
				"intelephense",
				"html",
				"cssls",
				"emmet_ls",
				"lua_ls",
				"ts_ls",
				"pyright",
				"clangd",
				"qmlls",
			},
			automatic_enable = true, -- Automatically enable installed servers
		})

		-- 5. Diagnostic icons
		local signs = { Error = "", Warn = "", Hint = "󰠠", Info = "" }
		vim.diagnostic.config({
			virtual_text = {
				prefix = "●", -- could be '■', '▎', '●', etc.
				spacing = 2,
			},
			signs = true, -- show the sign column icons
			underline = true, -- underline problematic code
			update_in_insert = false, -- don't update diagnostics while typing
			severity_sort = true, -- sort by severity
			float = {
				border = "rounded", -- border style for floating window
				source = true, -- show source (LSP server name) in float
				header = "",
				prefix = "",
			},
		})

		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end

		-- 6. Keymaps when LSP attaches
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				local opts = { buffer = ev.buf, silent = true }
				local keymap = vim.keymap

				keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
				keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
				keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", opts)
				keymap.set("n", "K", vim.lsp.buf.hover, opts)
				keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
				keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts) -- send all diagnostics to location list
				keymap.set("n", "<leader>gg", function()
					require("telescope.builtin").diagnostics({ bufnr = 0 }) -- current buffer
				end, opts)
			end,
		})
	end,
}
