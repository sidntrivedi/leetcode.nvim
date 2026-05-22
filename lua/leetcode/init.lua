local cli = require("leetcode.cli")
local config = require("leetcode.config")
local diagnostics = require("leetcode.diagnostics")
local files = require("leetcode.files")
local input = require("leetcode.input")
local languages = require("leetcode.languages")
local output = require("leetcode.output")
local parser = require("leetcode.parser")
local picker = require("leetcode.picker")
local result_panel = require("leetcode.result_panel")
local results = require("leetcode.results")
local session = require("leetcode.session")
local testcase = require("leetcode.testcase")
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
  result_panel.show(title, raw, result.code, opts)
end

local function buffer_file(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end

  if vim.bo[buf].buftype ~= "" then
    return nil
  end

  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" or vim.fn.filereadable(path) ~= 1 then
    return nil
  end

  return path
end

local function save_file(buf)
  if vim.bo[buf].modified then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd.write()
    end)
  end
end

local function problem_meta(path)
  local ok, meta = pcall(parser.meta_from_file, path)
  if not ok then
    return nil, tostring(meta)
  end
  if not meta or not meta.valid then
    return nil, meta and meta.warning or "Unable to read problem metadata."
  end
  return meta, nil
end

local function show_metadata_error(detail)
  show_result("metadata", {
    code = 1,
    stdout = "",
    stderr = table.concat({
      "Current file is not a LeetCode solution file.",
      detail or "Unable to read problem metadata.",
      "",
      "Focus a LeetCode solution file, keep one visible in another window, or open one with :LeetCodeOpen / :LeetCodeSearch.",
      "Expected header:",
      "@lc app=leetcode id=1 lang=golang",
    }, "\n"),
  })
end

local function add_candidate(candidates, seen, buf, win)
  local path = buffer_file(buf)
  if not path or seen[path] then
    return
  end
  seen[path] = true
  table.insert(candidates, { buf = buf, win = win, path = path })
end

local function current_problem_file()
  local candidates = {}
  local seen = {}
  add_candidate(candidates, seen, vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win())

  local alternate = vim.fn.bufnr("#")
  if alternate and alternate > 0 then
    add_candidate(candidates, seen, alternate, nil)
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    add_candidate(candidates, seen, vim.api.nvim_win_get_buf(win), win)
  end

  local last_error
  for _, candidate in ipairs(candidates) do
    local meta, err = problem_meta(candidate.path)
    if meta then
      candidate.meta = meta
      return candidate
    end
    last_error = err
  end

  local current_name = vim.api.nvim_buf_get_name(0)
  if current_name == "" then
    current_name = vim.bo.filetype ~= "" and vim.bo.filetype or "[No Name]"
  end
  show_metadata_error(last_error or ("Focused buffer is not a readable solution file: " .. current_name))
  return nil
end

local function warn_filename_fallback(meta)
  if meta and meta.source == "filename" and meta.warning then
    util.notify(meta.warning, vim.log.levels.WARN)
  end
end

function M.login()
  local choices = {
    { label = "Cookie", args = { "user", "-c" }, stdin = true },
    { label = "GitHub", args = { "user", "-g" } },
    { label = "LinkedIn", args = { "user", "-i" } },
  }

  picker.select_items(choices, {
    prompt = "LeetCode login method",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end

    if choice.stdin then
      input.prompt({ prompt = "LeetCode username or email" }, function(login)
        if not login or util.trim(login) == "" then
          util.notify("Login cancelled", vim.log.levels.WARN)
          return
        end

        input.prompt({ prompt = "Paste full cookie or LEETCODE_SESSION value", secret = true, width = 80 }, function(session_or_cookie)
          if not session_or_cookie or session_or_cookie == "" then
            util.notify("Login cancelled", vim.log.levels.WARN)
            return
          end

          local function save(csrf)
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
          end

          if util.cookie_has_required_fields(session_or_cookie) then
            save("")
            return
          end

          input.prompt({ prompt = "csrftoken value", secret = true, width = 80 }, function(csrf)
            if not csrf or csrf == "" then
              util.notify("Login cancelled", vim.log.levels.WARN)
              return
            end
            save(csrf)
          end)
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
    input.prompt({ prompt = "LeetCode problem id, slug, or title" }, function(value)
      if value and util.trim(value) ~= "" then
        M.open_problem(value, known)
      end
    end)
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
    input.prompt({ prompt = "LeetCode search" }, function(value)
      if value and util.trim(value) ~= "" then
        M.search(value)
      end
    end)
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
  local target = current_problem_file()
  if not target then
    return
  end
  warn_filename_fallback(target.meta)
  save_file(target.buf)

  local args = { "test", target.path }
  if testcase and testcase ~= "" then
    vim.list_extend(args, { "-t", testcase })
  end
  local win = target.win or vim.api.nvim_get_current_win()
  cli.run(args, {}, function(result)
    show_parsed_result("test", result, {
      return_to = command_failed(result) and nil or win,
      on_rerun = function(failed_testcase)
        M.test(failed_testcase or testcase)
      end,
      on_edit_testcase = function(failed_testcase)
        M.testcase(failed_testcase or testcase)
      end,
      on_submit = M.submit,
    })
  end)
end

function M.testcase(initial)
  testcase.open({
    initial = initial,
    on_run = function(value)
      M.test(value)
    end,
  })
end

function M.submit()
  local target = current_problem_file()
  if not target then
    return
  end
  warn_filename_fallback(target.meta)
  save_file(target.buf)

  local win = target.win or vim.api.nvim_get_current_win()
  cli.run({ "submit", target.path }, {}, function(result)
    show_parsed_result("submit", result, {
      return_to = command_failed(result) and nil or win,
      on_rerun = function(failed_testcase)
        M.test(failed_testcase)
      end,
      on_edit_testcase = function(failed_testcase)
        M.testcase(failed_testcase)
      end,
    })
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
  end, { nargs = "*" })
  vim.api.nvim_create_user_command("LeetCodeTest", function(opts)
    M.test(opts.args)
  end, { nargs = "*" })
  vim.api.nvim_create_user_command("LeetCodeTestCase", function(opts)
    M.testcase(opts.args)
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
