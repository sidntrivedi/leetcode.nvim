local M = {}

local function dimensions(prompt, requested_width)
  local columns = vim.o.columns
  local max_width = math.max(20, columns - 6)
  return math.min(requested_width or math.max(50, #prompt + 12), max_width)
end

local function window_config(prompt, width)
  local columns = vim.o.columns
  local lines = vim.o.lines

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

local function load_plenary_popup()
  local ok, popup = pcall(require, "plenary.popup")
  if ok then
    return popup
  end

  pcall(vim.cmd, "silent! packadd plenary.nvim")
  ok, popup = pcall(require, "plenary.popup")
  if ok then
    return popup
  end
  return nil
end

local function close(buf, win)
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

local function prepare_buffer(default)
  local buf = vim.api.nvim_create_buf(false, true)

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].undolevels = -1
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { default })
  return buf
end

local function apply_secret_mask(win)
  vim.wo[win].conceallevel = 2
  vim.wo[win].concealcursor = "nivc"
  vim.api.nvim_win_call(win, function()
    vim.fn.matchadd("Conceal", ".", 10, -1, { conceal = "*" })
  end)
end

local function attach_handlers(buf, win, default, callback)
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

local function native_prompt(opts, callback)
  local prompt = opts.prompt or "Input"
  local default = opts.default or ""
  local width = dimensions(prompt, opts.width)
  local buf = prepare_buffer(default)
  local win = vim.api.nvim_open_win(buf, true, window_config(prompt, width))
  vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"

  if opts.secret then
    apply_secret_mask(win)
  end

  attach_handlers(buf, win, default, callback)
end

local function plenary_prompt(opts, callback)
  local popup = load_plenary_popup()
  if not popup then
    return false
  end

  local prompt = opts.prompt or "Input"
  local default = opts.default or ""
  local width = dimensions(prompt, opts.width)
  local buf = prepare_buffer(default)
  local ok, win = pcall(popup.create, buf, {
    line = 0,
    col = 0,
    minwidth = width,
    maxwidth = width,
    minheight = 1,
    maxheight = 1,
    border = true,
    title = " " .. prompt .. " ",
    enter = true,
    focusable = true,
  })
  if not ok then
    close(buf, -1)
    return false
  end

  if opts.secret then
    apply_secret_mask(win)
  end

  attach_handlers(buf, win, default, callback)
  return true
end

function M.prompt(opts, callback)
  opts = opts or {}
  if plenary_prompt(opts, callback) then
    return
  end
  native_prompt(opts, callback)
end

return M
