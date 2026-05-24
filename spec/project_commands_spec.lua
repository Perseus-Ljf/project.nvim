local assert = require('luassert')

describe('project.nvim root detection', function()
  before_each(function()
    for name in pairs(package.loaded) do
      if name == 'project' or name:match('^project%.') then
        package.loaded[name] = nil
      end
    end
  end)

  it('detects a parent directory with a matching pattern', function()
    local cwd = vim.fn.getcwd()

    require('project').setup({ patterns = { '.git' } })
    vim.cmd.edit('README.md')
    local root, method = require('project').get_project_root()

    assert.are_equal(cwd, root)
    assert.are_equal('pattern .git', method)
  end)

  it('keeps disable_on support for filetypes', function()
    local cwd = vim.fn.getcwd()
    local root = vim.fn.tempname()
    local nested = root .. '/a/b'
    vim.fn.mkdir(root .. '/.git', 'p')
    vim.fn.mkdir(nested, 'p')
    vim.fn.writefile({}, nested .. '/file.md')

    require('project').setup({
      patterns = { '.git' },
      manual_mode = true,
      disable_on = { ft = { 'markdown' } },
    })
    vim.cmd.edit(nested .. '/file.md')
    vim.bo.filetype = 'markdown'
    require('project.core').on_buf_enter()

    assert.are_equal(cwd, vim.fn.getcwd())
    assert.is_nil(require('project.core').current_project)
  end)
end)
