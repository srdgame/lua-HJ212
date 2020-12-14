local class = require 'middleclass'

local meter = class('hj212.client.meter')

function meter:initialize(sn, tags, info)
	assert(sn, 'Device serial number missing')
	assert(tags, 'Device tags missing')
	assert(info, 'Device info missing')
	self._sn = sn
	self._tags = tags
	self._info = info
end

function meter:sn()
	return self._sn
end

function meter:has_tag(name)
	return tags[name]
end

--- Tags value
function meter:set_tag_value(name, value, timestamp)
end

--- XXXXX-Info value
function meter_set_info_value(name, value, timestamp)
end

function meter:rdata()
end

function meter:min_data()
end

function meter:hour_data()
end

function meter:day_data()
end

function meter:sample_data()
end

function meter:info_data()
end

return meter
