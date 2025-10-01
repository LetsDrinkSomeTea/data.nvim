local actions = require("data.core.actions")
local state = require("data.core.state")

local M = {}

local function with_current_session(callback)
  local session = state.current()
  if not session then
    vim.notify("data.nvim: no active session", vim.log.levels.WARN)
    return
  end
  callback(session)
end

local function session_completion()
  local results = {}
  for _, entry in ipairs(actions.list_sessions()) do
    results[#results + 1] = entry.id
  end
  return results
end

local function cycle_sessions(offset)
  local sessions = actions.list_sessions()
  if #sessions == 0 then
    vim.notify("data.nvim: no open tables", vim.log.levels.WARN)
    return
  end

  local current_index = 1
  for index, entry in ipairs(sessions) do
    if entry.current then
      current_index = index
      break
    end
  end

  local count = #sessions
  local target = ((current_index - 1 + offset) % count) + 1
  actions.switch(sessions[target].id)
end

local function parse_count(value)
  local number = tonumber(value)
  if not number or number < 1 then
    return 1
  end
  return math.floor(number)
end

function M.setup(opts)
  opts = opts or {}

  if vim.g.loaded_data_commands then
    return
  end
  vim.g.loaded_data_commands = true

  vim.api.nvim_create_user_command("DataOpen", function(command_opts)
    actions.open(command_opts.args, { enter = true })
  end, {
    nargs = 1,
    complete = "file",
  })

  vim.api.nvim_create_user_command("DataSwitch", function(command_opts)
    local id = command_opts.args
    if id == "" then
      vim.notify("data.nvim: session id required", vim.log.levels.WARN)
      return
    end
    actions.switch(id)
  end, {
    nargs = 1,
    complete = function()
      return session_completion()
    end,
  })

  vim.api.nvim_create_user_command("DataNext", function(command_opts)
    local step = parse_count(command_opts.args)
    cycle_sessions(step)
  end, {
    nargs = "?",
  })

  vim.api.nvim_create_user_command("DataPrev", function(command_opts)
    local step = parse_count(command_opts.args)
    cycle_sessions(-step)
  end, {
    nargs = "?",
  })

  vim.api.nvim_create_user_command("DataMove", function(command_opts)
    local direction = command_opts.fargs[1]
    if not direction then
      vim.notify("data.nvim: direction required (up/down/left/right)", vim.log.levels.WARN)
      return
    end
    local count = parse_count(command_opts.fargs[2])
    with_current_session(function(session)
      actions.move(session, direction, count)
    end)
  end, {
    nargs = "+",
  })

  vim.api.nvim_create_user_command("DataPage", function(command_opts)
    local delta = tonumber(command_opts.args) or 1
    with_current_session(function(session)
      actions.page(session, delta)
    end)
  end, {
    nargs = "?",
  })

  vim.api.nvim_create_user_command("DataJump", function(command_opts)
    local row = tonumber(command_opts.fargs[1])
    local col = tonumber(command_opts.fargs[2])
    with_current_session(function(session)
      actions.jump(session, row, col)
    end)
  end, {
    nargs = "*",
  })

  vim.api.nvim_create_user_command("DataSave", function()
    with_current_session(function(session)
      actions.save(session)
    end)
  end, {
    nargs = 0,
  })
end

return M
