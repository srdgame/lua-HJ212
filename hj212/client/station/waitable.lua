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
	return tag:wait(timestamp)
end

return waitable
