local base = require 'hj212.command.base'
local types = require 'hj212.types'

local cmd = base:subclass('hj212.command.cleanup')

function cmd:initialize(pol_id)
	base.initialize(self, types.COMMAND.CLEANUP, {
		PolId = pol_id
	})
end

return cmd
