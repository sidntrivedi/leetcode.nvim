vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.opt.packpath:prepend(vim.fn.getcwd())
vim.opt.shadafile = "NONE"
vim.opt.swapfile = false
vim.opt.directory = vim.fn.getcwd()
package.path = vim.fn.getcwd() .. "/tests/?.lua;" .. package.path
