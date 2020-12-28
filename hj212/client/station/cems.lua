local class = require 'middleclass'
local cems = class('hj212.client.station.cems')

local tag_map = {
	Ba = 'a01006',
	Ps = 'a01013',
	ts = 'a01012',
	Kv = 'Kv',
	Vp = 'a01011',
	F = 'a01016',
}

function cems:initialize(station)
	self._station = station
end

for k, v in pairs(tag_map) do
	cems[k] = function(self)
		local tag = self._station:find_tag(v)
		if tag then
			return tag:get_value()
		end
	end
end

return cems
