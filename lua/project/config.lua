local Defaults = require('project.config.defaults')
local Util = require('project.util')

local M = {}

M.options = vim.deepcopy(Defaults)

local function merge_options(options)
  options = options or {}
  Util.validate({ options = { options, { 'table' } } })

  local merged = vim.tbl_deep_extend('force', vim.deepcopy(Defaults), options)
  if options.patterns ~= nil then
    merged.patterns = options.patterns
  end
  if options.exclude_dirs ~= nil then
    merged.exclude_dirs = options.exclude_dirs
  end
  if options.disable_on and options.disable_on.ft ~= nil then
    merged.disable_on.ft = options.disable_on.ft
  end
  if options.disable_on and options.disable_on.bt ~= nil then
    merged.disable_on.bt = options.disable_on.bt
  end

  if type(merged.patterns) ~= 'table' or vim.tbl_isempty(merged.patterns) then
    merged.patterns = vim.deepcopy(Defaults.patterns)
  end

  local patterns = {}
  for _, pattern in ipairs(merged.patterns) do
    if type(pattern) == 'string' and pattern ~= '' and not vim.list_contains(patterns, pattern) then
      table.insert(patterns, pattern)
    end
  end
  merged.patterns = vim.tbl_isempty(patterns) and vim.deepcopy(Defaults.patterns) or patterns

  if type(merged.exclude_dirs) ~= 'table' then
    merged.exclude_dirs = {}
  end
  merged.exclude_dirs = vim.tbl_map(function(pattern)
    return require('project.util.globtopattern').pattern_exclude(pattern)
  end, merged.exclude_dirs)

  if not vim.list_contains({ 'global', 'tab', 'win' }, merged.scope_chdir) then
    merged.scope_chdir = Defaults.scope_chdir
  end

  merged.manual_mode = merged.manual_mode == true
  merged.silent_chdir = merged.silent_chdir ~= false
  merged.enable_autochdir = merged.enable_autochdir == true
  merged.disable_on = vim.tbl_deep_extend('force', vim.deepcopy(Defaults.disable_on), merged.disable_on or {})

  return merged
end

function M.setup(options)
  M.options = merge_options(options)
  vim.o.autochdir = M.options.enable_autochdir
  vim.g.project_setup = 1

  require('project.core').setup()
end

function M.get_config()
  return vim.inspect(M.options)
end

return M
