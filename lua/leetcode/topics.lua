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

function M.list()
  return vim.deepcopy(topics)
end

function M.normalize(topic)
  topic = util.trim(topic or ""):lower()
  topic = topic:gsub("%s+", "-")
  return topic
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

return M
