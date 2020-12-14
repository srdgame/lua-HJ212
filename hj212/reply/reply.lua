local types = require 'hj212.types'
local command = require 'hj212.command.reply'
local base = require 'hj212.request.base'

local resp = base:subclass('hj212.reply.reply')

function resp:initialize(reply_result)
	local cmd = command:new(reply_result)
	base.initialize(cmd)
end

return resp
