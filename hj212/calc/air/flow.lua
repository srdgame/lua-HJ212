local mgr = require 'hj212.calc.manager'

local air = {}

function air:on_value(typ, val, now)
	if typ == mgr.TYPES.RDATA then
		assert(now ~= self._wrap.last_rdata_time)
		val.value = val.value * (now - self._wrap.last_rdata_time)
		self._wrap.last_rdata_time = now
	elseif (typ == mgr.TYPES.MIN or typ == mgr.TYPES.HOUR) then
		val.cou = val.avg * (val.stime - val.etime)
	else
		--val.cou  = val.cou
	end

	return self._wrap.on_value(self, typ, val, now)
end

return function(obj)
	assert(obj._wrap == nil)

	local wrap = {
		last_rdata_time = os.time() - 5 -- Default 5 seconds
	}

	-- replace methods
	for k, v in pairs(air) do
		wrap[k] = obj[k]
		obj[k] = v
	end
	obj._wrap = wrap

	return obj
end
