local M = {}

function M.validate(specs)
  local max = vim.fn.has('nvim-0.11') == 1 and 3 or 4
  for name, spec in pairs(specs) do
    while #spec > max do
      table.remove(spec, #spec)
    end

    if max == 3 then
      table.insert(spec, 1, name)
      vim.validate(unpack(spec))
    else
      specs[name] = spec
    end
  end

  if max ~= 3 then
    vim.validate(specs)
  end
end

function M.buffer_valid(bufnr)
  M.validate({ bufnr = { bufnr, { 'number' } } })

  return vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr)
end

function M.vim_has(feature)
  M.validate({ feature = { feature, { 'string' } } })

  return vim.fn.has(feature) == 1
end

function M.is_windows()
  return M.vim_has('win32')
end

function M.is_type(t, value)
  M.validate({ t = { t, { 'string' } } })

  return value ~= nil and type(value) == t
end

function M.is_int(value, condition)
  M.validate({
    value = { value, { 'number' } },
    condition = { condition, { 'boolean', 'nil' }, true },
  })

  return value == math.floor(value) and value == math.ceil(value) and (condition == nil or condition)
end

function M.lstrip(char, str)
  M.validate({
    char = { char, { 'string' } },
    str = { str, { 'string' } },
  })

  while vim.startswith(str, char) and char ~= '' do
    str = str:sub(char:len() + 1)
  end

  return str
end

function M.rstrip(char, str)
  M.validate({
    char = { char, { 'string' } },
    str = { str, { 'string' } },
  })

  while str:sub(-char:len()) == char and char ~= '' do
    str = str:sub(1, -(char:len() + 1))
  end

  return str
end

function M.strip_slash(path, mods)
  M.validate({
    path = { path, { 'string' } },
    mods = { mods, { 'string', 'nil' }, true },
  })

  local separator = M.is_windows() and '\\' or '/'
  return M.rstrip(separator, vim.fn.fnamemodify(path, mods and mods ~= '' and mods or ':p'))
end

function M.optget(option, scope, value)
  M.validate({
    option = { option, { 'string' } },
    scope = { scope, { 'string' } },
    value = { value, { 'string', 'number', 'nil' }, true },
  })

  return vim.api.nvim_get_option_value(option, { [scope] = value })
end

function M.dir_exists(dir)
  M.validate({ dir = { dir, { 'string' } } })

  return vim.fn.isdirectory(dir) == 1
end

function M.path_exists(path)
  M.validate({ path = { path, { 'string' } } })

  return M.dir_exists(path) or vim.fn.filereadable(path) == 1
end

local Util = setmetatable(M, {
  __index = function(self, key)
    local ok, module = pcall(require, 'project.util.' .. key)
    if ok then
      return module
    end

    return rawget(self, key)
  end,
})

return Util
