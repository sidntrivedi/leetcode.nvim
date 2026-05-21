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
  local output = require("leetcode.output")
  local session = require("leetcode.session")

  assert_eq(util.template_filename("${id}.${kebab-case-name}.${ext}", {
    id = 1,
    name = "Two Sum",
    ext = ".go",
  }), "1.two-sum.go", "filename template")
  assert_true(util.cookie_has_required_fields("LEETCODE_SESSION=session; csrftoken=csrf;"), "cookie validation")
  assert_eq(util.cookie_value("LEETCODE_SESSION=session; csrftoken=csrf;", "LEETCODE_SESSION"), "session", "cookie value")
  assert_eq(util.cookie_from_values(" session ", " csrf "), "LEETCODE_SESSION=session; csrftoken=csrf;", "cookie builder")
  assert_eq(
    util.cookie_from_login_input("LEETCODE_SESSION=session; csrftoken=csrf;"),
    "LEETCODE_SESSION=session; csrftoken=csrf;",
    "full cookie input"
  )
  assert_eq(
    util.cookie_from_login_input("LEETCODE_SESSION=session;", "csrf"),
    "LEETCODE_SESSION=session; csrftoken=csrf;",
    "partial cookie input"
  )
  assert_eq(
    util.cookie_login_stdin(" user@example.com ", util.cookie_from_values("session", "csrf")),
    "user@example.com\nLEETCODE_SESSION=session; csrftoken=csrf;\n",
    "cookie login stdin"
  )

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
  local user_path = session.save_cookie_user(" user@example.com ", util.cookie_from_values("session", "csrf"), workspace)
  assert_eq(user_path, workspace .. "/.lc/leetcode/user.json", "session file path")
  local user = vim.json.decode(table.concat(vim.fn.readfile(user_path), "\n"))
  assert_eq(user.login, "user@example.com", "session login")
  assert_eq(user.sessionId, "session", "session id")
  assert_eq(user.sessionCSRF, "csrf", "session csrf")

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

  output.show("login", "first")
  local first_buf = output._find_buffer("leetcode://login")
  assert_true(first_buf ~= nil, "output buffer created")
  output.show("login", "second")
  local second_buf = output._find_buffer("leetcode://login")
  assert_eq(second_buf, first_buf, "output buffer reused")
  assert_eq(table.concat(vim.api.nvim_buf_get_lines(second_buf, 0, -1, false), "\n"), "second", "output buffer updated")

  print("leetcode.nvim tests passed")
  vim.cmd("qa!")
end

return M
