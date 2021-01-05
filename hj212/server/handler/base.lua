local class = require 'middleclass'

local handler = class('hj212.client.handler.set_rdata_interval')

function handler:initialize(client)
	self._client = client
	self._station = client:station()
end

function handler:log(level, ...)
	return self._client:log(level, ...)
end

function handler:__call(...)
	if self.process then
		return self:process(...)
	else
		return nil, "not implemented"
	end
end

function handler:send_request(resp, response)
	return self._client:send_request(resp, response)
end

return handler
