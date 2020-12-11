local base = require 'hj212.command.base'
local types = require 'hj212.types'

local cmd = base:subclass('hj212.command.day_status')

function cmd:initialize(timestamp, begin_time, end_time)
	local timestamp = timestamp or nil -- optional
	base.initialize(types.COMMAND.DAY_STATUS, {
		DataTime = timestamp,
		BeginTime = begin_time,
		EndTime = end_time,
	})
end

return cmd
