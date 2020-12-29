local base = require 'hj212.calc.base'
local mgr = require 'hj212.calc.manager'
local types = require 'hj212.types'

local simple = base:subclass('hj212.calc.simple')

function simple:initialize(name, mask, min, max)
	base.initialize(self, name, mask, min, max)
end

function simple:push(value, timestamp)
	local val = {value, math.floor(timestamp)}
	table.insert(self._sample_list, val)
	self:push_sample(val)
end

function simple:sample_meta()
	return {
		{ name = 'value', type = 'DOUBLE', not_null = true },
		{ name = 'timestamp', type = 'DOUBLE', not_null = true },
	}
end

local function calc_list(list, start, now)
	if #list == 0 then
		return {cou=0,avg=0,min=0,max=0,stime=start,etime=now,flag=types.FLAG.Connection}
	end
	local val_cou = 0
	local val_min = list[1][1]
	local val_max = list[1][1]

	for i, v in ipairs(list) do
		local val = v[1]
		assert(type(val) == 'number')
		val_min = val < val_min and val or val_min
		val_max = val > val_max and val or val_max

		val_cou = val_cou + val
	end

	--print('simple.calc_list', val_cou, #list)
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
	local list = self._sample_list
	local last = self._min_list[#self._min_list]
	if last and last.etime >= now then
		assert(now == last.etime, "Last end time not equal to now")
		return last
	end

	self._sample_list = {}

	while #list > 0 and list[#list][2] > now do
		self:log('debug', 'Push later items into samples list', list[#list][2], now)
		table.insert(self._sample_list, 1, list[#list])
		table.remove(list, #list)
	end

	while #list > 0 and list[1][2] < (now - duration) do
		local etime = now - duration
		local item_start = list[1][2]
		while etime - duration > item_start do
			etime = etime - duration
		end
		local start = etime - duration

		local old_list = {}
		local new_list = {}
		for i, v in ipairs(list) do
			if v[2] < etime then
				old_list[#old_list + 1] = v
			else
				new_list[#new_list + 1] = v
			end
		end
		assert(#old_list > 0)
		list = new_list

		self:log('debug', 'SIMPLE: calculate older min value', start, etime)
		local val = calc_list(old_list, start, etime)
		table.insert(self._min_list, val)
		self:on_value(mgr.TYPES.MIN, val, etime)
	end

	local start = now - duration

	local val = calc_list(list, start, now)

	table.insert(self._min_list, val)

	return val
end

local function calc_list_2(list, start, now)
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
	local list = self._min_list
	local last = self._hour_list[#self._hour_list]
	if last and last.etime >= now then
		assert(now == last.etime, "Last end time not equal to now")
		return last
	end

	self._min_list = {}

	while #list > 0 and list[#list].etime > now do
		self:log('debug', 'Push later items into min list', list[#list].etime, now)
		table.insert(self._min_list, 1, list[#list])
		table.remove(list, #list)
	end

	--- If the first item timestamp not in current duration
	while #list > 0 and list[1].stime < (now - duration) do
		local etime = now - duration
		local item_start = list[1].stime
		while etime - duration > item_start do
			etime = etime - duration
		end
		local start = etime - duration

		local old_list = {}
		local new_list = {}
		for i, v in ipairs(list) do
			if v.stime < etime then
				old_list[#old_list + 1] = v
			else
				new_list[#new_list + 1] = v
			end
		end
		assert(#old_list > 0)
		list = new_list

		self:log('debug', 'SIMPLE: calculate older hour value', start, etime)
		local val = calc_list_2(old_list, start, etime)
		table.insert(self._min_list, val)
		self:on_value(mgr.TYPES.HOUR, val, etime)
	end

	local start = now - duration

	local val = calc_list_2(list, start, now)

	table.insert(self._hour_list, val)

	return val
end

function simple:on_day_trigger(now, duration)
	local now = math.floor(now)
	if self._day and self._day.etime == now then
		assert(now == last.etime, "Last end time not equal to now")
		return self._day
	end

	local list = self._hour_list

	self._hour_list = {}

	local start = self._day and self._day.etime or (now - duration)

	local val = calc_list_2(list, start, now)

	self._day = val

	return val
end

return simple
