local base = require 'hj212.command.base'
local types = require 'hj212.types'

local cmd = base:subclass('hj212.command.status_start')

function cmd:initialize()
	base.initialize(types.COMMAND.STATUS_START, {})
end

return cmd
