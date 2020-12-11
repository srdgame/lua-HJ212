local base = require 'hj212.command.base'
local types = require 'hj212.types'

local cmd = base:subclass('hj212.command.get_device_id')

function cmd:initialize(pol_id, sn)
	local pol_id = pol_id or 'xxxxx'
	local s_time = sn or 'xxxxx-SN'
	base.initialize(types.COMMAND.GET_DEVICE_ID, {
		PolId = pol_id,
		-- xxxxxx-SN
	})
end

return cmd
