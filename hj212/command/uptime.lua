local base = require 'hj212.command.base'
local types = require 'hj212.types'

local cmd = base:subclass('hj212.command.uptime')

function cmd:initialize(data_time, restart_time)
	local data_time = data_time or os.time()
	base.initialize(types.COMMAND.UPTIME, {
		DataTime = data_time,
		RestartTime = restart_time,
	})
end

return cmd
