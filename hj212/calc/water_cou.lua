local base = require 'hj212.calc.simple'
local flow = require 'hj212.calc.water.flow'
local flow_cou = require 'hj212.calc.water.flow_cou'

local water = base:subclass('hj212.calc.water')

function water:initialize(station, id, type_mask, min, max, zs_calc)
	base.initialize(self, station, id, type_mask, min, max, zs_calc)

	local min_interval = assert(self._station:min_interval())

	self._station:water(function(cou_poll)
		if cou_poll then
			local cou_calc = cou_poll:cou_calc()
			self:push_pre_calc(cou_calc)

			local calc = flow_cou:new(self, cou_calc, min_interval)
			self:push_value_calc(calc)
		else
			local calc = flow:new(self, min_interval)
			self:push_value_calc(calc)
		end
	end)
end

return water
