# leetcode.nvim

Solve LeetCode problems from Neovim using the same CLI family as the VS Code
LeetCode extension.

This plugin can log in, search problems, open a problem into a local solution
file with the description, run tests, submit, and show results in a compact
floating panel.

It is inspired by
[LeetCode-OpenSource/vscode-leetcode](https://github.com/LeetCode-OpenSource/vscode-leetcode)
and uses
[vsc-leetcode-cli](https://www.npmjs.com/package/vsc-leetcode-cli) for the
LeetCode transport layer.

## Features

- Cookie login that writes the session where `vsc-leetcode-cli` expects it:
  `~/.lc/leetcode/user.json`.
- Search problems from Neovim and open the selected problem into your workspace.
- Generated solution files include the LeetCode problem description and `@lc`
  metadata.
- Run `:LeetCodeTest` and `:LeetCodeSubmit` from the solution buffer.
- Test/submit results appear in a floating panel with status, runtime, memory,
  testcase input, output, expected output, stdout, and errors when available.
- Telescope is used automatically for pickers when installed.
- Plenary is used automatically for floating text prompts when installed.
- Works without Telescope or Plenary by falling back to built-in Neovim UI.

## Quick Start

1. Install the plugin.

Native Neovim packages:

```sh
mkdir -p ~/.local/share/nvim/site/pack/plugins/start
git clone git@github.com:sidntrivedi/leetcode.nvim \
  ~/.local/share/nvim/site/pack/plugins/start/leetcode.nvim
```

2. Install the local CLI dependency, unless you already have a compatible
   `leetcode` binary on `PATH`.

```sh
cd ~/.local/share/nvim/site/pack/plugins/start/leetcode.nvim
npm install
```

3. Add setup code to Neovim.

```lua
require("leetcode").setup({
  workspace = vim.fn.expand("~/Code/leetcode"),
})
```

4. Restart Neovim and run:

```vim
:LeetCodeHealth
:LeetCodeLogin
:LeetCodeSearch two sum
```

5. Inside an opened solution file:

```vim
:LeetCodeTest
:LeetCodeSubmit
```

## Prerequisites

- Neovim 0.10 or newer.
- Node.js available on your `PATH`.
- Network access to `leetcode.com`.
- A LeetCode browser session for the recommended cookie login flow.
- `vsc-leetcode-cli`, available in one of these ways:
  local `node_modules` inside this plugin, a global `leetcode` executable on
  `PATH`, or a configured `cli.path`.

Optional but recommended:

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for
  selection pickers.
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for floating text
  prompts.

## Installation

### Native Packages

Use this if you install plugins with Neovim's built-in package layout
(`:h packages`), sometimes called vim packages or vim-pack.

```sh
mkdir -p ~/.local/share/nvim/site/pack/plugins/start
git clone git@github.com:sidntrivedi/leetcode.nvim \
  ~/.local/share/nvim/site/pack/plugins/start/leetcode.nvim
```

Install the plugin-local CLI dependency:

```sh
cd ~/.local/share/nvim/site/pack/plugins/start/leetcode.nvim
npm install
```

If you already have a compatible `leetcode` executable on `PATH`, the
`npm install` step is optional.

The global CLI option is:

```sh
npm install -g vsc-leetcode-cli
```

### lazy.nvim

```lua
{
  "sidntrivedi/leetcode.nvim",
  build = "npm install",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("leetcode").setup({
      workspace = vim.fn.expand("~/Code/leetcode"),
    })
  end,
}
```

If you use a global `leetcode` binary instead of the plugin-local CLI, you can
omit `build = "npm install"`.

### Other Plugin Managers

Install `sidntrivedi/leetcode.nvim` using your manager's normal GitHub plugin
syntax. After it is cloned, make sure `vsc-leetcode-cli` is available.

Local CLI option:

```sh
cd /path/to/leetcode.nvim
npm install
```

Global CLI option:

```sh
npm install -g vsc-leetcode-cli
```

Then either let the plugin find `leetcode` on `PATH`, or configure an exact
path:

```lua
require("leetcode").setup({
  cli = {
    path = "/path/to/leetcode",
  },
})
```

## Setup

Minimal setup:

```lua
require("leetcode").setup({
  workspace = vim.fn.expand("~/Code/leetcode"),
})
```

Example `~/.config/nvim/lua/plugins/leetcode.lua`:

```lua
require("leetcode").setup({
  workspace = vim.fn.expand("~/Code/leetcode"),
  lang = "golang",
})
```

Then load it from `~/.config/nvim/init.lua`:

```lua
require("plugins.leetcode")
```

Full defaults:

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
  output = {
    split = "botright 12split",
  },
})
```

## First Login

Run:

```vim
:LeetCodeLogin
```

Choose `Cookie`, then enter:

- your LeetCode username or email
- either a full copied cookie string, or only the raw `LEETCODE_SESSION` value
- the raw `csrftoken` value, only if you did not paste a full cookie string

The plugin builds this cookie format for you:

```text
LEETCODE_SESSION=<session-value>; csrftoken=<csrf-value>;
```

It saves the session to:

```text
~/.lc/leetcode/user.json
```

Check whether the saved session looks usable:

```vim
:LeetCodeLoginStatus
```

## Daily Workflow

Search and open a problem:

```vim
:LeetCodeSearch two sum
```

Open directly by id, slug, or title:

```vim
:LeetCodeOpen 1
:LeetCodeOpen two-sum
```

Change language for future opens:

```vim
:LeetCodeLang
:LeetCodeLang python3
```

Run the sample tests for the current solution file:

```vim
:LeetCodeTest
```

Run with an explicit testcase:

```vim
:LeetCodeTest [2,7,11,15]\n9
```

Submit:

```vim
:LeetCodeSubmit
```

## Result Panel

`LeetCodeTest` and `LeetCodeSubmit` show a focused floating result panel.

Panel keys:

- `q` closes the panel.
- `<Esc>` closes the panel.
- `r` opens the full raw CLI output in the normal output buffer.

The panel shows parsed fields when the CLI output includes them:

- status or verdict
- cases passed
- runtime
- memory
- input
- your output
- expected output
- stdout
- compile/runtime errors

## Input UI

Typed values use floating text boxes instead of command-line prompts. This
includes search queries, direct-open prompts, username/email, cookie input, and
`csrftoken`.

Selection prompts use Telescope automatically when available. Without Telescope,
they fall back to `vim.ui.select`.

Typed prompts use Plenary automatically when available. Without Plenary, they
fall back to a native Neovim floating input window.

Secret values are masked while typing and redacted from output buffers.

## Commands

| Command | What it does |
| --- | --- |
| `:LeetCodeLogin` | Log in. Cookie login is the recommended flow. |
| `:LeetCodeLoginStatus` | Validate the saved session file and run a lightweight authenticated check. |
| `:LeetCodeLogout` | Log out using the CLI. |
| `:LeetCodeUser` | Show the current CLI user. |
| `:LeetCodeHealth` | Check workspace, CLI, Node, language, session file, and cookie fields. |
| `:LeetCodeLang [lang]` | Set the language used for future problem opens. |
| `:LeetCodeSearch [query]` | Search problems and open the selected problem. |
| `:LeetCodeOpen [id\|slug\|title]` | Open one problem directly. |
| `:LeetCodeTest [testcase]` | Run tests for the current LeetCode solution file. |
| `:LeetCodeSubmit` | Submit the current LeetCode solution file. |

## Solution File Detection

`LeetCodeTest` and `LeetCodeSubmit` need a real LeetCode solution file. Files
opened by this plugin include metadata like:

```text
@lc app=leetcode id=1 lang=golang
```

If your focus is in a UI buffer such as NvimTree, the plugin tries to find a
valid solution file from:

- the current buffer
- the alternate buffer
- visible windows in the current tab

If none are valid, it shows an actionable error.

## Health Check

Run this first if anything behaves unexpectedly:

```vim
:LeetCodeHealth
```

It checks:

- workspace directory
- configured language
- local CLI in `node_modules`
- fallback `leetcode` executable on `PATH`
- active CLI path
- Node.js
- filename template
- session file
- cookie fields

Each failing row includes a suggested fix.

## Troubleshooting

`active CLI` fails in `:LeetCodeHealth`:

```sh
cd /path/to/leetcode.nvim
npm install
```

Or configure a global CLI:

```lua
require("leetcode").setup({
  cli = {
    path = "/path/to/leetcode",
  },
})
```

`session file` or `cookie fields` fails:

```vim
:LeetCodeLogin
:LeetCodeLoginStatus
```

`LeetCodeTest` or `LeetCodeSubmit` says the current file is not a solution:

- focus the solution file and rerun the command
- keep the solution file visible in another window
- open the problem through `:LeetCodeOpen` or `:LeetCodeSearch`
- confirm the file contains an `@lc app=leetcode id=... lang=...` header

Telescope is installed but not used:

- make sure `telescope.nvim` is on Neovim's runtimepath
- restart Neovim after installing it
- check `:messages` for a `LeetCode Telescope picker unavailable` warning

## References

- [LeetCode VS Code extension](https://github.com/LeetCode-OpenSource/vscode-leetcode)
- [vsc-leetcode-cli on npm](https://www.npmjs.com/package/vsc-leetcode-cli)
- [leetcode-cli reference project](https://github.com/LeetCode-OpenSource/leetcode-cli)
