local base = require 'hj212.command.base'
local types = require 'hj212.types'

local cmd = base:subclass('hj212.command.set_info')

function cmd:initialize(pol_id, info_id)
	local pol_id = pol_id or 'xxxxx'
	local data_time = timestamp or 0
	base.initialize(types.COMMAND.SET_INFO, {
		PolId = pol_id,
		InfoId = info_id,
		-- <InfoId>-Info
	})
end

return cmd
