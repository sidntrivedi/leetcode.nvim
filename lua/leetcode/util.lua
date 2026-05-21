local M = {}

local ansi_pattern = "\27%[[0-9;]*[A-Za-z]"

local exts = {
  bash = ".sh",
  c = ".c",
  cpp = ".cpp",
  csharp = ".cs",
  golang = ".go",
  java = ".java",
  javascript = ".js",
  kotlin = ".kt",
  mysql = ".sql",
  php = ".php",
  python = ".py",
  python3 = ".py",
  ruby = ".rb",
  rust = ".rs",
  scala = ".scala",
  swift = ".swift",
}

function M.trim(s)
  return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function M.split_lines(s)
  s = s or ""
  s = s:gsub("\r\n", "\n")
  if s:sub(-1) ~= "\n" then
    s = s .. "\n"
  end
  local lines = {}
  for line in s:gmatch("(.-)\n") do
    table.insert(lines, line)
  end
  return lines
end

function M.strip_ansi(s)
  return (s or ""):gsub(ansi_pattern, "")
end

function M.redact(s)
  s = s or ""
  s = s:gsub("LEETCODE_SESSION=[^;%s]+", "LEETCODE_SESSION=<redacted>")
  s = s:gsub("csrftoken=[^;%s]+", "csrftoken=<redacted>")
  s = s:gsub("Cookie:%s*[^%n]+", "Cookie: <redacted>")
  return s
end

function M.cookie_has_required_fields(cookie)
  cookie = cookie or ""
  return cookie:match("LEETCODE_SESSION=([^;]+)") ~= nil and cookie:match("csrftoken=([^;]+)") ~= nil
end

function M.cookie_value(cookie, name)
  cookie = cookie or ""
  return cookie:match(name .. "=([^;]+)")
end

function M.cookie_from_values(session, csrf)
  return "LEETCODE_SESSION=" .. M.trim(session) .. "; csrftoken=" .. M.trim(csrf) .. ";"
end

function M.cookie_from_login_input(session_or_cookie, csrf)
  session_or_cookie = M.trim(session_or_cookie)
  if M.cookie_has_required_fields(session_or_cookie) then
    return session_or_cookie
  end

  local session = M.cookie_value(session_or_cookie, "LEETCODE_SESSION") or session_or_cookie
  return M.cookie_from_values(session, csrf or "")
end

function M.cookie_login_stdin(login, cookie)
  return M.trim(login) .. "\n" .. M.trim(cookie) .. "\n"
end

function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "leetcode.nvim" })
end

function M.lang_to_ext(lang)
  return exts[lang] or ".raw"
end

function M.ext_to_lang(path)
  for lang, ext in pairs(exts) do
    if path:sub(-#ext) == ext then
      return lang
    end
  end
  return "unknown"
end

function M.slugify(text)
  text = M.trim(text):lower()
  text = text:gsub("&", " and ")
  text = text:gsub("[^%w]+", "-")
  text = text:gsub("^-+", ""):gsub("-+$", "")
  return text
end

function M.path_join(...)
  local parts = { ... }
  local filtered = {}
  for _, part in ipairs(parts) do
    if part and part ~= "" then
      table.insert(filtered, tostring(part))
    end
  end
  local sep = package.config:sub(1, 1)
  local path = table.concat(filtered, sep)
  path = path:gsub(sep .. "+", sep)
  return path
end

function M.parent_dir(path)
  return vim.fn.fnamemodify(path, ":h")
end

function M.ensure_dir(path)
  if vim.fn.isdirectory(path) == 0 then
    vim.fn.mkdir(path, "p")
  end
end

function M.template_filename(template, data)
  local values = {
    id = tostring(data.id or data.fid or ""),
    fid = tostring(data.fid or data.id or ""),
    name = data.name or "",
    slug = data.slug or M.slugify(data.name or ""),
    ["kebab-case-name"] = data.slug or M.slugify(data.name or ""),
    ext = (data.ext or ""):gsub("^%.", ""),
    lang = data.lang or "",
  }
  return (template:gsub("%${([^}]+)}", function(key)
    return values[key] or ""
  end))
end

function M.first_non_empty_line(content)
  for _, line in ipairs(M.split_lines(content)) do
    if M.trim(line) ~= "" then
      return M.trim(line)
    end
  end
  return ""
end

return M
