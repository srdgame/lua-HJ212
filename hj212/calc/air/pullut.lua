local air = {}

function air:initialize(base, cou_base)
	self._base = base
	self._cou_base = cou_base
end

function air:on_value(typ, val, now)
	local cou_base = self._cou_base
	if not cou_base then
		self:log('debug', 'No COU base')
		return
	end
	local fn = 'query_'..type_name
	assert(cou_base[fn], 'Missing function:'..fn)
	local cou_value = cou_base[fn](cou_base, val.etime)
	if cou_value then
		val.cou = cou_value.cou * val.avg * (10 ^ -6)
	else
		self:log('debug', 'No COU base value')
	end

	return self._base.on_value(self, typ, val, now)
end

function air:trigger_cou(type_name, ...)
	local cou_base = self._cou_base
	if not cou_base then
		return
	end
	local fn = 'on_'..type_name..'_trigger'
	assert(cou_base[fn], 'Missing function:'..fn)
	return cou_base[fn](cou_base, ...)
end

function air:on_min_trigger(now, duration)
	if self._cou_base then
		self._cou_base:on_min_trigger(now, duration)
	end
	return self._base.on_min_trigger(self, now, duration)
end

function air:on_hour_trigger(now, duration)
	if self._cou_base then
		self._cou_base:on_hour_trigger(now, duration)
	end
	return self._base.on_hour_trigger(self, now, duration)
end

function air:on_day_trigger(now, duration)
	if self._cou_base then
		self._cou_base:on_day_trigger(now, duration)
	end
	return self._base.on_day_trigger(self, now, duration)
end

return air
