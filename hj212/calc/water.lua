local base = require 'hj212.calc.base'
local mgr = require 'hj212.calc.manager'
local types = require 'hj212.types'

local water = base:subclass('hj212.calc.water')

local MAX_TIMESTAMP_GAP = 5 -- tenseconds

--- The upper tag, e.g. [w00000]
-- If the upper tag not exists time will be used for caclue the (COU) value
--
function water:initialize(name, mask, min, max, upper_tag)
	base.initialize(self, name, mask, min, max)

	self._last = os.time() - 5 -- five seconds
	self._last_avg = nil
	self._upper = upper_tag

	--- If we are waited by other tags
	self._value = nil
	self._timestamp = 0
	self._waiting = {}
end

function water:push(value, timestamp)
	local timestamp = math.floor(timestamp)
	assert(timestamp)
	if self._upper then
		self._upper:get_value(timestamp, function(upper_value)
			self:_push(upper_value, value, timestamp)
		end)
	else
		local t = timestamp - self._last
		self:_push(t, value, timestamp)
	end
end

function water:_push(bvalue, value, timestamp)
	if timestamp <= self._last then
		return -- TODO:
	end

	local val = bvalue * value * (10 ^ -3)

	local sample = {val, value, timestamp}
	table.insert(self._sample_list, sample)
	self:push_sample(sample)

	self._last_avg = (val) / (timestamp - self._last)
	self._last = timestamp

	self._value = val
	self._timestamp = timestamp

	if #self._waiting == 0 then
		return
	end

	for _, v in ipairs(self._waiting) do
		if math.abs(v.timestamp - timestamp) < MAX_TIMESTAMP_GAP then
			v.callback(val)
		end
	end
	self._waiting = {}
end

function water:sample_meta()
	return {
		{ name = 'val', type = 'DOUBLE', not_null = true },
		{ name = 'value', type = 'DOUBLE', not_null = true },
		{ name = 'timestamp', type = 'DOUBLE', not_null = true },
	}
end

function water:get_value(timestamp, val_calc)
	if math.abs(self._timestamp - timestamp) < MAX_TIMESTAMP_GAP then
		return val_calc(self._value)
	end

	table.insert(self._waiting, {
		timestamp = timestamp,
		callback = val_calc
	})
end

local function calc_list(upper, upper_val, list, start, now, last, last_avg)
	if (upper and not upper_val) or #list == 0 then
		return {cou=0,avg=0,min=0,max=0,stime=start,etime=now,flag=types.FLAG.CONNECTION}
	end
	local val_cou = 0
	local val_min = list[1][2]
	local val_max = list[1][2]

	for i, v in ipairs(list) do
		local val = v[1]
		local raw_val = v[2]
		val_min = raw_val < val_min and raw_val or val_min
		val_max = raw_val > val_max and raw_val or val_max

		val_cou = val_cou + val
	end

	if last and last_avg then
		if last < now then
			val_cou = last_avg * (now - last)
		end
	end

	local val_avg = 0
	if not upper_val then
		val_avg = val_cou / (now - start)
		--print('water.calc_list 1', val_cou, now - start, val_avg, val_min, val_max)
	else
		if upper_val.cou > 0 then
			val_avg = (val_cou / upper_val.cou) * (10 ^ -3)
		else
			val_avg = 0
		end
		--print('water.calc_list 2', val_cou, upper_val.cou, val_avg, val_min, val_max)
	end

	return {
		cou = val_cou,
		avg = val_avg,
		min = val_min,
		max = val_max,
		stime = start,
		etime = now,
	}
end

