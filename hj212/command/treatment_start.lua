local base = require 'hj212.command.base'
local types = require 'hj212.types'

local cmd = base:subclass('hj212.command.treatment_start')

function cmd:initialize()
	base.initialize(self, types.COMMAND.TREATMENT_START, {})
end

return cmd
