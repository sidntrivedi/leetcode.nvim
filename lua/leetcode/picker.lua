local M = {}

local function problem_display(problem)
  local state = problem.state or " "
  local locked = problem.locked and "locked" or "open"
  return string.format("%-6s %-60s %-8s %-7s %s", problem.fid or problem.id, problem.name, problem.level or "", state, locked)
end

local function load_telescope()
  local ok = pcall(require, "telescope")
  if ok then
    return true
  end

  pcall(vim.cmd, "silent! packadd telescope.nvim")
  ok = pcall(require, "telescope")
  return ok
end

local function telescope_select(items, opts, callback)
  if not load_telescope() then
    return false
  end

  local ok, err = pcall(function()
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    pickers.new({}, {
      prompt_title = opts.prompt or "LeetCode",
      finder = finders.new_table({
        results = items,
        entry_maker = function(item)
          local text = opts.format_item and opts.format_item(item) or tostring(item)
          return {
            value = item,
            display = text,
            ordinal = text,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if entry then
            callback(entry.value)
          end
        end)
        return true
      end,
    }):find()
  end)

  if not ok then
    return false, err
  end
  return true
end

function M.select_items(items, opts, callback)
  opts = opts or {}
  local ok, err = telescope_select(items, opts, callback)
  if ok then
    return
  end

  if err then
    vim.schedule(function()
      vim.notify("LeetCode Telescope picker unavailable: " .. tostring(err), vim.log.levels.WARN, { title = "leetcode.nvim" })
    end)
  end

  vim.ui.select(items, opts, callback)
end

function M.select_problem(problems, callback)
  M.select_items(problems, {
    prompt = "LeetCode problems",
    format_item = problem_display,
  }, callback)
end

return M
