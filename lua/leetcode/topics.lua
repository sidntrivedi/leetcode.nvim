local util = require("leetcode.util")

local M = {}

local topics = {
  { label = "Array", value = "array" },
  { label = "String", value = "string" },
  { label = "Hash Table", value = "hash-table" },
  { label = "Dynamic Programming", value = "dynamic-programming" },
  { label = "Math", value = "math" },
  { label = "Sorting", value = "sort" },
  { label = "Greedy", value = "greedy" },
  { label = "Depth-First Search", value = "depth-first-search" },
  { label = "Breadth-First Search", value = "breadth-first-search" },
  { label = "Tree", value = "tree" },
  { label = "Binary Tree", value = "binary-tree" },
  { label = "Binary Search", value = "binary-search" },
  { label = "Two Pointers", value = "two-pointers" },
  { label = "Sliding Window", value = "sliding-window" },
  { label = "Stack", value = "stack" },
  { label = "Queue", value = "queue" },
  { label = "Heap", value = "heap" },
  { label = "Graph", value = "graph" },
  { label = "Backtracking", value = "backtracking" },
  { label = "Linked List", value = "linked-list" },
  { label = "Bit Manipulation", value = "bit-manipulation" },
  { label = "Union Find", value = "union-find" },
  { label = "Trie", value = "trie" },
  { label = "Recursion", value = "recursion" },
  { label = "Divide and Conquer", value = "divide-and-conquer" },
  { label = "Design", value = "design" },
  { label = "Database", value = "database" },
  { label = "Random", value = "random" },
}

local difficulties = {
  { label = "Any", value = "", query = "" },
  { label = "Easy", value = "easy", query = "e" },
  { label = "Medium", value = "medium", query = "m" },
  { label = "Hard", value = "hard", query = "h" },
}

function M.list()
  return vim.deepcopy(topics)
end

function M.difficulties()
  return vim.deepcopy(difficulties)
end

function M.picker_items()
  local items = {}
  for _, topic in ipairs(topics) do
    for _, difficulty in ipairs(difficulties) do
      table.insert(items, {
        label = topic.label,
        value = topic.value,
        difficulty = difficulty.value,
        difficulty_label = difficulty.label,
        query = difficulty.query,
      })
    end
  end
  return items
end

function M.normalize(topic)
  topic = util.trim(topic or ""):lower()
  topic = topic:gsub("%s+", "-")
  return topic
end

function M.normalize_difficulty(difficulty)
  difficulty = util.trim(difficulty or ""):lower()
  if difficulty == "" or difficulty == "any" or difficulty == "all" then
    return "", ""
  end
  if difficulty == "e" or difficulty == "easy" then
    return "easy", "e"
  end
  if difficulty == "m" or difficulty == "medium" then
    return "medium", "m"
  end
  if difficulty == "h" or difficulty == "hard" then
    return "hard", "h"
  end
  return nil, nil
end

function M.parse_args(args)
  local parts = {}
  for part in util.trim(args or ""):gmatch("%S+") do
    table.insert(parts, part)
  end

  if #parts == 0 then
    return "", "", ""
  end

  local first_diff, first_query = M.normalize_difficulty(parts[1])
  local last_diff, last_query = M.normalize_difficulty(parts[#parts])

  if #parts > 1 and first_diff ~= nil and first_diff ~= "" then
    table.remove(parts, 1)
    return M.normalize(table.concat(parts, " ")), first_diff, first_query
  end

  if #parts > 1 and last_diff ~= nil and last_diff ~= "" then
    table.remove(parts, #parts)
    return M.normalize(table.concat(parts, " ")), last_diff, last_query
  end

  if #parts == 1 and first_diff ~= nil and first_diff ~= "" then
    return "", first_diff, first_query
  end

  return M.normalize(table.concat(parts, " ")), "", ""
end

function M.label(topic)
  topic = M.normalize(topic)
  for _, item in ipairs(topics) do
    if item.value == topic then
      return item.label
    end
  end
  return topic
end

function M.difficulty_label(difficulty)
  difficulty = M.normalize_difficulty(difficulty)
  if difficulty == "" then
    return "Any"
  end
  return difficulty:sub(1, 1):upper() .. difficulty:sub(2)
end

return M
