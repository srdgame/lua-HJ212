local base = require 'hj212.calc.simple'
local mgr = require 'hj212.calc.manager'
local pullut = require 'hj212.calc.air.pullut'
local flow = require 'hj212.calc.air.flow'

local air = base:subclass('hj212.calc.air')

function air:initialize(station, name, type_mask, min, max)
	base.initialize(self, station, name, type_mask, min, max)
	if name ~= 'a00000' then
		self._station:air(function(air)
			if air then
				pullut(self, air:cou_calc())
			else
				flow(self)
			end
		end)
	else
		flow(self)
	end
end

return air
