local util = require("leetcode.util")

local M = {}

local last = ""
local active = nil

local function close_active()
  if active then
    if vim.api.nvim_win_is_valid(active.win) then
      vim.api.nvim_win_close(active.win, true)
    end
    if vim.api.nvim_buf_is_valid(active.buf) then
      vim.api.nvim_buf_delete(active.buf, { force = true })
    end
  end
  active = nil
end

local function dims(lines)
  local max_line = 40
  for _, line in ipairs(lines) do
    max_line = math.max(max_line, #line)
  end

  local width = math.min(math.max(56, max_line + 4), math.max(40, vim.o.columns - 8))
  local height = math.min(math.max(8, #lines + 2), math.max(8, vim.o.lines - 8))
  return width, height
end

function M.set_last(value)
  if value and util.trim(value) ~= "" then
    last = value
  end
end

function M.last()
  return last
end

function M.open(opts)
  opts = opts or {}
  local initial = opts.initial
  if initial == nil or initial == "" then
    initial = last
  end
  local lines = util.split_lines(initial or "")
  if #lines == 0 then
    lines = { "" }
  end

  close_active()
  local width, height = dims(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "leetcode-testcase"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " LeetCode testcase: r run, q close ",
    title_pos = "left",
  })
  vim.wo[win].wrap = false
  vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"
  active = { buf = buf, win = win }

  local function content()
    return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  end

  local function run()
    local value = content()
    M.set_last(value)
    close_active()
    if opts.on_run then
      opts.on_run(value)
    end
  end

  local map_opts = { buffer = buf, nowait = true, noremap = true, silent = true }
  vim.keymap.set("n", "q", close_active, map_opts)
  vim.keymap.set("n", "<Esc>", close_active, map_opts)
  vim.keymap.set("n", "r", run, map_opts)
  vim.keymap.set("n", "<CR>", run, map_opts)

  vim.api.nvim_win_set_cursor(win, { 1, 0 })
  vim.cmd("startinsert")
end

M._close_active = close_active

return M
