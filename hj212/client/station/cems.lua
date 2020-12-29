local class = require 'middleclass'
local waitable = require 'hj212.client.station.waitable'
local cems = class('hj212.client.station.cems')

local tag_map = {
	Ba = 'a01006',
	Ps = 'a01013',
	ts = 'a01012',
	Kv = 'Kv',
	Vp = 'a01011',
	F = 'a01016',
	Xsw = 'a01014',
}

local value_rate = {
	Ba = 1000,
	Ps = 1000,
	Xsw = 0.01,
}

function cems:initialize(station)
	self._station = station

	for k, v in pairs(tag_map) do
		local wtag = waitable:new(station, v)
		local rate = value_rate[k]

		self[k] = function(self)
			local value, err = wtag:value()
			if not value then
				return nil, err
			end
			if rate then
				return value * rate
			else
				return value
			end
		end
	end
end

return cems
