local M = {}

local function window_config(prompt, width)
  local columns = vim.o.columns
  local lines = vim.o.lines
  local max_width = math.max(20, columns - 6)
  width = math.min(width or math.max(50, #prompt + 12), max_width)

  return {
    relative = "editor",
    width = width,
    height = 1,
    row = math.floor((lines - 3) / 2),
    col = math.floor((columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. prompt .. " ",
    title_pos = "left",
  }
end

local function close(buf, win)
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

function M.prompt(opts, callback)
  opts = opts or {}
  local prompt = opts.prompt or "Input"
  local default = opts.default or ""
  local buf = vim.api.nvim_create_buf(false, true)

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].undolevels = -1
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { default })

  local win = vim.api.nvim_open_win(buf, true, window_config(prompt, opts.width))
  vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"

  if opts.secret then
    vim.wo[win].conceallevel = 2
    vim.wo[win].concealcursor = "nivc"
    vim.api.nvim_win_call(win, function()
      vim.fn.matchadd("Conceal", ".", 10, -1, { conceal = "*" })
    end)
  end

  local done = false
  local function finish(value)
    if done then
      return
    end
    done = true
    close(buf, win)
    callback(value)
  end

  local function submit()
    local value = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
    finish(value)
  end

  local function cancel()
    finish(nil)
  end

  local map_opts = { buffer = buf, nowait = true, noremap = true, silent = true }
  vim.keymap.set({ "i", "n" }, "<CR>", submit, map_opts)
  vim.keymap.set({ "i", "n" }, "<Esc>", cancel, map_opts)
  vim.keymap.set({ "i", "n" }, "<C-c>", cancel, map_opts)

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    once = true,
    callback = function()
      if not done then
        finish(nil)
      end
    end,
  })

  vim.api.nvim_win_set_cursor(win, { 1, #default })
  vim.cmd("startinsert!")
end

return M
