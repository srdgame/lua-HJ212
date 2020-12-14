local types = require 'hj212.types'
local command = require 'hj212.command.result'
local base = require 'hj212.request.base'

local resp = base:subclass('hj212.reply.result')

function resp:initialize(result_status)
	local cmd = command:new(result_status)
	base.initialize(cmd)
end

return resp
