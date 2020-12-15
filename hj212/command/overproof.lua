local base = require 'hj212.command.base'
local types = require 'hj212.types'

local cmd = base:subclass('hj212.command.limit_keep')

function cmd:initialize(data_time, vase_no)
	local data_time = data_time or nil -- optional
	local vese_no = vese_no or nil
	base.initialize(self, types.COMMAND.OVERPROOF, {
		DataTime = data_time,
		VeseNo = vese_no
	})
end

return cmd
