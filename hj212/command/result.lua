local base = require 'hj212.command.base'
local types = require 'hj212.types'

local result = base:subclass('hj212.command.result')

function result:initialize(result)
	local result = result or types.RESULT.SUCCESS
	base.initialize(self, types.COMMAND.RESULT, {
		ExeRtn = result
	})
end

return result
