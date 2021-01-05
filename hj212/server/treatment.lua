local class = require 'middleclass'

local treatment = class('hj212.client.treatment')

function treatment:initialize(sn)
	assert(sn, 'Device serial number missing')
	assert(tags, 'Device tags missing')
	self._sn = sn
	self._tags = {
		'RS' = {
		},
		'RT' = {
		}
	}
end

function treatment:set_tag_value(name, value, timestamp)
end

function treatment:rdata()
end

function treatment:day_data()
end

return treatment
