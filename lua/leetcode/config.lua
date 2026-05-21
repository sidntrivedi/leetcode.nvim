local M = {}

M.defaults = {
  workspace = vim.fn.getcwd(),
  lang = "golang",
  file = {
    folder = "",
    filename = "${id}.${kebab-case-name}.${ext}",
    overwrite = false,
    ensure_go_package = true,
  },
  cli = {
    node = "node",
    path = nil,
  },
  output = {
    split = "botright 12split",
  },
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  M.options.workspace = vim.fn.expand(M.options.workspace)
  M.options.file.folder = vim.fn.expand(M.options.file.folder or "")
  return M.options
end

function M.get()
  return M.options
end

return M

