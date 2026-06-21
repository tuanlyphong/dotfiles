return {
	-- Proper Java LSP wiring (Mason installs the binary; this plugin connects it)
	{
		"mfussenegger/nvim-jdtls",
		dependencies = { "folke/which-key.nvim" },
		ft = { "java" },
		opts = function()
			return {
				-- jdtls binary installed by Mason
				cmd = {
					vim.fn.stdpath("data") .. "/mason/bin/jdtls",
					"--jvm-arg=-Xms1g",
					"--jvm-arg=-Xmx4g",
				},
				root_dir = vim.fs.dirname(vim.fs.find({ "pom.xml", "build.gradle", ".git" }, { upward = true })[1]),
				settings = {
					java = {
						inlayHints = { parameterNames = { enabled = "all" } },
						format = { enabled = true },
						saveActions = { organizeImports = true },
						completion = {
							favoriteStaticMembers = {
								"org.junit.Assert.*",
								"org.junit.jupiter.api.Assertions.*",
								"org.mockito.Mockito.*",
							},
						},
						sources = {
							organizeImports = {
								starThreshold = 9999,
								staticStarThreshold = 9999,
							},
						},
						codeGeneration = {
							toString = {
								template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
							},
							useBlocks = true,
						},
					},
				},
				-- Java-specific keymaps (only active in .java files)
				on_attach = function(_, bufnr)
					local jdtls = require("jdtls")
					local opts = { buffer = bufnr, silent = true }
					vim.keymap.set(
						"n",
						"<leader>jo",
						jdtls.organize_imports,
						vim.tbl_extend("force", opts, { desc = "Organize imports" })
					)
					vim.keymap.set(
						"n",
						"<leader>jv",
						jdtls.extract_variable,
						vim.tbl_extend("force", opts, { desc = "Extract variable" })
					)
					vim.keymap.set(
						"n",
						"<leader>jc",
						jdtls.extract_constant,
						vim.tbl_extend("force", opts, { desc = "Extract constant" })
					)
					vim.keymap.set("v", "<leader>jm", function()
						jdtls.extract_method(true)
					end, vim.tbl_extend("force", opts, { desc = "Extract method" }))
					vim.keymap.set(
						"n",
						"<leader>jt",
						jdtls.test_nearest_method,
						vim.tbl_extend("force", opts, { desc = "Test nearest method" })
					)
					vim.keymap.set(
						"n",
						"<leader>jT",
						jdtls.test_class,
						vim.tbl_extend("force", opts, { desc = "Test class" })
					)
				end,
			}
		end,
		config = function(_, opts)
			-- Attach jdtls whenever a Java file opens
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "java",
				callback = function()
					require("jdtls").start_or_attach(opts)
				end,
			})
		end,
	},

	-- Uncomment dap.core extra in lazy.lua OR add nvim-dap here for Java debugging
	{
		"mfussenegger/nvim-dap",
		optional = true,
		dependencies = { "mfussenegger/nvim-jdtls" },
	},

	-- Add java + html/xml to treesitter (merge with your existing treesitter.lua)
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			vim.list_extend(opts.ensure_installed, {
				"html",
				"typescript",
				"javascript",
				"tsx",
				"json",
				"yaml",
				"dockerfile",
				"bash",
			})
		end,
	},
}
