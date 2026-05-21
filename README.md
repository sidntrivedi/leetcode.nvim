# leetcode.nvim

A small Neovim wrapper around the same LeetCode CLI used by the VS Code
extension. It supports login/logout, searching problems, generating solution
files with descriptions, running tests, and submitting the current file.

## Prerequisites

- Neovim 0.10 or newer.
- Node.js and npm available on your `PATH`.
- Network access to `leetcode.com` for login, problem fetch, test, and submit.
- A LeetCode browser session if you use the recommended cookie login flow. The
  cookie string must include `LEETCODE_SESSION` and `csrftoken`.
- The `vsc-leetcode-cli` dependency installed locally for this plugin with
  `npm install`.

## Installation

This config uses Neovim's native package layout. Clone the plugin into
`pack/plugins/start`, then install the local Node dependency:

```sh
mkdir -p ~/.local/share/nvim/site/pack/plugins/start
git clone git@github.com:sidntrivedi/leetcode.nvim \
  ~/.local/share/nvim/site/pack/plugins/start/leetcode.nvim
cd ~/.local/share/nvim/site/pack/plugins/start/leetcode.nvim
npm install
```

## Setup

Create `~/.config/nvim/lua/plugins/leetcode.lua`:

```lua
require("leetcode").setup({
  workspace = vim.fn.expand("~/Code/leetcode"),
})
```

Then load it from `~/.config/nvim/init.lua` with your other plugin configs:

```lua
safe_require("plugins.leetcode")
```

Defaults:

```lua
require("leetcode").setup({
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
})
```

## Commands

- `:LeetCodeLogin` logs in. Cookie login is the default and recommended flow.
- `:LeetCodeLogout` logs out.
- `:LeetCodeUser` shows the current user.
- `:LeetCodeSearch [query]` searches problems and opens the selected problem.
- `:LeetCodeOpen <id|slug|title>` opens one problem directly.
- `:LeetCodeTest [testcase]` runs tests for the current file.
- `:LeetCodeSubmit` submits the current file.
- `:LeetCodeHealth` checks Node, CLI path, and basic configuration.

## Cookie Login

Use `:LeetCodeLogin`, choose cookie login, then enter:

- your LeetCode username or email
- either a full copied cookie string, or the raw `LEETCODE_SESSION` value
- the raw `csrftoken` value, only if you did not paste a full cookie string

The plugin builds the cookie string for you and sends it to:

```sh
leetcode user -c
```

Internally, the plugin formats those values as:

```text
LEETCODE_SESSION=<session-value>; csrftoken=<csrf-value>;
```

The cookie is redacted from output buffers.
