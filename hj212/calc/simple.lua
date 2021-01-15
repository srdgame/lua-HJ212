local base = require 'hj212.calc.base'
local mgr = require 'hj212.calc.manager'
local types = require 'hj212.types'

local simple = base:subclass('hj212.calc.simple')

function simple:initialize(station, name, mask, min, max)
	base.initialize(self, station, name, mask, min, max)
end

function simple:push(value, timestamp)
	if timestamp < self._last_calc_time then
		return nil, 'older value skipped ts:'..timestamp..' last:'..self._last_calc_time
	end
	local val = {value = value, timestamp = timestamp}
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

	--self:log('debug', 'simple.calc_sample', val_cou, #list)
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
	local sample_list = self._sample_list
	local last = self._min_list:find(now)
	if last then
		return last
	end

	local start = base.calc_list_stime(sample_list, now, duration)
	while start < (now - duration) do
		local etime = start + duration
		local list = sample_list:pop(etime)

		if self._min_list:find(etime) then
			self:log('error', "SIMPLE: older sample value skipped", etime)
			local cjson = require 'cjson.safe'
			for _, v in pairs(list) do
				self:log('error', ' Skip: '..cjson.encode(v))
			end
		else
			self:log('debug', 'SIMPLE: calculate older sample value', start, etime, #list, list[1].timestamp)
			local val = calc_sample(list, start, etime)
			val = self:on_value(mgr.TYPES.MIN, val, etime)
			self._min_list:append(val)
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	local list = sample_list:pop(now)

	local val = calc_sample(list, start, now)
	val = self:on_value(mgr.TYPES.MIN, val, now)
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
	local sample_list = self._min_list
	local last = self._hour_list:find(now)
	if last then
		return last
	end

	local start = base.calc_list_stime(sample_list, now, duration)
	while start < (now - duration) do
		local etime = start + duration
		local list = sample_list:pop(etime)

		if self._hour_list:find(etime) then
			self:log('error', "SIMPLE: older min value skipped")
			local cjson = require 'cjson.safe'
			for _, v in pairs(list) do
				self:log('error', ' Skip: '..cjson.encode(v))
			end
		else
			self:log('debug', 'SIMPLE: calculate older min value', start, etime, #list, list[1].stime)
			local val = calc_cou(list, start, etime)
			val = self:on_value(mgr.TYPES.HOUR, val, etime)
			assert(self._hour_list:append(val))
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	local list = sample_list:pop(now)

	local val = calc_cou(list, start, now)
	val = self:on_value(mgr.TYPES.HOUR, val, now)
	assert(self._hour_list:append(val))

	return val
end

function simple:on_day_trigger(now, duration)
	local sample_list = self._hour_list
	local last = self._day_list:find(now)
	if last then
		return last
	end

	local start = base.calc_list_stime(sample_list, now, duration)
	while start < (now - duration) do
		local etime = start + duration
		local list = sample_list:pop(etime)

		if self._day_list:find(etime) then
			self:log('error', "SIMPLE: older hour value skipped")
			local cjson = require 'cjson.safe'
			for _, v in pairs(list) do
				self:log('error', ' Skip: '..cjson.encode(v))
			end
		else
			self:log('debug', 'SIMPLE: calculate older hour value', start, etime, #list, list[1].stime)
			local val = calc_cou(list, start, etime)
			val = self:on_value(mgr.TYPES.DAY, val, etime)
			assert(self._day_list:append(val))
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	local list = sample_list:pop(now)

	local val = calc_cou(list, start, now)
	val = self:on_value(mgr.TYPES.DAY, val, now)
	assert(self._day_list:append(val))

	return val
end

return simple
