local base = require 'hj212.client.handler.base'
local types = require 'hj212.types'

local handler = base:subclass('hj212.client.handler.min_data')

function handler:process(request)
	local params = request:params()
	local stime, err = params:get('BeginTime')
	if not stime  then
		return nil, err
	end
	local etime, err = params:get('EndTime')
	if not etime then
		return nil, err
	end

	self:log('info', "Get MIN data from: "..stime.." to "..etime)

	return self._client:handle(types.COMMAND.MIN_DATA, stime, etime, true)
end

return handler
