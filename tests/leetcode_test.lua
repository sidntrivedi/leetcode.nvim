local function assert_eq(actual, expected, msg)
  if actual ~= expected then
    error((msg or "assertion failed") .. "\nexpected: " .. vim.inspect(expected) .. "\nactual: " .. vim.inspect(actual), 2)
  end
end

local function assert_true(value, msg)
  if not value then
    error(msg or "expected truthy value", 2)
  end
end

local function tmpdir()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  return dir
end

local function write(path, lines)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  vim.fn.writefile(lines, path)
end

local M = {}

function M.run()
  local root = vim.fn.getcwd()
  package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

  local util = require("leetcode.util")
  local parser = require("leetcode.parser")
  local config = require("leetcode.config")
  local files = require("leetcode.files")
  local cli = require("leetcode.cli")

  assert_eq(util.template_filename("${id}.${kebab-case-name}.${ext}", {
    id = 1,
    name = "Two Sum",
    ext = ".go",
  }), "1.two-sum.go", "filename template")

  local parsed = parser.parse_list([[
    ✔   [   1] Two Sum                                                      Easy   (57.43 %)
    🔒   [  15] 3Sum                                                         Medium (36.10 %)
        [  42] Trapping Rain Water                                          Hard   (64.00 %)
  ]])
  assert_eq(#parsed, 3, "list parser count")
  assert_eq(parsed[1].id, "1", "first id")
  assert_eq(parsed[1].slug, "two-sum", "first slug")
  assert_eq(parsed[2].slug, "3sum", "numeric slug")

  local content = [[/*
 * @lc app=leetcode id=1 lang=golang
 *
 * [1] Two Sum
 *
 * https://leetcode.com/problems/two-sum/description/
 */
func twoSum(nums []int, target int) []int {
}
]]
  local problem = parser.problem_from_content(content)
  assert_eq(problem.id, "1", "content id")
  assert_eq(problem.lang, "golang", "content lang")
  assert_eq(problem.name, "Two Sum", "content name")
  assert_eq(problem.slug, "two-sum", "content slug")

  local workspace = tmpdir()
  config.setup({ workspace = workspace })
  local path, created = files.write_or_open(problem, content)
  assert_true(created, "file should be created")
  assert_eq(vim.fn.fnamemodify(path, ":t"), "1.two-sum.go", "created file name")
  local saved = table.concat(vim.fn.readfile(path), "\n")
  assert_true(saved:match("^package main"), "go package inserted")
  assert_true(saved:match("@lc app=leetcode id=1 lang=golang"), "lc metadata preserved")

  local _, created_again = files.write_or_open(problem, "changed")
  assert_eq(created_again, false, "existing file should not be overwritten")
  local unchanged = table.concat(vim.fn.readfile(path), "\n")
  assert_true(unchanged:match("twoSum"), "existing content preserved")

  local mock_cli = workspace .. "/mock-leetcode"
  write(mock_cli, {
    "#!/bin/sh",
    "printf '%s\\n' \"$@\" > " .. workspace .. "/argv.txt",
    "printf 'ok\\n'",
  })
  vim.fn.setfperm(mock_cli, "rwxr-xr-x")
  config.setup({ workspace = workspace, cli = { path = mock_cli } })
  local result, cmd = cli.run_sync({ "test", path })
  assert_eq(result.code, 0, "mock cli exit")
  assert_eq(result.stdout, "ok\n", "mock cli stdout")
  assert_eq(cmd[1], mock_cli, "cli path")
  assert_eq(table.concat(vim.fn.readfile(workspace .. "/argv.txt"), " "), "test " .. path, "cli argv")

  print("leetcode.nvim tests passed")
  vim.cmd("qa!")
end

return M

