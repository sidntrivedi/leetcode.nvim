local config = require("leetcode.config")
local parser = require("leetcode.parser")
local util = require("leetcode.util")

local M = {}

function M.prepare_content(content, lang)
  if lang == "golang" and config.get().file.ensure_go_package then
    if util.first_non_empty_line(content) ~= "package main" then
      content = "package main\n\n" .. content
    end
  end
  if content:sub(-1) ~= "\n" then
    content = content .. "\n"
  end
  return content
end

function M.target_path(problem)
  local opts = config.get()
  local lang = problem.lang or opts.lang
  local data = vim.tbl_extend("force", {}, problem, {
    lang = lang,
    ext = util.lang_to_ext(lang),
  })
  local name = util.template_filename(opts.file.filename, data)
  return util.path_join(opts.workspace, opts.file.folder, name)
end

function M.write_or_open(problem, content)
  local opts = config.get()
  problem.lang = problem.lang or opts.lang
  local path = M.target_path(problem)

  if vim.fn.filereadable(path) == 1 and not opts.file.overwrite then
    vim.cmd.edit(vim.fn.fnameescape(path))
    return path, false
  end

  util.ensure_dir(util.parent_dir(path))
  local prepared = M.prepare_content(content, problem.lang)
  vim.fn.writefile(util.split_lines(prepared), path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  return path, true
end

function M.write_or_open_from_content(content)
  local problem = parser.problem_from_content(content)
  if not problem.lang or problem.lang == "" then
    problem.lang = config.get().lang
  end
  return M.write_or_open(problem, content)
end

return M

