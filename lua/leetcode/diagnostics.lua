local cli = require("leetcode.cli")
local config = require("leetcode.config")
local session = require("leetcode.session")
local util = require("leetcode.util")

local M = {}

local function row(status, name, detail, fix)
  return { status = status, name = name, detail = detail, fix = fix }
end

local function marker(status)
  if status == "ok" then return "OK" end
  if status == "warn" then return "WARN" end
  return "FAIL"
end

function M.collect()
  local opts = config.get()
  local rows = {}

  if vim.fn.isdirectory(opts.workspace) == 1 then
    table.insert(rows, row("ok", "workspace", opts.workspace))
  else
    table.insert(rows, row("fail", "workspace", opts.workspace, "Create the directory or set require('leetcode').setup({ workspace = ... })"))
  end

  if util.is_supported_lang(opts.lang) then
    table.insert(rows, row("ok", "language", opts.lang))
  else
    table.insert(rows, row("fail", "language", tostring(opts.lang), "Run :LeetCodeLang or set lang to a supported LeetCode language"))
  end

  local active_cli = cli.resolve()
  local local_cli = cli.local_path()
  local fallback_cli = vim.fn.exepath("leetcode")

  if cli.exists(local_cli) then
    table.insert(rows, row("ok", "local CLI", local_cli))
  else
    table.insert(rows, row("warn", "local CLI", local_cli, "Run npm install in the plugin directory if you do not use a global CLI"))
  end

  if fallback_cli ~= "" then
    table.insert(rows, row("ok", "fallback CLI", fallback_cli))
  else
    table.insert(rows, row("warn", "fallback CLI", "leetcode not found on PATH", "Install vsc-leetcode-cli globally or run npm install locally"))
  end

  if cli.exists(active_cli) then
    table.insert(rows, row("ok", "active CLI", active_cli))
  else
    table.insert(rows, row("fail", "active CLI", active_cli, "Run npm install in the plugin directory, install leetcode on PATH, or configure cli.path"))
  end

  if opts.cli.path and opts.cli.path ~= "" and not cli.exists(vim.fn.expand(opts.cli.path)) then
    table.insert(rows, row("fail", "cli.path", opts.cli.path, "Point cli.path at an executable leetcode CLI"))
  elseif opts.cli.path and opts.cli.path ~= "" then
    table.insert(rows, row("ok", "cli.path", opts.cli.path))
  end

  if vim.fn.exepath(opts.cli.node) ~= "" then
    table.insert(rows, row("ok", "node", vim.fn.exepath(opts.cli.node)))
  elseif active_cli == local_cli then
    table.insert(rows, row("fail", "node", opts.cli.node, "Install Node.js or set cli.node"))
  else
    table.insert(rows, row("warn", "node", opts.cli.node, "Only needed when using the local node_modules CLI"))
  end

  local rendered = util.template_filename(opts.file.filename, { id = 1, name = "Two Sum", slug = "two-sum", ext = ".go", lang = "golang" })
  if rendered:match("1") and rendered:match("%.go$") then
    table.insert(rows, row("ok", "filename template", opts.file.filename))
  else
    table.insert(rows, row("warn", "filename template", opts.file.filename, "Expected template to include id/name and extension placeholders"))
  end

  local user, err, path = session.read_user()
  if err == nil then
    table.insert(rows, row("ok", "session file", path))
    if session.has_cookie_fields(user) then
      table.insert(rows, row("ok", "cookie fields", "sessionId and sessionCSRF present"))
    else
      table.insert(rows, row("fail", "cookie fields", "missing sessionId or sessionCSRF", "Run :LeetCodeLogin"))
    end
  elseif err == "missing" then
    table.insert(rows, row("fail", "session file", path, "Run :LeetCodeLogin"))
  else
    table.insert(rows, row("fail", "session file", path, "Delete the file and run :LeetCodeLogin"))
  end

  return rows
end

function M.format(rows)
  local lines = { "leetcode.nvim health", "" }
  for _, item in ipairs(rows) do
    table.insert(lines, string.format("[%s] %s: %s", marker(item.status), item.name, item.detail or ""))
    if item.fix then
      table.insert(lines, "  fix: " .. item.fix)
    end
  end
  return table.concat(lines, "\n")
end

function M.login_status(callback)
  local rows = {}
  local user, err, path = session.read_user()
  if err then
    callback(M.format({ row("fail", "session file", path, "Run :LeetCodeLogin") }))
    return
  end

  table.insert(rows, row("ok", "session file", path))
  if session.has_cookie_fields(user) then
    table.insert(rows, row("ok", "cookie fields", "sessionId and sessionCSRF present"))
  else
    table.insert(rows, row("fail", "cookie fields", "missing sessionId or sessionCSRF", "Run :LeetCodeLogin"))
  end

  session.live_check(function(result)
    table.insert(rows, row(result.ok == true and "ok" or (result.ok == nil and "warn" or "fail"), "live check", result.message, result.ok == false and "Copy fresh cookies from leetcode.com and run :LeetCodeLogin" or nil))
    callback(M.format(rows))
  end)
end

return M
