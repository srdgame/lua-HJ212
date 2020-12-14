local class = require 'middleclass'

local meter = class('hj212.client.meter')

function meter:initialize(sn, tags)
	assert(sn, 'Device serial number missing')
	assert(tags, 'Device tags missing')
	self._sn = sn
	self._tags = tags
end

function meter:set_tag_value(name, value, timestamp)
end

function meter:rdata()
end

function meter:min_data()
end

function meter:hour_data()
end

function meter:day_data()
end

return meter
