local assert = require('luassert')

describe('project.nvim setup', function()
  before_each(function()
    for name in pairs(package.loaded) do
      if name == 'project' or name:match('^project%.') then
        package.loaded[name] = nil
      end
    end
  end)

  it('sets default configuration', function()
    local project = require('project')

    assert.is_true(pcall(project.setup))
    assert.are_same(require('project.config.defaults'), require('project.config').options)
  end)

  it('merges user configuration with defaults', function()
    local project = require('project')

    assert.is_true(pcall(project.setup, { patterns = { '.git' }, scope_chdir = 'tab' }))
    assert.are_same({ '.git' }, require('project.config').options.patterns)
    assert.are_equal('tab', require('project.config').options.scope_chdir)
  end)

  for _, param in ipairs({ 1, false, '', function() end }) do
    it(('throws error when setup is called with %s'):format(type(param)), function()
      assert.is_false(pcall(require('project').setup, param))
    end)
  end
end)
