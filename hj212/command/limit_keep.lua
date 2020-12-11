local base = require 'hj212.command.base'
local types = require 'hj212.types'

local cmd = base:subclass('hj212.command.limit_keep')

function cmd:initialize(timestamp, vase_no)
	local timestamp = timestamp or nil -- optional
	local vese_no = vese_no or nil
	base.initialize(types.COMMAND.LIMIT_KEEP, {
		DataTime = timestamp,
		VeseNo = vese_no
	})
end

return cmd
