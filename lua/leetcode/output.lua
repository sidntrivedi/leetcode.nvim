local util = require("leetcode.util")
local config = require("leetcode.config")

local M = {}

local function output_name(title)
  return "leetcode://" .. (title or "output")
end

local function find_buffer(name)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf) == name then
      return buf
    end
  end
  return nil
end

function M.show(title, content, opts)
  opts = opts or {}
  content = util.strip_ansi(util.redact(content or ""))
  local lines = util.split_lines(content)
  local name = output_name(title)

  vim.cmd(config.get().output.split)
  local buf = find_buffer(name) or vim.api.nvim_create_buf(false, true)
  if vim.api.nvim_buf_get_name(buf) == "" then
    vim.api.nvim_buf_set_name(buf, name)
  end
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "leetcode-output"
  vim.api.nvim_win_set_buf(0, buf)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  if opts.return_to and vim.api.nvim_win_is_valid(opts.return_to) then
    vim.api.nvim_set_current_win(opts.return_to)
  end
end

M._output_name = output_name
M._find_buffer = find_buffer

return M
