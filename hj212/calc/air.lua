local base = require 'hj212.calc.simple'
local mgr = require 'hj212.calc.manager'
local pullut = require 'hj212.calc.air.pullut'
local flow = require 'hj212.calc.air.flow'

local air = base:subclass('hj212.calc.air')

function air:initialize(name, type_mask, min, max, pullut_base)
	base.initialize(self, name, type_mask, min, max)
	if pullut_base then
		pullut.initialize(self, base, pullut_base)
	else
		flow.initialize(self, base)
	end
end

return air
