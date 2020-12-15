local base = require 'hj212.client.handler.base'
local command = require 'hj212.command.get_time'
local reply = require 'hj212.reply.base'

local handler = base:subclass('hj212.client.handler.get_time')

function handler:process(request)
	local params = request:params()
	local val, err = params:get('PolId')
	if val == nil then
		return nil, err
	end

	self:log('debug', "Get device time for:"..val)

	local now = os.time()
	if self._client.get_time then
		now = self._client:get_time(val)
	end

	local resp = reply:new(command:new(val, now))

	return self:send_reply(resp)
end

return handler
