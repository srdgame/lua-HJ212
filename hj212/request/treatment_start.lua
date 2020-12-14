local types = require 'hj212.types'
local command = require 'hj212.command.treatment_start'
local base = require 'hj212.request.base'

local req = base:subclass('hj212.request.treatment_start')

function req:initialize(status, need_ack)
	local cmd = command:new()
	for i, v in ipairs(status or {}) do
		cmd:add_device(v:data_time(), v)
	end
	base.initialize(cmd, need_ack)
end

return req
