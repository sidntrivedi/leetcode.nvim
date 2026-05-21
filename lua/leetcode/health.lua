local M = {}

function M.check()
  local diagnostics = require("leetcode.diagnostics")
  require("leetcode.output").show("health", diagnostics.format(diagnostics.collect()))
end

return M
