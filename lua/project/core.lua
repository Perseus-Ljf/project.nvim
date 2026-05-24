local Config = require('project.config')
local Util = require('project.util')

local uv = vim.uv or vim.loop

local M = {
  current_project = nil,
  current_method = nil,
}

function M.check_oil(bufnr)
  Util.validate({ bufnr = { bufnr, { 'number', 'nil' }, true } })
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local ok, oil = pcall(require, 'oil')
  local dir = ok and oil and oil.get_current_dir and oil.get_current_dir(bufnr) or bufname:gsub('^oil://', '')

  return dir ~= '' and Util.strip_slash(dir) or nil
end

function M.find_pattern_root(bufnr)
  Util.validate({ bufnr = { bufnr, { 'number', 'nil' }, true } })
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local dir = M.check_oil(bufnr) or vim.api.nvim_buf_get_name(bufnr)
  if dir == '' then
    return nil
  end

  dir = vim.fn.isdirectory(dir) == 1 and dir or Util.strip_slash(dir, ':p:h')
  dir = Util.is_windows() and dir:gsub('\\', '/') or dir

  return Util.path.root_included(dir)
end

function M.get_project_root(bufnr)
  Util.validate({ bufnr = { bufnr, { 'number', 'nil' }, true } })
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not Util.buffer_valid(bufnr) then
    return nil
  end

  return M.find_pattern_root(bufnr)
end

function M.get_current_project(bufnr)
  local root, method = M.get_project_root(bufnr)
  return root, method
end

function M.valid_bt(bufnr)
  Util.validate({ bufnr = { bufnr, { 'number', 'nil' }, true } })
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  return Util.buffer_valid(bufnr)
    and not vim.list_contains(Config.options.disable_on.bt, Util.optget('buftype', 'buf', bufnr))
end

function M.set_pwd(dir, method)
  Util.validate({
    dir = { dir, { 'string', 'nil' }, true },
    method = { method, { 'string', 'nil' }, true },
  })

  if not dir or not method then
    return false
  end

  dir = Util.strip_slash(dir)
  if not Util.path.exists(dir) then
    return false
  end

  if dir == Util.strip_slash(uv.cwd() or vim.fn.getcwd()) then
    M.current_project = dir
    M.current_method = method
    return true
  end

  local scope = Config.options.scope_chdir
  local ok = pcall(
    scope == 'global' and vim.api.nvim_set_current_dir or (scope == 'tab' and vim.cmd.tchdir or vim.cmd.lchdir),
    dir
  )

  if ok then
    M.current_project = dir
    M.current_method = method
  elseif not Config.options.silent_chdir then
    vim.notify(('project.nvim: failed to change directory to `%s`'):format(dir), vim.log.levels.ERROR)
  end

  return ok
end

function M.on_buf_enter(bufnr)
  Util.validate({ bufnr = { bufnr, { 'number', 'nil' }, true } })
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not M.valid_bt(bufnr) then
    return
  end

  if vim.list_contains(Config.options.disable_on.ft, Util.optget('filetype', 'buf', bufnr)) then
    return
  end

  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local dir = M.check_oil(bufnr) or (bufname ~= '' and Util.strip_slash(bufname, ':p:h') or nil)
  if not dir or Util.path.is_excluded(Util.is_windows() and dir:gsub('\\', '/') or dir) then
    return
  end

  local root, method = M.get_project_root(bufnr)
  M.set_pwd(root, method)
end

function M.setup()
  local group = vim.api.nvim_create_augroup('project.nvim', { clear = true })

  if not Config.options.manual_mode then
    vim.api.nvim_create_autocmd('BufEnter', {
      group = group,
      callback = function(ev)
        M.on_buf_enter(ev.buf)
      end,
    })
  end
end

return M
