local cli = require("leetcode.cli")
local config = require("leetcode.config")
local files = require("leetcode.files")
local output = require("leetcode.output")
local parser = require("leetcode.parser")
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

        local session = vim.fn.inputsecret("LEETCODE_SESSION value: ")
        if session == "" then
          util.notify("Login cancelled", vim.log.levels.WARN)
          return
        end

        local csrf = vim.fn.inputsecret("csrftoken value: ")
        if csrf == "" then
          util.notify("Login cancelled", vim.log.levels.WARN)
          return
        end

        local cookie = util.cookie_from_values(session, csrf)
        cli.run(choice.args, { stdin = util.cookie_login_stdin(login, cookie) }, function(result)
          show_result("login", result)
        end)
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

    vim.ui.select(problems, {
      prompt = "LeetCode problems",
      format_item = function(item)
        return string.format("[%s] %s %s", item.fid or item.id, item.name, item.level or "")
      end,
    }, function(choice)
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
  save_current_file()

  local args = { "test", path }
  if testcase and testcase ~= "" then
    vim.list_extend(args, { "-t", testcase })
  end
  local win = vim.api.nvim_get_current_win()
  cli.run(args, {}, function(result)
    show_result("test", result, { return_to = command_failed(result) and nil or win })
  end)
end

function M.submit()
  local path = current_file()
  if not path then
    return
  end
  save_current_file()

  local win = vim.api.nvim_get_current_win()
  cli.run({ "submit", path }, {}, function(result)
    show_result("submit", result, { return_to = command_failed(result) and nil or win })
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
  vim.api.nvim_create_user_command("LeetCodeLogout", M.logout, {})
  vim.api.nvim_create_user_command("LeetCodeUser", M.user, {})
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
