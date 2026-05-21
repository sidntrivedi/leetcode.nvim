local util = require("leetcode.util")

local M = {}

local function clean(raw)
  return util.strip_ansi(util.redact(raw or ""))
end

local function line_match(lines, pattern)
  for _, line in ipairs(lines) do
    local match = line:match(pattern)
    if match then
      return util.trim(match)
    end
  end
  return nil
end

function M.parse(kind, raw, code)
  raw = clean(raw)
  local lines = util.split_lines(raw)
  local parsed = { kind = kind, ok = code == 0, raw = raw, fields = {} }

  parsed.verdict = line_match(lines, "^%s*[✔✘]?%s*([%a%s]+)$")
  parsed.cases = line_match(lines, "([%d]+/%d+ cases passed[^%n]*)")
  parsed.runtime = line_match(lines, "Runtime[^:]*:%s*(.+)")
  parsed.memory = line_match(lines, "Memory[^:]*:%s*(.+)")
  parsed.input = line_match(lines, "Your Input:%s*(.+)") or line_match(lines, "Testcase:%s*(.+)")
  parsed.output = line_match(lines, "Output[^:]*:%s*(.+)") or line_match(lines, "Answer:%s*(.+)")
  parsed.expected = line_match(lines, "Expected Answer:%s*(.+)") or line_match(lines, "Expected_answer:%s*(.+)")
  parsed.stdout = line_match(lines, "Stdout:%s*(.*)")
  parsed.error = line_match(lines, "Error:%s*(.+)") or line_match(lines, "Compile Error:%s*(.+)")

  if raw:match("Accepted") or raw:match("Finished") then
    parsed.verdict = parsed.verdict or "Accepted"
    parsed.ok = true
  elseif raw:match("Wrong Answer") then
    parsed.verdict = "Wrong Answer"
    parsed.ok = false
  elseif raw:match("Compile Error") then
    parsed.verdict = "Compile Error"
    parsed.ok = false
  elseif raw:match("Runtime Error") then
    parsed.verdict = "Runtime Error"
    parsed.ok = false
  end

  return parsed
end

function M.format(kind, raw, code)
  local parsed = M.parse(kind, raw, code)
  local title = kind == "submit" and "Submit result" or "Test result"
  local lines = { title, "" }

  local status = parsed.verdict or (parsed.ok and "Finished" or "Failed")
  table.insert(lines, "Status: " .. status)
  if parsed.cases then table.insert(lines, "Cases: " .. parsed.cases) end
  if parsed.runtime then table.insert(lines, "Runtime: " .. parsed.runtime) end
  if parsed.memory then table.insert(lines, "Memory: " .. parsed.memory) end
  if parsed.input then table.insert(lines, "Input: " .. parsed.input) end
  if parsed.output then table.insert(lines, "Output: " .. parsed.output) end
  if parsed.expected then table.insert(lines, "Expected: " .. parsed.expected) end
  if parsed.stdout and parsed.stdout ~= "" then table.insert(lines, "Stdout: " .. parsed.stdout) end
  if parsed.error then table.insert(lines, "Error: " .. parsed.error) end

  table.insert(lines, "")
  table.insert(lines, "Raw output")
  table.insert(lines, "----------")
  vim.list_extend(lines, util.split_lines(parsed.raw))

  return table.concat(lines, "\n")
end

return M

