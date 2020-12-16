local base = require 'hj212.client.handler.base'

local handler = base:subclass('hj212.client.handler.set_rdata_interval')

function handler:process(request)
	local params = request:params()
	local interval, err = params:get('RtdInterval')
	interval = tonumber(interval)
	if interval == nil then
		return nil, err
	end

	self:log('debug', "Set RData interval to "..interval)

	return self._client:handle(types.COMMAND.SET_RDATA_INTERVAL, interval)
end

return handler
