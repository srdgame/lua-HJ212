local base = require 'hj212.command.base'
local types = require 'hj212.types'

local cmd = base:subclass('hj212.command.set_min_interval')

function cmd:initialize(interval)
	base.initialize(self, types.COMMAND.GET_MIN_INTERVAL, {
		MinInterval = interval
	})
end

return cmd
