local base = require 'hj212.calc.simple'
local mgr = require 'hj212.calc.manager'
local flow = require 'hj212.calc.air.flow'
local pollut = require 'hj212.calc.air.pollut'

local air = base:subclass('hj212.calc.air')

function air:initialize(station, id, type_mask, min, max, zs_calc)
	base.initialize(self, station, id, type_mask, min, max, zs_calc)
	if id ~= 'a00000' then
		self._station:air(function(air)
			if air then
				local air_calc = air:cou_calc()
				self:push_pre_calc(air_calc)
				local calc = pollut:new(self, air_calc)
				self:push_value_calc(calc)
			else
				self:push_value_calc(flow:new(self))
			end
		end)
	else
		self:push_value_calc(flow:new(self))
	end
end

return air
