local types = require 'hj212.types'
local command = require 'hj212.command.data_ack'
local base = require 'hj212.request.base'

local resp = base:subclass('hj212.reply.data_ack')

function resp:initialize()
	local cmd = command:new()
	base.initialize(cmd)
end

return resp
