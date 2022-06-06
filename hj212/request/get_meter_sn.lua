local types = require 'hj212.types'
local command = require 'hj212.command.get_meter_sn'
local base = require 'hj212.request.base'

local req = base:subclass('hj212.request.upload_meter_sn')

function req:initialize(need_ack, tags)
	local cmd = command:new()
	for i, v in ipairs(tags or {}) do
		if v:data_time() then
			cmd:add_tag(v:data_time(), v)
		else
			-- TODO: alert this
		end
	end
	base.initialize(self, cmd, need_ack)
end

return req
