return {
	-- Database client (PostgreSQL, MySQL, SQLite — all in one)
	{
		"tpope/vim-dadbod",
		lazy = true,
	},

	-- Visual UI: sidebar tree of connections, databases, tables
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			"tpope/vim-dadbod",
			"kristijanhusak/vim-dadbod-completion",
		},
		cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
		keys = {
			{ "<leader>db", "<cmd>DBUIToggle<cr>", desc = "Toggle DB UI" },
			{ "<leader>da", "<cmd>DBUIAddConnection<cr>", desc = "Add DB connection" },
		},
		init = function()
			vim.g.db_ui_use_nerd_fonts = 1
			vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
			-- Auto-execute SQL on save in dadbod buffers
			vim.g.db_ui_execute_on_save = 1
		end,
	},

	-- SQL autocomplete: table names, column names, keywords
	{
		"kristijanhusak/vim-dadbod-completion",
		dependencies = { "tpope/vim-dadbod" },
		ft = { "sql", "mysql", "plsql" },
		config = function()
			-- Hook into nvim-cmp sources for SQL files
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "sql", "mysql", "plsql" },
				callback = function()
					require("cmp").setup.buffer({
						sources = {
							{ name = "vim-dadbod-completion" },
							{ name = "buffer" },
						},
					})
				end,
			})
		end,
	},
}

-- USAGE:
-- 1. Open DB UI:         <leader>db
-- 2. Add connection:     <leader>da
--    PostgreSQL URL:     postgresql://user:password@localhost:5432/mydb
--    AWS RDS URL:        postgresql://user:password@your-rds-endpoint:5432/mydb
-- 3. Browse tables, press <CR> to open, gE to execute query
