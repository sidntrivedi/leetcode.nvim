local config = require("leetcode.config")
local util = require("leetcode.util")

local M = {}

local function local_cli_path()
  local root = debug.getinfo(1, "S").source:sub(2)
  root = vim.fn.fnamemodify(root, ":p:h:h:h")
  return util.path_join(root, "node_modules", "vsc-leetcode-cli", "bin", "leetcode")
end

function M.resolve()
  local opts = config.get()
  if opts.cli.path and opts.cli.path ~= "" then
    return vim.fn.expand(opts.cli.path)
  end

  local local_path = local_cli_path()
  if vim.fn.filereadable(local_path) == 1 then
    return local_path
  end

  local executable = vim.fn.exepath("leetcode")
  if executable ~= "" then
    return executable
  end

  return local_path
end

function M.command(args)
  local opts = config.get()
  local cli_path = M.resolve()
  local cmd = {}
  if cli_path:match("%.js$") or (vim.fn.filereadable(cli_path) == 1 and vim.fn.executable(cli_path) == 0) then
    table.insert(cmd, opts.cli.node)
    table.insert(cmd, cli_path)
  else
    table.insert(cmd, cli_path)
  end
  vim.list_extend(cmd, args)
  return cmd
end

function M.run(args, opts, callback)
  opts = opts or {}
  local cmd = M.command(args)
  local run_opts = {
    text = true,
    cwd = opts.cwd or config.get().workspace,
    stdin = opts.stdin,
  }

  vim.system(cmd, run_opts, function(result)
    result.stdout = util.redact(result.stdout or "")
    result.stderr = util.redact(result.stderr or "")
    vim.schedule(function()
      callback(result, cmd)
    end)
  end)
end

function M.run_sync(args, opts)
  opts = opts or {}
  local cmd = M.command(args)
  local result = vim.system(cmd, {
    text = true,
    cwd = opts.cwd or config.get().workspace,
    stdin = opts.stdin,
  }):wait()
  result.stdout = util.redact(result.stdout or "")
  result.stderr = util.redact(result.stderr or "")
  return result, cmd
end

return M
