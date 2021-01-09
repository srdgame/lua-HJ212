local air = {}

function air.initialize(self)
	self._last_rdata_time = os.time() - 5 -- Default 5 seconds

	-- replace methods
	for k, v in pairs(air) do
		if k ~= 'initialize' then
			self[k] = v
		end
	end
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

	return self.class.on_value(self, typ, val, now)
end

return air
