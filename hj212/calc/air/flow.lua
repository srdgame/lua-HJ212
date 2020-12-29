local air = {}

function air:initialize(base)
	self._base = base
	self._last_rdata_time = os.time() - 5 -- Default 5 seconds
end

function air:on_value(typ, val, now)
	if typ == mgr.TYPES.RDATA then
		assert(now ~= self._last_rdata_time)
		val.value = val.value * (now - self._last_rdata_time)
		self._last_rdata_time = now
	elseif (typ == mgr.TYPES.MIN or typ == mgr.TYPES.HOUR) then
		val.cou = val.avg * (val.stime - val.etime)
	else
		--val.cou  = val.cou
	end

	return self._base.on_value(self, typ, val, now)
end

return air
