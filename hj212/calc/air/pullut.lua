local mgr = require 'hj212.calc.manager'
local base = require 'hj212.calc.base'

local air = {}

function air:on_value(typ, val, now)
	if typ == mgr.TYPES.RDATA then
		return self._wrap.on_value(self, typ, val, now)
	end

	local cou_base = self._wrap.cou_base
	local type_name = base.TYPE_NAMES[typ]
	local fn = 'query_'..string.lower(type_name)
	assert(cou_base[fn], 'Missing function:'..fn)
	local cou_value = cou_base[fn](cou_base, val.etime)
	if cou_value then
		val.cou = cou_value.cou * val.avg * (10 ^ -6)
	else
		self:log('debug', 'No COU base value')
	end

	return self._wrap.on_value(self, typ, val, now)
end

function air:on_min_trigger(now, duration)
	if self._wrap.cou_base then
		self._wrap.cou_base:on_min_trigger(now, duration)
	end
	return self._wrap.on_min_trigger(self, now, duration)
end

function air:on_hour_trigger(now, duration)
	if self._wrap.cou_base then
		self._wrap.cou_base:on_hour_trigger(now, duration)
	end
	return self._wrap.on_hour_trigger(self, now, duration)
end

function air:on_day_trigger(now, duration)
	if self._wrap.cou_base then
		self._wrap.cou_base:on_day_trigger(now, duration)
	end
	return self._wrap.on_day_trigger(self, now, duration)
end

return function(obj, cou_base)
	assert(obj._wrap == nil)
	local wrap = {
		base = self,
		cou_base = assert(cou_base)
	}

	for k, v in pairs(air) do
		if k ~= 'initialize' then
			wrap[k] = obj[k]
			obj[k] = v
		end
	end
	obj._wrap = wrap

	return obj
end
