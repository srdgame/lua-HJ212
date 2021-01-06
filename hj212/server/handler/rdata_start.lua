local base = require 'hj212.client.handler.base'

local handler = base:subclass('hj212.client.handler.rdata_start')

function handler:process(request)
	local params = request:params()
	if not params then
		return nil, "Params missing"
	end

	local interval, err = params:get('RtdInterval')
	interval = tonumber(interval)
	if interval == nil then
		return nil, err
	end

	self:log('debug', "Set RData interval to "..interval)

	if self._client.set_rdata_interval then
		self._client:set_rdata_interval(interval)
	else
		return nil, "Client does not support changing rdata interval"
	end

	return true
end

return handler
