local base = require 'hj212.calc.base'

local water = base:subclass('hj212.calc.water')

local MAX_TIMESTAMP_GAP = 5 -- tenseconds

--- The upper tag, e.g. [w00000]
-- If the upper tag not exists time will be used for caclue the (total) value
--
function water:initialize(callback, upper_tag)
	base.initialize(self, callback)

	self._last = os.time() - 1 --- Make sure last will not be same as tiemstamp
	self._last_avg = nil
	self._upper = upper_tag

	--- If we are waited by other tags
	self._value = nil
	self._timestamp = 0
	self._waiting = {}
end

function water:push(value, timestamp)
	local timestamp = math.floor(timestamp)
	if self._upper then
		self._upper:get_value(timestmap, function(upper_value)
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

	table.insert(self._sample_list, {val, value, timestamp})

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

function water:get_value(timestamp, val_calc)
	if math.abs(self._timestamp - timestamp) < MAX_TIMESTAMP_GAP then
		return val_calc(self._value)
	end

	table.insert(self._waiting, {
		timestamp = timestamp,
		callback = val_calc
	})
end

local function calc_list(upper_val, list, start, now, last, last_avg)
	local val_t = 0
	local val_min = list[1][2]
	local val_max = list[1][2]

	for i, v in ipairs(list) do
		local val = v[1]
		local raw_val = v[2]
		val_min = raw_val < val_min and raw_val or val_min
		val_max = raw_val < val_max and raw_val or val_max

		val_t = val_t + val
	end

	if last and last_avg then
		if last < now then
			val_t = last_avg * (now - last)
		end
	end

	local val_avg = 0
	if not upper_val then
		val_avg = val_t / (now - start)
		print('water.calc_list 1', val_t, now - start, val_avg, val_min, val_max)
	else
		val_avg = (val_t / upper_val.total) * (10 ^ -3)
		print('water.calc_list 2', val_t, upper_val.total, val_avg, val_min, val_max)
	end

	return {
		total = val_t,
		avg = val_avg,
		min = val_min,
		max = val_max,
		stime = start,
		etime = now,
	}
end

function water:query_min(etime)
	for _, v in ipairs(self._min_list) do
		if v.etime == etime then
			return v
		end
	end
	return nil, "No value end with "..etime
end

function water:query_hour(etime)
	for _, v in ipairs(self._hour_list) do
		if v.etime == etime then
			return v
		end
	end
	return nil, "No value end with "..etime
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

	if #list == 0 then
		return nil, "There is no sample data"
	end
	self._sample_list = {}

	while list[#list][2] > now do
		table.insert(self._sample_list, list[#list])
		table.remove(list, #list)
	end

	--- Calculate the upper tag first
	local upper_val =  nil
	if self._upper then
		local val, err = self._upper:on_min_trigger(now)
		if not val then
			return nil, err
		end
		upper_val = val
	end

	while #list > 0 and list[1][3] < now - duration do
		last = self._min_list[#self._min_list]
		local start = last and last.etime or self:day_start()
		local item_start = list[1][3]
		while start + duration < item_start do
			start = start + duration
		end
		local etime = start + duration

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
		list = new_list

		local upper_val = nil
		if self._upper then
			upper_val = self._upper:query_min(etime)
		end

		if upper_val and #old_list > 0 then
			local val = calc_list(upper_val, old_list, start, etime, last_time, last_avg)
			table.insert(self._min_list, val)
			self._callback(mgr.TRYPES.MIN, val)
		else
			--TODO:
		end
	end
	if #list == 0 then
		return nil, "There is no sample data for current duration"
	end

	local start = now - duration

	--- Calculate the upper tag first
	local upper_val =  nil
	if self._upper then
		local val, err = self._upper:on_min_trigger(now)
		if not val then
			return nil, err
		end
		upper_val = val
	end

	local val = calc_list(upper_val, list, start, now, self._last, self._last_avg)

	table.insert(self._min_list, val)

	return val
end

local function calc_list_2(upper_val, list, start, now)
	local etime = start
	local val_t = 0
	local val_min = list[1].min
	local val_max = list[2].max

	for _, v in ipairs(list) do
		assert(v.stime > start, "Start time issue")
		assert(v.etime > etime, "Last time issue")
		etime = v.etime

		val_min = v.min < val_min and v.min or val_min
		val_max = v.max > val_max and v.max or val_max

		val_t = val_t + v.total
	end

	assert(etime == now, "Min data list has been calculated before hour calculation")

	local val_avg = 0
	if not upper_val then
		val_avg = val_t_avg / (now - start)
	else
		val_avg = (val_t / upper_val.total) * (10 ^ -3)
	end

	return {
		total = val_t,
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

	if #list == 0 then
		return nil, "There is no min data"
	end
	self._min_list = {}

	--- Calculate the upper tag first
	local upper_val = nil
	local err = nil
	if self._upper then
		upper_val, err = self._upper:on_hour_trigger(now)
	end
	
	while #list > 0 and list[1].etime < now - duration do
		last = self._hour_list[#self._hour_list]
		local start = last and last.etime or self:day_start()
		local item_start = list[1][3]
		while start + duration < item_start do
			start = start + duration
		end
		local etime = start + duration

		local old_list = {}
		local new_list = {}
		for _, v in ipairs(list) do
			if v.etime < etime then
				old_list[#old_list + 1] = v
			else
				new_list[#new_list + 1] = v
			end
		end
		list = new_list

		local upper_val = nil
		if self._upper then
			upper_val = self._upper:query_hour(etime)
		end

		if upper_val and #old_list > 0 then
			local val = calc_list_2(upper_val, old_list, start, etime)
			table.insert(self._min_list, val)
			self._callback(mgr.TRYPES.MIN, val)
		else
			--TODO:
		end
	end
	if #list == 0 then
		return nil, "There is no sample data for current duration"
	end

	if not upper_value then
		return nil, err
	end
	
	local start = now - duration

	local val = calc_list_2(upper_val, list, start,  now)

	table.insert(self._hour_list, val)

	return val
end

function water:on_day_trigger(now, duration)
	local now = math.floor(now)
	if self._day and self._day.etime == now then
		return self._day
	end

	local list = self._hour_list
	if #list == 0 then
		return nil, "There is no min data"
	end

	self._hour_list = {}

	--- Calculate the upper tag first
	local upper_val = nil
	if self._upper then
		local val, err = self._upper:on_day_trigger(now)
		if not val then
			return nil, err
		end
		upper_val = val
	end

	local start = now - duration

	local val = calc_list_2(upper_val, list, start, now)

	self._day = val

	return val
end

return water
