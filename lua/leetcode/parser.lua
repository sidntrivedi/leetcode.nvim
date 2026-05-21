local util = require("leetcode.util")

local M = {}

function M.problem_from_content(content)
  local problem = {}
  local meta = content:match("@lc%s+app=leetcode%s+id=([^%s]+)%s+lang=([^%s]+)")
  if meta then
    problem.id, problem.lang = content:match("@lc%s+app=leetcode%s+id=([^%s]+)%s+lang=([^%s]+)")
    problem.fid = problem.id
  end

  local fid, name = content:match("%[([^%]]+)%]%s*([^\n]+)")
  if fid and name then
    problem.fid = util.trim(fid)
    problem.id = problem.id or problem.fid
    problem.name = util.trim(name)
  end

  local slug = content:match("https://leetcode%.com/problems/([^/%s]+)/")
  problem.slug = slug or util.slugify(problem.name or "")
  return problem
end

function M.parse_list(output)
  local problems = {}
  for _, raw in ipairs(util.split_lines(output)) do
    local line = util.strip_ansi(raw)
    local locked = line:find("🔒", 1, true) ~= nil
    local starred = line:find("★", 1, true) ~= nil
    local state = "None"
    if line:find("✔", 1, true) then
      state = "ac"
    elseif line:find("✘", 1, true) then
      state = "notac"
    end
    line = line:gsub("[✔✘★☆🔒]", " ")
    local id, rest = line:match("%[%s*([%w%-]+)%s*%]%s+(.+)")
    local name, level, percent
    if id and rest then
      for _, difficulty in ipairs({ "Easy", "Medium", "Hard" }) do
        name, percent = rest:match("^(.-)%s+" .. difficulty .. "%s+%(([%d%.]+)%s*%%%)%s*$")
        if name then
          level = difficulty
          break
        end
      end
    end
    if id and name then
      table.insert(problems, {
        id = util.trim(id),
        fid = util.trim(id),
        name = util.trim(name),
        slug = util.slugify(name),
        level = level,
        percent = tonumber(percent),
        locked = locked,
        starred = starred,
        state = state,
      })
    end
  end
  return problems
end

function M.meta_from_file(path, content)
  content = content or table.concat(vim.fn.readfile(path), "\n")
  local id, lang = content:match("@lc%s+app=leetcode%s+id=([^%s]+)%s+lang=([^%s]+)")
  if id and lang then
    return { id = id, fid = id, lang = lang, source = "metadata", valid = true }
  end

  local name = vim.fn.fnamemodify(path, ":t:r")
  id = name:match("^([^.]+)")
  lang = util.ext_to_lang(path)
  local valid = id ~= nil and id ~= "" and lang ~= "unknown"
  return {
    id = id,
    fid = id,
    lang = lang,
    source = "filename",
    valid = valid,
    warning = valid
        and "Missing @lc metadata, using filename and extension fallback"
      or "Current file is missing @lc metadata and does not look like a LeetCode solution file",
  }
end

return M