function water:on_min_trigger(now, duration)
	local now = math.floor(now)
	local list = self._sample_list
	local last = self._min_list[#self._min_list]

	--- if Sample list is empty check whether this tag has ben calculated
	if last and last.etime >= now then
		assert(last.etime == now, "End time is smaller!!!")
		return last
	end

	self._sample_list = {}

	while #list > 0 and list[#list][3] > now do
		self:log('debug', 'Pushing later item into sample list', list[#list][3], now)
		table.insert(self._sample_list, 1, list[#list])
		table.remove(list)
	end

	--- Calculate the upper tag first
	local upper_val =  nil
	if self._upper then
		local val, err = self._upper:on_min_trigger(now)
		if not val then
			self:log('error', 'water:on_min_trigger failed to get upper value', err)
		end
		upper_val = val
	end

	while #list > 0 and list[1][3] < (now - duration) do
		local etime = now - duration
		local item_start = list[1][3]
		while etime - duration > item_start do
			etime = etime - duration
		end
		local start = etime - duration

		local old_list = {}
		local new_list = {}
		local last_time = start
		local last_avg = 0
		for _, v in ipairs(list) do
			if v[3] < etime then
				old_list[#old_list + 1] = v
				last_avg = v[1] / (v[3] - last_time)
				last_time = v[3]
			else
				new_list[#new_list + 1] = v
			end
		end
		assert(#old_list > 0)
		list = new_list

		local upper_val = nil
		if self._upper then
			upper_val = self._upper:query_min(etime)
		end

		self:log('debug', 'WATER: calcuate older min value', start, etime)
		local val = calc_list(self._upper, upper_val, old_list, start, etime, last_time, last_avg)
		table.insert(self._min_list, val)
		self._callback(mgr.TYPES.MIN, val, etime)
	end

	local start = now - duration

	local val = calc_list(self._upper, upper_val, list, start, now, self._last, self._last_avg)

	table.insert(self._min_list, val)

	return val
end

local function calc_list_2(upper, upper_val, list, start, now)
	if (upper and not upper_val) or #list == 0 then
		return {cou=0,avg=0,min=0,max=0,stime=start,etime=now,flag=types.FLAG.CONNECTION}
	end
	local etime = start
	local val_cou = 0
	local val_min = list[1].min
	local val_max = list[2].max

	for _, v in ipairs(list) do
		assert(v.stime >= start, "Start time issue:"..v.stime..'\t'..start)
		assert(v.etime >= etime, "Last time issue:"..v.etime..'\t'..etime)
		etime = v.etime

		val_min = v.min < val_min and v.min or val_min
		val_max = v.max > val_max and v.max or val_max

		val_cou = val_cou + v.cou
	end

	assert(etime <= now)

	local val_avg = 0
	if not upper_val then
		val_avg = val_cou / (now - start)
	else
		if upper_val.cou > 0 then
			val_avg = (val_cou / upper_val.cou) * (10 ^ -3)
		else
			val_avg = 0
		end
	end

	return {
		cou = val_cou,
		avg = val_avg,
		min = val_min,
		max = val_max,
		stime = start,
		etime = now,
	}
end

function water:on_hour_trigger(now, duration)
	local now = math.floor(now)
	local list = self._min_list
	local last = self._hour_list[#self._hour_list]

	--- if Sample list is empty check whether this tag has ben calculated
	if last and last.etime >= now then
		assert(last.etime == now, "Cannot retrigger for any older time")
		return last
	end

	self._min_list = {}
	while #list > 0 and list[#list].etime > now do
		self:log('debug', 'Pushing later item into min list', list[#list].etime, now)
		table.insert(self._min_list, 1, list[#list])
		table.remove(list)
	end

	--- Calculate the upper tag first
	local upper_val = nil
	local err = nil
	if self._upper then
		upper_val, err = self._upper:on_hour_trigger(now)
	end
	
	while #list > 0 and list[1].stime < (now - duration) do
		local etime = now - duration
		local item_start = list[1].stime
		while etime - duration > item_start do
			etime = etime - duration
		end
		local start = etime - duration

		local old_list = {}
		local new_list = {}
		for _, v in ipairs(list) do
			if v.stime < etime then
				old_list[#old_list + 1] = v
			else
				new_list[#new_list + 1] = v
			end
		end
		assert(#old_list > 0)
		list = new_list

		local upper_val = nil
		if self._upper then
			upper_val = self._upper:query_hour(etime)
		end

		self:log('debug', 'WATER: calcuate older hour value', start, etime)
		local val = calc_list_2(self._upper, upper_val, old_list, start, etime)
		table.insert(self._min_list, val)
		self._callback(mgr.TYPES.HOUR, val, etime)
	end

	local start = now - duration

	local val = calc_list_2(self._upper, upper_val, list, start,  now)

	table.insert(self._hour_list, val)

	return val
end

function water:on_day_trigger(now, duration)
	local now = math.floor(now)
	if self._day and self._day.etime == now then
		return self._day
	end

	local list = self._hour_list
	self._hour_list = {}

	--- Calculate the upper tag first
	local upper_val = nil
	if self._upper then
		local val, err = self._upper:on_day_trigger(now)
		if not val then
			self:log('error', 'on_day_trigger failed to get upper', err)
		end
		upper_val = val
	end

	local start = now - duration

	local val = calc_list_2(self._upper, upper_val, list, start, now)

	self._day = val

	return val
end

return water
