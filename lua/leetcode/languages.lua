local config = require("leetcode.config")
local util = require("leetcode.util")

local M = {}

function M.list()
  return util.supported_langs()
end

function M.current()
  return config.get().lang
end

function M.set(lang)
  if not util.is_supported_lang(lang) then
    return false, "Unsupported LeetCode language: " .. tostring(lang)
  end
  config.set_lang(lang)
  return true
end

function M.select()
  require("leetcode.picker").select_items(M.list(), { prompt = "LeetCode language" }, function(lang)
    if not lang then
      return
    end
    local ok, err = M.set(lang)
    if ok then
      util.notify("LeetCode language set to " .. lang)
    else
      util.notify(err, vim.log.levels.ERROR)
    end
  end)
end

return M
