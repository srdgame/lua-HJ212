local base = require 'hj212.calc.base'
local mgr = require 'hj212.calc.manager'
local types = require 'hj212.types'

local simple = base:subclass('hj212.calc.simple')

function simple:initialize(name, mask, min, max)
	base.initialize(self, name, mask, min, max)
end

function simple:push(value, timestamp)
	local val = {value = value, timestamp = math.floor(timestamp)}
	return self._sample_list:append(val)
end

function simple:sample_meta()
	return {
		{ name = 'value', type = 'DOUBLE', not_null = true },
		{ name = 'timestamp', type = 'DOUBLE', not_null = true },
	}, 1 --version
end

local function calc_sample(list, start, now)
	if #list == 0 then
		return {cou=0,avg=0,min=0,max=0,stime=start,etime=now,flag=types.FLAG.Connection}
	end
	local val_cou = 0
	local val_min = list[1].value
	local val_max = val_min

	for i, v in ipairs(list) do
		local val = v.value
		assert(type(val) == 'number')
		val_min = val < val_min and val or val_min
		val_max = val > val_max and val or val_max

		val_cou = val_cou + val
	end

	--print('simple.calc_sample', val_cou, #list)
	local val_avg = val_cou / #list

	return {
		cou = val_cou,
		avg = val_avg,
		min = val_min,
		max = val_max,
		stime = start,  -- Duration start
		etime = now,	-- Duration end
	}
end

function simple:on_min_trigger(now, duration)
	local now = math.floor(now)
	local sample_list = self._sample_list
	local last = self._min_list:find(now)
	if last then
		return last
	end

	local start = base.calc_list_stime(sample_list, now, duration)
	while start < now - duration do
		local etime = start + duration
		local list = sample_list:pop(etime)

		if self._min_list:find(etime) then
			self:log('error', "SIMPLE: older sample value skipped")
		else
			self:log('debug', 'SIMPLE: calculate older sample value', start, etime)
			local val = calc_sample(list, start, etime)
			val = self:on_value(mgr.TYPES.MIN, val)
			self._min_list:append(val)
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	local list = sample_list:pop(now)

	local val = calc_sample(list, start, now)
	val = self:on_value(mgr.TYPES.MIN, val)
	self._min_list:append(val)

	return val
end

local function calc_cou(list, start, now)
	if #list == 0 then
		return {cou=0,avg=0,min=0,max=0,stime=start,etime=now,flag=types.FLAG.Connection}
	end
	local etime = start
	local val_cou = 0
	local val_t_avg = 0
	local val_min = list[1].min
	local val_max = list[1].max

	for i, v in ipairs(list) do
		assert(v.stime >= start, "Start time issue:"..v.stime..'\t'..start)
		assert(v.etime >= etime, "Last time issue:"..v.etime..'\t'..etime)
		etime = v.etime

		val_min = v.min < val_min and v.min or val_min
		val_max = v.max > val_max and v.max or val_max

		val_cou = val_cou + v.cou
		val_t_avg = val_t_avg + v.avg
	end

	assert(etime <= now, 'etime:'..etime..'\tnow:'..now)

	local val_avg = val_t_avg / #list

	return {
		cou = val_cou,
		avg = val_avg,
		min = val_min,
		max = val_max,
		stime = start,
		etime = now,
	}
end

function simple:on_hour_trigger(now, duration)
	local now = math.floor(now)
	local sample_list = self._min_list
	local last = self._hour_list:find(now)
	if last then
		return last
	end

	local start = base.calc_list_stime(sample_list, now, duration)
	while start < now - duration do
		local etime = start + duration
		local list = sample_list:pop(etime)

		if self._hour_list:find(etime) then
			self:log('error', "SIMPLE: older min value skipped")
		else
			self:log('debug', 'SIMPLE: calculate older min value', start, etime)
			local val = calc_cou(list, start, etime)
			val = self:on_value(mgr.TYPES.HOUR, val)
			assert(self._hour_list:append(val))
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	local list = sample_list:pop(now)

	local val = calc_cou(list, start, now)
	val = self:on_value(mgr.TYPES.HOUR, val)
	assert(self._hour_list:append(val))

	return val
end

function simple:on_day_trigger(now, duration)
	local now = math.floor(now)
	local sample_list = self._hour_list
	local last = self._day_list:find(now)
	if last then
		return last
	end

	local start = base.calc_list_stime(sample_list, now, duration)
	while start < now - duration do
		local etime = start + duration
		local list = sample_list:pop(etime)

		if self._day_list:find(etime) then
			self:log('error', "SIMPLE: older hour value skipped")
		else
			self:log('debug', 'SIMPLE: calculate older min value', start, etime)
			local val = calc_cou(list, start, etime)
			val = self:on_value(mgr.TYPES.DAY, val)
			assert(self._day_list:append(val))
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	local list = sample_list:pop(now)

	local val = calc_cou(list, start, now)
	val = self:on_value(mgr.TYPES.DAY, val)
	assert(self._day_list:append(val))

	return val
end

return simple
