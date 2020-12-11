local types = require 'hj212.types'
local command = require 'hj212.command.day_data'
local base = require 'hj212.request.base'

local req = base:subclass('hj212.request.upload_day_data')

function req:initialize(client, need_ack, tags)
	local cmd = command:new()
	for i, v in ipairs(tags) do
		cmd:add_tag(v:data_time(), v)
	end
	base.initialize(client, command, need_ack)
end

return req
