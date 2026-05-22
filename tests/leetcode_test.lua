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
  local results = require("leetcode.results")
  local result_panel = require("leetcode.result_panel")
  local testcase = require("leetcode.testcase")
  local topics = require("leetcode.topics")
  local languages = require("leetcode.languages")
  local diagnostics = require("leetcode.diagnostics")

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
  assert_eq(parsed[1].state, "ac", "first solved state")
  assert_eq(parsed[1].locked, false, "first unlocked")
  assert_eq(parsed[2].slug, "3sum", "numeric slug")
  assert_eq(parsed[2].locked, true, "locked marker")
  assert_eq(parsed[3].state, "None", "unknown solved state")

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
  local meta = parser.meta_from_file("1.two-sum.go", content)
  assert_eq(meta.id, "1", "metadata id")
  assert_eq(meta.lang, "golang", "metadata lang")
  assert_eq(meta.source, "metadata", "metadata source")
  assert_eq(meta.valid, true, "metadata valid")
  local fallback_meta = parser.meta_from_file("42.trapping-rain-water.py", "")
  assert_eq(fallback_meta.id, "42", "fallback id")
  assert_eq(fallback_meta.lang, "python", "fallback lang")
  assert_eq(fallback_meta.source, "filename", "fallback source")
  assert_eq(fallback_meta.valid, true, "fallback valid")
  local invalid_meta = parser.meta_from_file("README.md", "")
  assert_eq(invalid_meta.valid, false, "invalid metadata")
  local unreadable_meta = parser.meta_from_file(vim.fn.tempname() .. "/NvimTree_1")
  assert_eq(unreadable_meta.valid, false, "unreadable metadata")
  assert_eq(unreadable_meta.source, "unreadable", "unreadable metadata source")

  local workspace = tmpdir()
  config.setup({ workspace = workspace })
  assert_eq(languages.set("python3"), true, "language set")
  assert_eq(config.get().lang, "python3", "config lang updated")
  local ok_lang, lang_err = languages.set("brainfuck")
  assert_eq(ok_lang, false, "unsupported language rejected")
  assert_true(lang_err:match("Unsupported LeetCode language"), "unsupported language message")
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

  local parsed_result = results.parse("test", "Wrong Answer\nYour Input: [1]\nOutput: 1\nExpected Answer: 2\n", 1)
  assert_eq(parsed_result.verdict, "Wrong Answer", "result verdict")
  assert_eq(parsed_result.input, "[1]", "result input")
  assert_eq(parsed_result.output, "1", "result output")
  assert_eq(parsed_result.expected, "2", "result expected")
  local formatted_result = results.format("submit", "Accepted\nRuntime: 1 ms\nMemory: 2 MB\n", 0)
  assert_true(formatted_result:match("Submit result"), "formatted title")
  assert_true(formatted_result:match("Status: Accepted"), "formatted status")
  assert_true(formatted_result:match("Runtime: 1 ms"), "formatted runtime")
  local panel_lines = result_panel._summary_lines(parsed_result)
  assert_eq(panel_lines[1], "WRONG  LeetCode Test", "panel title")
  assert_true(table.concat(panel_lines, "\n"):match("Your Output"), "panel output section")
  assert_true(table.concat(panel_lines, "\n"):match("Expected"), "panel expected section")
  testcase.set_last("[1]\n2")
  assert_eq(testcase.last(), "[1]\n2", "last testcase")
  assert_eq(topics.normalize("Dynamic Programming"), "dynamic-programming", "topic normalization")
  assert_eq(topics.label("two-pointers"), "Two Pointers", "topic label")
  assert_true(#topics.list() > 10, "topic catalog")
  local topic, difficulty, query = topics.parse_args("dynamic programming hard")
  assert_eq(topic, "dynamic-programming", "topic parse")
  assert_eq(difficulty, "hard", "difficulty parse")
  assert_eq(query, "h", "difficulty query")
  topic, difficulty, query = topics.parse_args("easy linked list")
  assert_eq(topic, "linked-list", "leading difficulty topic parse")
  assert_eq(difficulty, "easy", "leading difficulty parse")
  assert_eq(query, "e", "leading difficulty query")
  assert_true(#topics.picker_items() > #topics.list(), "topic difficulty picker catalog")

  local health = diagnostics.format(diagnostics.collect())
  assert_true(health:match("leetcode.nvim health"), "health title")
  assert_true(health:match("workspace"), "health workspace row")
  assert_true(health:match("cookie fields"), "health cookie row")

  local leetcode = require("leetcode")
  assert_eq(leetcode._command_failed({ code = 0, stdout = "[ERROR] Problem not found!\n", stderr = "" }), true, "cli error stdout")
  assert_eq(leetcode._command_failed({ code = 0, stdout = "ok\n", stderr = "" }), false, "cli success")

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
