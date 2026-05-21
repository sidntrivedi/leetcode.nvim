local util = require("leetcode.util")

local M = {}

function M.user_file(home)
  home = home or vim.fn.expand("~")
  return util.path_join(home, ".lc", "leetcode", "user.json")
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

