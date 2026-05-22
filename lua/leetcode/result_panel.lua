local output = require("leetcode.output")
local results = require("leetcode.results")
local testcase = require("leetcode.testcase")
local util = require("leetcode.util")

local M = {}

local active = {}

local function close_existing()
  for _, handle in ipairs(active) do
    if vim.api.nvim_win_is_valid(handle.win) then
      vim.api.nvim_win_close(handle.win, true)
    end
    if vim.api.nvim_buf_is_valid(handle.buf) then
      vim.api.nvim_buf_delete(handle.buf, { force = true })
    end
  end
  active = {}
end

local function dims(lines)
  local max_line = 24
  for _, line in ipairs(lines) do
    max_line = math.max(max_line, #line)
  end

  local width = math.min(math.max(44, max_line + 4), math.max(40, vim.o.columns - 8))
  local height = math.min(math.max(8, #lines), math.max(8, vim.o.lines - 8))
  return width, height
end

local function icon(parsed)
  if parsed.verdict == "Accepted" or parsed.verdict == "Finished" then
    return "PASS"
  end
  if parsed.verdict == "Wrong Answer" then
    return "WRONG"
  end
  if parsed.verdict == "Compile Error" then
    return "COMPILE"
  end
  if parsed.verdict == "Runtime Error" then
    return "RUNTIME"
  end
  return parsed.ok and "DONE" or "FAILED"
end

local function section(lines, title, value)
  if not value or value == "" then
    return
  end
  table.insert(lines, "")
  table.insert(lines, title)
  table.insert(lines, string.rep("-", #title))
  for _, line in ipairs(util.split_lines(value)) do
    if line ~= "" then
      table.insert(lines, line)
    end
  end
end

local function summary_lines(parsed, opts)
  opts = opts or {}
  local title = parsed.kind == "submit" and "LeetCode Submit" or "LeetCode Test"
  local status = parsed.verdict or (parsed.ok and "Finished" or "Failed")
  local lines = {
    string.format("%s  %s", icon(parsed), title),
    "",
    "Status: " .. status,
  }

  if parsed.cases then table.insert(lines, "Cases: " .. parsed.cases) end
  if parsed.runtime then table.insert(lines, "Runtime: " .. parsed.runtime) end
  if parsed.memory then table.insert(lines, "Memory: " .. parsed.memory) end

  section(lines, "Input", parsed.input)
  section(lines, "Your Output", parsed.output)
  section(lines, "Expected", parsed.expected)
  section(lines, "Stdout", parsed.stdout)
  section(lines, "Error", parsed.error)

  table.insert(lines, "")
  local keys = { "q close", "R raw" }
  if opts.on_rerun then table.insert(keys, "r rerun") end
  if opts.on_edit_testcase then table.insert(keys, "e edit testcase") end
  if parsed.input then table.insert(keys, "y yank testcase") end
  if opts.on_submit then table.insert(keys, "s submit") end
  table.insert(lines, "Keys: " .. table.concat(keys, " | "))
  return lines
end

local function open_float(title, lines)
  local width, height = dims(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "leetcode-result"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = 2,
    col = vim.o.columns - width - 4,
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "left",
  })
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"

  table.insert(active, { buf = buf, win = win })
  return buf, win
end

function M.show(kind, raw, code, opts)
  opts = opts or {}
  raw = util.strip_ansi(util.redact(raw or ""))
  local parsed = results.parse(kind, raw, code)
  if parsed.input then
    testcase.set_last(parsed.input)
  end
  local lines = summary_lines(parsed, opts)
  local title = kind == "submit" and "submit" or "test"

  close_existing()
  local ok, buf = pcall(open_float, title, lines)
  if not ok then
    output.show(title, results.format(kind, raw, code), opts)
    return
  end

  local map_opts = { buffer = buf, nowait = true, noremap = true, silent = true }
  vim.keymap.set("n", "q", function()
    close_existing()
    if opts.return_to and vim.api.nvim_win_is_valid(opts.return_to) then
      vim.api.nvim_set_current_win(opts.return_to)
    end
  end, map_opts)
  vim.keymap.set("n", "<Esc>", function()
    close_existing()
    if opts.return_to and vim.api.nvim_win_is_valid(opts.return_to) then
      vim.api.nvim_set_current_win(opts.return_to)
    end
  end, map_opts)
  vim.keymap.set("n", "R", function()
    output.show(title, results.format(kind, raw, code), opts)
  end, map_opts)
  if opts.on_rerun then
    vim.keymap.set("n", "r", function()
      close_existing()
      opts.on_rerun(parsed.input)
    end, map_opts)
  end
  if opts.on_edit_testcase then
    vim.keymap.set("n", "e", function()
      close_existing()
      opts.on_edit_testcase(parsed.input)
    end, map_opts)
  end
  if parsed.input then
    vim.keymap.set("n", "y", function()
      vim.fn.setreg('"', parsed.input)
      pcall(vim.fn.setreg, "+", parsed.input)
      util.notify("Yanked testcase")
    end, map_opts)
  end
  if opts.on_submit then
    vim.keymap.set("n", "s", function()
      close_existing()
      opts.on_submit()
    end, map_opts)
  end
end

M._summary_lines = summary_lines
M._close_existing = close_existing

return M
