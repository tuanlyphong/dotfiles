return {
	{
		"RRethy/base16-nvim",
		priority = 1000,
		config = function()
			require('base16-colorscheme').setup({
				base00 = '#16130b',
				base01 = '#16130b',
				base02 = '#918e86',
				base03 = '#918e86',
				base04 = '#ebe7dc',
				base05 = '#fffdf8',
				base06 = '#fffdf8',
				base07 = '#fffdf8',
				base08 = '#ffa59c',
				base09 = '#ffa59c',
				base0A = '#f6dd8a',
				base0B = '#b0ffa3',
				base0C = '#fff1c4',
				base0D = '#f6dd8a',
				base0E = '#ffe9a3',
				base0F = '#ffe9a3',
			})

			vim.api.nvim_set_hl(0, 'Visual', {
				bg = '#918e86',
				fg = '#fffdf8',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Statusline', {
				bg = '#f6dd8a',
				fg = '#16130b',
			})
			vim.api.nvim_set_hl(0, 'LineNr', { fg = '#918e86' })
			vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#fff1c4', bold = true })

			vim.api.nvim_set_hl(0, 'Statement', {
				fg = '#ffe9a3',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Keyword', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Repeat', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Conditional', { link = 'Statement' })

			vim.api.nvim_set_hl(0, 'Function', {
				fg = '#f6dd8a',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Macro', {
				fg = '#f6dd8a',
				italic = true
			})
			vim.api.nvim_set_hl(0, '@function.macro', { link = 'Macro' })

			vim.api.nvim_set_hl(0, 'Type', {
				fg = '#fff1c4',
				bold = true,
				italic = true
			})
			vim.api.nvim_set_hl(0, 'Structure', { link = 'Type' })

			vim.api.nvim_set_hl(0, 'String', {
				fg = '#b0ffa3',
				italic = true
			})

			vim.api.nvim_set_hl(0, 'Operator', { fg = '#ebe7dc' })
			vim.api.nvim_set_hl(0, 'Delimiter', { fg = '#ebe7dc' })
			vim.api.nvim_set_hl(0, '@punctuation.bracket', { link = 'Delimiter' })
			vim.api.nvim_set_hl(0, '@punctuation.delimiter', { link = 'Delimiter' })

			vim.api.nvim_set_hl(0, 'Comment', {
				fg = '#918e86',
				italic = true
			})

			local current_file_path = vim.fn.stdpath("config") .. "/lua/plugins/dankcolors.lua"
			if not _G._matugen_theme_watcher then
				local uv = vim.uv or vim.loop
				_G._matugen_theme_watcher = uv.new_fs_event()
				_G._matugen_theme_watcher:start(current_file_path, {}, vim.schedule_wrap(function()
					local new_spec = dofile(current_file_path)
					if new_spec and new_spec[1] and new_spec[1].config then
						new_spec[1].config()
						print("Theme reload")
					end
				end))
			end
		end
	}
}
