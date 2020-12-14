local types = require 'hj212.types'
local command = require 'hj212.command.notice'
local base = require 'hj212.request.base'

local resp = base:subclass('hj212.reply.notice')

function resp:initialize()
	local cmd = command:new()
	base.initialize(cmd)
end

return resp
