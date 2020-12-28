local class = require 'middleclass'

local waitable = class('hj212.client.station.waitable')

function waitable:initialize(station, tag_name)
	self._station = station
	self._tag_name = tag_name
end

function waitable:value(self, timestamp)
	local tag, err = self._station:find_tag(self._tag_name)
	if not tag then
		return nil, err
	end

	local now = os.time()
	-- Ten seconds
	while os.time() - now < 10 do
		local val, timestamp = self:get_value()
		if val ~= nil then
			return val
		end

		self._station:sleep(100) -- 100 ms
	end
	return nil, "Timeout to get value"
end

return waitable
