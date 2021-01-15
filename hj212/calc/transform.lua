local base = require 'hj212.calc.base'
local mgr = require 'hj212.calc.manager'
local types = require 'hj212.types'

local trans = base:subclass('hj212.calc.transform')

--- calc_base the calc_base tag name
function trans:initialize(station, name, type_mask, min, max, calc_base, calc_func)
	base.initialize(self, station, name, type_mask, min, max)
	local tag_base = self._station:wait_tag(calc_base, function(tag)
		self._calc_base = tag and tag:cou_calc()
	end)
	self._calc_func = calc_func
end

function trans:push(value, timestamp)
	assert(false, "This should not sample data")
	return true
end

function trans:sample_meta()
	return {
		{ name = 'value', type = 'DOUBLE', not_null = true },
		{ name = 'timestamp', type = 'DOUBLE', not_null = true },
	}, 1 --version
end

function trans:on_value(typ, val, now)
	if type == mgr.TYPES.RDATA then
		val.value = self._calc_func(val.value, 'RDATA')
	else
		val.cou = self._calc_func(val.cou, 'COU')
		val.avg = self._calc_func(val.cou, 'AVG')
		val.min = self._calc_func(val.cou, 'MIN')
		val.max = self._calc_func(val.cou, 'MAX')
	end
	return base.on_value(self, typ, val, now)
end

function trans:on_min_trigger(now, duration)
	assert(self._calc_base)
	local val = self._calc_base:on_min_trigger(now, druation)
	val = self:on_value(mgr.TYPES.MIN, val, now)
	self._min_list:append(val)
	return val
end

function trans:on_hour_trigger(now, duration)
	assert(self._calc_base)
	local val = self._calc_base:on_hour_trigger(now, druation)
	val = self:on_value(mgr.TYPES.HOUR, val, now)
	self._hour_list:append(val)
	return val
end

function trans:on_day_trigger(now, duration)
	assert(self._calc_base)
	local val = self._calc_base:on_day_trigger(now, druation)
	val = self:on_value(mgr.TYPES.DAY, val, now)
	self._day_list:append(val)
	return val
end

return trans
