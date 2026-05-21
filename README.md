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
- Node.js available on your `PATH`.
- Network access to `leetcode.com` for login, problem fetch, test, and submit.
- A LeetCode browser session if you use the recommended cookie login flow. The
  cookie string must include `LEETCODE_SESSION` and `csrftoken`.
- [`vsc-leetcode-cli`](https://www.npmjs.com/package/vsc-leetcode-cli)
  available either from this plugin's local `node_modules`, from a `leetcode`
  executable on `PATH`, or from `cli.path` in setup.

## Installation

### Native Packages

Use this section if you install plugins with Neovim's built-in package layout
(`:h packages`), sometimes called vim packages or vim-pack. Clone the plugin
into `pack/plugins/start`:

```sh
mkdir -p ~/.local/share/nvim/site/pack/plugins/start
git clone git@github.com:sidntrivedi/leetcode.nvim \
  ~/.local/share/nvim/site/pack/plugins/start/leetcode.nvim
```

If you do not already have a compatible `leetcode` binary on `PATH`, install the
local CLI dependency:

```sh
cd ~/.local/share/nvim/site/pack/plugins/start/leetcode.nvim
npm install
```

### Other Plugin Managers

If you use a plugin manager such as `lazy.nvim`, `packer.nvim`, or `vim-plug`,
install `sidntrivedi/leetcode.nvim` using that manager's normal GitHub plugin
syntax. After the plugin is cloned, make sure `vsc-leetcode-cli` is available.
The simplest option is to run `npm install` inside the cloned plugin directory:

Example dependency install:

```sh
cd /path/to/leetcode.nvim
npm install
```

If you already have a compatible `leetcode` executable installed globally, you
can skip `npm install`; the plugin falls back to `leetcode` on `PATH`. You can
also point at a specific CLI executable:

```lua
require("leetcode").setup({
  cli = {
    path = "/path/to/leetcode",
  },
})
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
