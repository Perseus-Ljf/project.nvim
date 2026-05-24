# project.nvim

A minimal Neovim project rooter.

It detects the current project root from configurable patterns and changes Neovim's current working directory to that root. This makes tools such as `:Telescope find_files` start from the current project directory without requiring a Telescope extension.

## Setup

```lua
require('project').setup()
```

With custom patterns:

```lua
require('project').setup({
  patterns = { '.git', 'pyproject.toml', 'package.json' },
})
```

## Options

Defaults:

```lua
{
  patterns = {
    '.git',
    '.github',
    '_darcs',
    '.hg',
    '.bzr',
    '.svn',
    'Pipfile',
    'pyproject.toml',
    '.pre-commit-config.yaml',
    '.pre-commit-config.yml',
    '.csproj',
    '.sln',
    '.nvim.lua',
    '.neoconf.json',
    'neoconf.json',
  },
  manual_mode = false,
  enable_autochdir = false,
  silent_chdir = true,
  scope_chdir = 'global',
  exclude_dirs = {},
  disable_on = {
    ft = {
      'NvimTree',
      'TelescopePrompt',
      'TelescopeResults',
      'alpha',
      'checkhealth',
      'lazy',
      'log',
      'ministarter',
      'neo-tree',
      'notify',
      'nvim-pack',
      'packer',
      'qf',
    },
    bt = { 'help', 'nofile', 'nowrite', 'terminal' },
  },
}
```

`scope_chdir` controls how the directory is changed:

- `global`: use `vim.api.nvim_set_current_dir`
- `tab`: use `:tchdir`
- `win`: use `:lchdir`

Set `manual_mode = true` to disable the `BufEnter` autocmd and call the detector yourself:

```lua
require('project.core').on_buf_enter()
```

## Pattern Syntax

- `.git`: root contains a matching file or directory.
- `=src`: root directory name is exactly `src`.
- `^fixtures`: root has an ancestor named `fixtures`.
- `>Latex`: root's direct parent is named `Latex`.
- `!.git/worktrees`: exclude a match. Put exclusions before inclusions.

## API

```lua
local project = require('project')

project.setup(opts)

local root, method = project.get_project_root()
local current_root, current_method = project.current_project()

project.add_root_patterns({ 'package.json' })
project.remove_root_patterns('.github')
```
