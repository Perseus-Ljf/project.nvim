local Config = require('project.config')
local Core = require('project.core')
local Util = require('project.util')

local M = {
  config = Config,
  core = Core,
  util = Util,
}

function M.setup(options)
  return Config.setup(options)
end

function M.get_project_root(bufnr)
  return Core.get_project_root(bufnr)
end

function M.current_project(refresh)
  if refresh then
    return Core.get_current_project()
  end

  return Core.current_project, Core.current_method
end

local function normalize_patterns(patterns)
  if type(patterns) == 'string' then
    return { patterns }
  end

  return patterns
end

function M.add_root_patterns(patterns)
  Util.validate({ patterns = { patterns, { 'string', 'table' } } })

  for _, pattern in ipairs(normalize_patterns(patterns)) do
    if pattern ~= '' and not vim.list_contains(Config.options.patterns, pattern) then
      table.insert(Config.options.patterns, pattern)
    end
  end
end

function M.remove_root_patterns(patterns)
  Util.validate({ patterns = { patterns, { 'string', 'table' } } })

  for _, pattern in ipairs(normalize_patterns(patterns)) do
    for i = #Config.options.patterns, 1, -1 do
      if Config.options.patterns[i] == pattern then
        table.remove(Config.options.patterns, i)
      end
    end
  end
end

return M
