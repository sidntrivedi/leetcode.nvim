# leetcode.nvim

A small Neovim wrapper around the same LeetCode CLI used by the VS Code
extension. It supports login/logout, searching problems, generating solution
files with descriptions, running tests, and submitting the current file.

This plugin is inspired by
[LeetCode-OpenSource/vscode-leetcode](https://github.com/LeetCode-OpenSource/vscode-leetcode)
and uses
[vsc-leetcode-cli](https://www.npmjs.com/package/vsc-leetcode-cli) for the
LeetCode transport layer.

## Prerequisites

- Neovim 0.10 or newer.
- Node.js and npm available on your `PATH`.
- Network access to `leetcode.com` for login, problem fetch, test, and submit.
- A LeetCode browser session if you use the recommended cookie login flow. The
  cookie string must include `LEETCODE_SESSION` and `csrftoken`.
- The local Node dependency installed from this plugin directory with
  `npm install`. This installs
  [`vsc-leetcode-cli`](https://www.npmjs.com/package/vsc-leetcode-cli), the CLI
  used by the VS Code extension.

## Installation

### Native Packages

Use this section if you install plugins with Neovim's built-in package layout
(`:h packages`), sometimes called vim packages or vim-pack. Clone the plugin
into `pack/plugins/start`, then install the local Node dependency:

```sh
mkdir -p ~/.local/share/nvim/site/pack/plugins/start
git clone git@github.com:sidntrivedi/leetcode.nvim \
  ~/.local/share/nvim/site/pack/plugins/start/leetcode.nvim
cd ~/.local/share/nvim/site/pack/plugins/start/leetcode.nvim
npm install
```

### Other Plugin Managers

If you use a plugin manager such as `lazy.nvim`, `packer.nvim`, or `vim-plug`,
install `sidntrivedi/leetcode.nvim` using that manager's normal GitHub plugin
syntax. After the plugin is cloned, run `npm install` inside the cloned plugin
directory so `vsc-leetcode-cli` is available.

Example dependency install:

```sh
cd /path/to/leetcode.nvim
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

The plugin builds the cookie string for you and saves it where
`vsc-leetcode-cli` reads its session: `~/.lc/leetcode/user.json`.

Internally, the plugin formats those values as:

```text
LEETCODE_SESSION=<session-value>; csrftoken=<csrf-value>;
```

The cookie is redacted from output buffers.
