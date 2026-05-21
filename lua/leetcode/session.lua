local util = require("leetcode.util")

local M = {}

function M.user_file(home)
  home = home or vim.fn.expand("~")
  return util.path_join(home, ".lc", "leetcode", "user.json")
end

function M.read_user(home)
  local path = M.user_file(home)
  if vim.fn.filereadable(path) ~= 1 then
    return nil, "missing", path
  end

  local ok, data = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  end)
  if not ok or type(data) ~= "table" then
    return nil, "invalid_json", path
  end

  return data, nil, path
end

function M.has_cookie_fields(user)
  return type(user) == "table"
    and type(user.sessionId) == "string"
    and user.sessionId ~= ""
    and type(user.sessionCSRF) == "string"
    and user.sessionCSRF ~= ""
end

function M.cookie_header(user)
  if not M.has_cookie_fields(user) then
    return nil
  end
  return util.cookie_from_values(user.sessionId, user.sessionCSRF)
end

function M.live_check(callback)
  local user, err, path = M.read_user()
  if err then
    callback({ ok = false, status = err, path = path, message = "Session file is not usable" })
    return
  end

  if not M.has_cookie_fields(user) then
    callback({ ok = false, status = "missing_fields", path = path, message = "Session file is missing sessionId or sessionCSRF" })
    return
  end

  if vim.fn.executable("curl") ~= 1 then
    callback({ ok = nil, status = "skipped", path = path, message = "curl is not available for live validation" })
    return
  end

  vim.system({
    "curl",
    "-sS",
    "--max-time",
    "10",
    "-o",
    "-",
    "-w",
    "\n%{http_code}",
    "https://leetcode.com/api/problems/algorithms/",
    "-H",
    "Cookie: " .. M.cookie_header(user),
    "-H",
    "X-CSRFToken: " .. user.sessionCSRF,
  }, { text = true }, function(result)
    local stdout = result.stdout or ""
    local body, status = stdout:match("^(.*)\n(%d%d%d)$")
    status = tonumber(status)
    local ok = result.code == 0 and status == 200 and body and body:match('"user_name"%s*:%s*"[^"]+"') ~= nil
    vim.schedule(function()
      callback({
        ok = ok,
        status = status or result.code,
        path = path,
        message = ok and "LeetCode accepted the saved session" or "LeetCode did not accept the saved session",
      })
    end)
  end)
end

function M.user_from_cookie(login, cookie)
  return {
    login = util.trim(login),
    name = util.trim(login),
    paid = false,
    sessionId = util.cookie_value(cookie, "LEETCODE_SESSION"),
    sessionCSRF = util.cookie_value(cookie, "csrftoken"),
  }
end

function M.save_cookie_user(login, cookie, home)
  if not util.cookie_has_required_fields(cookie) then
    return nil, "Cookie login needs LEETCODE_SESSION and csrftoken values"
  end

  local user = M.user_from_cookie(login, cookie)
  local path = M.user_file(home)
  util.ensure_dir(util.parent_dir(path))
  vim.fn.writefile({ vim.json.encode(user) }, path)
  return path, nil
end

return M
