local M = {}

local function display(problem)
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

local function telescope_select(problems, callback)
  if not load_telescope() then
    return false, "Telescope is not available"
  end

  local ok, err = pcall(function()
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    pickers.new({}, {
      prompt_title = "LeetCode Problems",
      finder = finders.new_table({
        results = problems,
        entry_maker = function(problem)
          return {
            value = problem,
            display = display(problem),
            ordinal = table.concat({ problem.fid or problem.id, problem.name, problem.level or "", problem.state or "" }, " "),
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

function M.select_problem(problems, callback)
  local ok, err = telescope_select(problems, callback)
  if ok then
    return
  end

  if err then
    vim.schedule(function()
      vim.notify("LeetCode Telescope picker unavailable: " .. tostring(err), vim.log.levels.WARN, { title = "leetcode.nvim" })
    end)
  end

  vim.ui.select(problems, {
    prompt = "LeetCode problems",
    format_item = function(item)
      return display(item)
    end,
  }, callback)
end

return M
