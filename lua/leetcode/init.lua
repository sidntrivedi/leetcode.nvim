local cli = require("leetcode.cli")
local config = require("leetcode.config")
local diagnostics = require("leetcode.diagnostics")
local files = require("leetcode.files")
local languages = require("leetcode.languages")
local output = require("leetcode.output")
local parser = require("leetcode.parser")
local picker = require("leetcode.picker")
local results = require("leetcode.results")
local session = require("leetcode.session")
local util = require("leetcode.util")

local M = {}
local commands_registered = false

local function command_failed(result)
  return result.code ~= 0
end

local function show_result(title, result, opts)
  local body = table.concat(vim.tbl_filter(function(part)
    return part and part ~= ""
  end, { result.stdout, result.stderr }), "\n")
  if body == "" then
    body = "Command finished with exit code " .. tostring(result.code)
  end
  output.show(title, body, opts)
end

local function show_parsed_result(title, result, opts)
  local raw = table.concat(vim.tbl_filter(function(part)
    return part and part ~= ""
  end, { result.stdout, result.stderr }), "\n")
  if raw == "" then
    raw = "Command finished with exit code " .. tostring(result.code)
  end
  output.show(title, results.format(title, raw, result.code), opts)
end

local function current_file()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    util.notify("Current buffer has no file name", vim.log.levels.ERROR)
    return nil
  end
  return path
end

local function save_current_file()
  if vim.bo.modified then
    vim.cmd.write()
  end
end

local function current_problem_meta(path)
  local ok, meta = pcall(parser.meta_from_file, path)
  if not ok or not meta or not meta.valid then
    local detail = ok and meta and meta.warning or tostring(meta)
    show_result("metadata", {
      code = 1,
      stdout = "",
      stderr = table.concat({
        "Current file is not a LeetCode solution file.",
        detail or "Unable to read problem metadata.",
        "",
        "Open a problem with :LeetCodeOpen or :LeetCodeSearch, or add a header like:",
        "@lc app=leetcode id=1 lang=golang",
      }, "\n"),
    })
    return nil
  end

  if meta.source == "filename" and meta.warning then
    util.notify(meta.warning, vim.log.levels.WARN)
  end
  return meta
end

