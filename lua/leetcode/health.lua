local cli = require("leetcode.cli")
local config = require("leetcode.config")

local M = {}

function M.check()
  local opts = config.get()
  local lines = {
    "leetcode.nvim health",
    "",
    "Neovim: " .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
    "Workspace: " .. opts.workspace,
    "Language: " .. opts.lang,
    "Node: " .. (vim.fn.exepath(opts.cli.node) ~= "" and vim.fn.exepath(opts.cli.node) or "not found"),
    "CLI: " .. cli.resolve(),
  }
  local readable = vim.fn.filereadable(cli.resolve()) == 1 or vim.fn.executable(cli.resolve()) == 1
  table.insert(lines, "CLI readable/executable: " .. tostring(readable))
  require("leetcode.output").show("health", table.concat(lines, "\n"))
end

return M

