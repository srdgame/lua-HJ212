local base = require 'hj212.command.base'
local types = require 'hj212.types'

local reply = base:subclass('hj212.command.reply')

function reply:initialize(result)
	local result = result or types.REPLY.RUN
	base.initialize(types.COMMAND.REPLY, {
		QnRtn = result
	})
end

return reply
