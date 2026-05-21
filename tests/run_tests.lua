local ok, err = pcall(function()
  require("leetcode_test").run()
end)

if not ok then
  print(debug.traceback(err))
  vim.cmd("cquit")
end

