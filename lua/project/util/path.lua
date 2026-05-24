local Config = require('project.config')
local Util = require('project.util')

local uv = vim.uv or vim.loop

local M = {}

M.exists = Util.path_exists

function M.is_excluded(dir)
  Util.validate({ dir = { dir, { 'string' } } })

  for _, excluded in ipairs(Config.options.exclude_dirs) do
    if dir:match(excluded) then
      return true
    end
  end

  return false
end

function M.is(dir, identifier)
  Util.validate({
    dir = { dir, { 'string' } },
    identifier = { identifier, { 'string' } },
  })

  return dir:match('.*/(.*)') == identifier
end

function M.get_parent(path)
  Util.validate({ path = { path, { 'string' } } })

  local parent = path:match('^(.*)/')
  return parent ~= '' and parent or '/'
end

function M.has(dir, identifier)
  Util.validate({
    dir = { dir, { 'string' } },
    identifier = { identifier, { 'string' } },
  })

  local scan = uv.fs_scandir(dir)
  if not scan then
    return false
  end

  local pattern = require('project.util.globtopattern').globtopattern(identifier)
  while true do
    local file = uv.fs_scandir_next(scan)
    if not file then
      return false
    end
    if file:match(pattern) then
      return true
    end
  end
end

function M.sub(dir, identifier)
  Util.validate({
    dir = { dir, { 'string' } },
    identifier = { identifier, { 'string' } },
  })

  local path = M.get_parent(dir)
  local current
  while true do
    if M.is(path, identifier) then
      return true
    end
    current, path = path, M.get_parent(path)
    if current == path then
      return false
    end
  end
end

function M.child(dir, identifier)
  Util.validate({
    dir = { dir, { 'string' } },
    identifier = { identifier, { 'string' } },
  })

  return M.is(M.get_parent(dir), identifier)
end

function M.match(dir, pattern)
  Util.validate({
    dir = { dir, { 'string' } },
    pattern = { pattern, { 'string' } },
  })

  local switch = {
    ['='] = M.is,
    ['^'] = M.sub,
    ['>'] = M.child,
  }
  local first_char = pattern:sub(1, 1)
  local matcher = switch[first_char]

  return matcher and matcher(dir, pattern:sub(2)) or M.has(dir, pattern)
end

function M.root_included(dir)
  Util.validate({ dir = { dir, { 'string' } } })

  while true do
    for _, pattern in ipairs(Config.options.patterns) do
      local excluded = false
      if pattern:sub(1, 1) == '!' then
        excluded, pattern = true, pattern:sub(2)
      end

      if M.match(dir, pattern) then
        if not excluded then
          return dir, ('pattern %s'):format(pattern)
        end
        break
      end
    end

    local parent = M.get_parent(dir)
    if not parent or parent == dir then
      return nil
    end
    if Util.is_windows() and parent:match('^%a:$') then
      return nil
    end

    dir = parent
  end
end

return M
