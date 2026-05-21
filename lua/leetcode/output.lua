local util = require("leetcode.util")
local config = require("leetcode.config")

local M = {}

function M.show(title, content, opts)
  opts = opts or {}
  content = util.strip_ansi(util.redact(content or ""))
  local lines = util.split_lines(content)

  vim.cmd(config.get().output.split)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "leetcode://" .. (title or "output"))
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "leetcode-output"
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  if opts.return_to and vim.api.nvim_win_is_valid(opts.return_to) then
    vim.api.nvim_set_current_win(opts.return_to)
  end
end

return M
