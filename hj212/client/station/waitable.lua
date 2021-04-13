local class = require 'middleclass'

local waitable = class('hj212.client.station.waitable')

function waitable:initialize(station, poll_id)
	self._station = station
	self._poll_id = poll_id
end

function waitable:poll()
	return self._station:find_poll(self._poll_id)
end

function waitable:value(timeout)
	local timeout = timeout or 10 --- default is ten seconds
	local poll, err = self._station:find_poll(self._poll_id)
	if not poll then
		return nil, "Cannot found this poll"
	end

	local now = os.time()
	-- Ten seconds
	while os.time() - now < timeout do
		local val, timestamp = poll:get_value()
		if val ~= nil then
			return val, timestamp
		end

		self._station:sleep(50) -- 50 ms
	end
	return nil, "Wait for value timeout"
end

return waitable
