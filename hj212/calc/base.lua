local class = require 'middleclass'
local mgr = require 'hj212.calc.manager'

local base = class('hj212.calc.base')

base.static.TYPES = mgr.static.TYPES

function base:initialize(callback)
	self._callback = callback
end

function base:push(value, timestamp)
	assert(nil, "Not implemented")
end

function base:set_mask(mask)
	self._type_mask = mask
end

function base:on_trigger(typ, now)	
	if (self._type_mask & typ) == typ then
		if typ == mgr.TYPES.MIN then
			assert(self.on_min_trigger)
			local val = self:on_min_trigger(now)
			self._callback(mgr.TYPES.MIN, val)
		end
		if typ == mgr.TYPES.HOUR then
			assert(self.on_hour_trigger)
			local val = self:on_hour_trigger(now)
			self._callback(mgr.TYPES.HOUR, val)
		end
		if typ == mgr.TYPES.DAY then
			assert(self.on_day_trigger)
			local val = self:on_day_trigger(now)
			self._callback(mgr.TYPES.DAY, val)
		end
	else
		return nil, "Unexpected trigger type"..typ
	end
end

return base
