local base = require 'hj212.command.base'
local types = require 'hj212.types'

local cmd = base:subclass('hj212.command.get_meter_sn')

function cmd:initialize(pol_id, sn)
	local data = {
		PolId = pol_id
	}
	if pol_id and sn then
		data[pol_id..'-SN'] = sn
	end

	base.initialize(self, types.COMMAND.GET_METER_SN, data)
end

return cmd
