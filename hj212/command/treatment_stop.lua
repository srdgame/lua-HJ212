local base = require 'hj212.command.base'
local types = require 'hj212.types'

local cmd = base:subclass('hj212.command.treatment_stop')

function cmd:initialize()
	base.initialize(self, types.COMMAND.TREATMENT_STOP, {})
end

return cmd
