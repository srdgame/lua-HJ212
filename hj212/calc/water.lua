local base = require 'hj212.calc.simple'
local mgr = require 'hj212.calc.manager'
local flow = require 'hj212.calc.water.flow'
local pollut = require 'hj212.calc.water.pollut'

local water = base:subclass('hj212.calc.water')

function water:initialize(station, id, type_mask, min, max, zs_calc)
	base.initialize(self, station, id, type_mask, min, max, zs_calc)

	local min_interval = assert(self._station:min_interval())

	if id ~= 'w00000' then
		self._station:water(function(water)
			if water then
				local water_calc = water:cou_calc()
				self:push_pre_calc(water_calc)

				local calc = pollut:new(self, water_calc, min_interval)
				self:push_value_calc(calc)
			else
				local calc = flow:new(self, min_interval)
				self:push_value_calc(calc)
			end
		end)
	else
		local calc = flow:new(self, min_interval)
		self:push_value_calc(calc)
	end
end

return water
