local types = require 'hj212.types'
local command = require 'hj212.command.get_meter_info'
local base = require 'hj212.request.base'

local req = base:subclass('hj212.request.get_meter_info')

function req:initialize(need_ack, poll_id, tags)
	local data_time = (tags and #tags > 0) and tags[1]:data_time() or os.time()

	local cmd = command:new(data_time, poll_id)

	for i, v in ipairs(tags or {}) do
		cmd:add_tag(v:data_time(), v)
	end
	base.initialize(self, cmd, need_ack)
end

return req
