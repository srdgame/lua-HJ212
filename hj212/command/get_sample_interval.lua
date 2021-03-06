local base = require 'hj212.command.base'
local types = require 'hj212.types'

local cmd = base:subclass('hj212.command.get_sample_interval')

function cmd:initialize(pol_id, c_start_time, c_time)
	local c_start_time = c_start_time or 0
	local c_time = c_time or 2
	base.initialize(self, types.COMMAND.GET_SAMPLE_INTERVAL, {
		PolId = pol_id,
		CstartTime = c_start_time,
		Ctime = c_time,
	})
end

return cmd
