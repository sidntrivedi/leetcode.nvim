if vim.g.loaded_leetcode_nvim == 1 then
  return
end
vim.g.loaded_leetcode_nvim = 1

require("leetcode").setup()

