local base = require 'hj212.command.base'
local types = require 'hj212.types'

local cmd = base:subclass('hj212.command.uptime')

function cmd:initialize(timestamp, restart_time)
	local timestamp = timestamp or nil -- optional
	base.initialize(types.COMMAND.UPTIME, {
		DataTime = timestamp,
		RestartTime = restart_time,
	})
end

return cmd
