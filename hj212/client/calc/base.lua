local class = require 'middleclass'
local mgr = require 'hj212.client.calc.manager'

local base = class('hj212.client.calc.base')

base.static.TYPES = mgr.static.TYPES

function base:initialize(type_mask)
	self._type_mask = type_mask
end

function base:on_trigger(typ, now)	
	if (self._type_mask & typ) == typ then
		if typ == mgr.TYPES.MIN then
			assert(self.on_min_trigger)
			return self:on_min_trigger(now)
		end
		if typ == mgr.TYPES.HOUR then
			assert(self.on_hour_trigger)
			return self:on_hour_trigger(now)
		end
		if typ == mgr.TYPES.DAY then
			assert(self.on_day_trigger)
			return self:on_day_trigger(now)
		end
	else
		return nil, "Unexpected trigger type"..typ
	end
end
