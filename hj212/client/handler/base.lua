local class = require 'middleclass'

local handler = class('hj212.client.handler.set_rdata_interval')

function handler:initialize(client)
	self._client = client
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

return handler