function M.login()
  local choices = {
    { label = "Cookie", args = { "user", "-c" }, stdin = true },
    { label = "GitHub", args = { "user", "-g" } },
    { label = "LinkedIn", args = { "user", "-i" } },
  }

  vim.ui.select(choices, {
    prompt = "LeetCode login method",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end

    if choice.stdin then
      vim.ui.input({ prompt = "LeetCode username or email: " }, function(login)
        if not login or util.trim(login) == "" then
          util.notify("Login cancelled", vim.log.levels.WARN)
          return
        end

        local session_or_cookie = vim.fn.inputsecret("Paste full cookie or LEETCODE_SESSION value: ")
        if session_or_cookie == "" then
          util.notify("Login cancelled", vim.log.levels.WARN)
          return
        end

        local csrf = ""
        if not util.cookie_has_required_fields(session_or_cookie) then
          csrf = vim.fn.inputsecret("csrftoken value: ")
          if csrf == "" then
            util.notify("Login cancelled", vim.log.levels.WARN)
            return
          end
        end

        local cookie = util.cookie_from_login_input(session_or_cookie, csrf)
        if not util.cookie_has_required_fields(cookie) then
          util.notify("Cookie login needs LEETCODE_SESSION and csrftoken values", vim.log.levels.ERROR)
          return
        end

        local path, err = session.save_cookie_user(login, cookie)
        if err then
          util.notify(err, vim.log.levels.ERROR)
          return
        end

        show_result("login", {
          code = 0,
          stdout = "Saved LeetCode cookie session to " .. path .. "\nRun :LeetCodeSearch or :LeetCodeOpen to verify it against leetcode.com.",
          stderr = "",
        })
      end)
      return
    end

    cli.run(choice.args, {}, function(result)
      show_result("login", result)
    end)
  end)
end

function M.logout()
  cli.run({ "user", "-L" }, {}, function(result)
    show_result("logout", result)
  end)
end

function M.user()
  cli.run({ "user" }, {}, function(result)
    show_result("user", result)
  end)
end

function M.login_status()
  diagnostics.login_status(function(text)
    output.show("login-status", text)
  end)
end

function M.lang(lang)
  if lang and lang ~= "" then
    local ok, err = languages.set(lang)
    if not ok then
      util.notify(err, vim.log.levels.ERROR)
    end
    return
  end

  languages.select()
end

function M.open_problem(keyword, known)
  if not keyword or keyword == "" then
    util.notify("Missing LeetCode problem id, slug, or title", vim.log.levels.ERROR)
    return
  end

  local args = { "show", keyword, "-c", "-x", "-l", config.get().lang }
  cli.run(args, {}, function(result)
    if command_failed(result) then
      show_result("open", result)
      return
    end

    local content = util.strip_ansi(result.stdout)
    local problem = parser.problem_from_content(content)
    if known then
      problem = vim.tbl_extend("force", known, problem)
    end
    if not problem.id or problem.id == "" then
      show_result("open", { stdout = content, stderr = "Unable to parse problem metadata from CLI output", code = 1 })
      return
    end

    local path, created = files.write_or_open(problem, content)
    util.notify((created and "Created " or "Opened ") .. path)
  end)
end

function M.search(query)
  query = query or ""
  if query == "" then
    query = vim.fn.input("LeetCode search: ")
  end
  if query == "" then
    return
  end

  cli.run({ "list", query }, {}, function(result)
    if command_failed(result) then
      show_result("search", result)
      return
    end

    local problems = parser.parse_list(result.stdout)
    if #problems == 0 then
      show_result("search", { stdout = result.stdout, stderr = "No parsable problems found", code = 1 })
      return
    end

    picker.select_problem(problems, function(choice)
      if not choice then
        return
      end
      M.open_problem(choice.id, choice)
    end)
  end)
end

function M.test(testcase)
  local path = current_file()
  if not path then
    return
  end
  if not current_problem_meta(path) then
    return
  end
  save_current_file()

  local args = { "test", path }
  if testcase and testcase ~= "" then
    vim.list_extend(args, { "-t", testcase })
  end
  local win = vim.api.nvim_get_current_win()
  cli.run(args, {}, function(result)
    show_parsed_result("test", result, { return_to = command_failed(result) and nil or win })
  end)
end

function M.submit()
  local path = current_file()
  if not path then
    return
  end
  if not current_problem_meta(path) then
    return
  end
  save_current_file()

  local win = vim.api.nvim_get_current_win()
  cli.run({ "submit", path }, {}, function(result)
    show_parsed_result("submit", result, { return_to = command_failed(result) and nil or win })
  end)
end

function M.health()
  require("leetcode.health").check()
end

local function register_commands()
  if commands_registered then
    return
  end
  commands_registered = true

  vim.api.nvim_create_user_command("LeetCodeLogin", M.login, {})
  vim.api.nvim_create_user_command("LeetCodeLoginStatus", M.login_status, {})
  vim.api.nvim_create_user_command("LeetCodeLogout", M.logout, {})
  vim.api.nvim_create_user_command("LeetCodeUser", M.user, {})
  vim.api.nvim_create_user_command("LeetCodeLang", function(opts)
    M.lang(opts.args)
  end, { nargs = "?" })
  vim.api.nvim_create_user_command("LeetCodeSearch", function(opts)
    M.search(opts.args)
  end, { nargs = "*" })
  vim.api.nvim_create_user_command("LeetCodeOpen", function(opts)
    M.open_problem(opts.args)
  end, { nargs = "+" })
  vim.api.nvim_create_user_command("LeetCodeTest", function(opts)
    M.test(opts.args)
  end, { nargs = "*" })
  vim.api.nvim_create_user_command("LeetCodeSubmit", M.submit, {})
  vim.api.nvim_create_user_command("LeetCodeHealth", M.health, {})
end

function M.setup(opts)
  config.setup(opts)
  register_commands()
  return M
end

return M
