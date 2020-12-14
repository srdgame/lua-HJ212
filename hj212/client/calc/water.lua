local base = require 'hj212.client.calc.base'

local water = base:subclass('hj212.client.calc.water')

--- The upper tag, e.g. [w00000]
-- If the upper tag not exists time will be used for caclue the (total) value
--
function water:initialize(upper_tag)
	self._start = os.time()
	self._last = os.time()
	self._last_avg = nil
	self._upper = upper_tag
	--- The sample data list
	self._sample_list = {}
	--- Minutes
	self._min_list = {}
	self._hour_list = {}
	self._day = nil

	--- If we are waited by other tags
	self._waiting = {}
end

function water:set_value(value, timestamp, quality)
	local timestamp = math.floor(timestamp)
	if self._upper then
		self._upper:get_value(function(upper_value)
			self:_set_value(upper_value, value, timestamp, quality)
		end)
	else
		local t = timestamp - self._last
		self:_set_value(t, value, timestamp, quality)
	end
end

function water:_set_value(bvalue, value, timestamp, quality)
	assert(timestamp > self._last, 'Last timestamp')

	local val = bvalue * value * (10 ^ -3)

	table.insert(self._sample_list, {val, value, timestamp, quality})

	self._last_avg = (val) / (timestamp - self._last)
	self._last = timestamp

	if self._waiting[timestamp] then
		for _, cb in ipairs(self._waiting) do
			cb(val)
		end
		self._waiting[timestam] = nil
	end
end

function water:get_value(timestamp, val_calc)
	if self._waiting[timestamp] then
		table.insert(self._waiting, val_calc)
	end

	for _, v in ipairs(self._sample_list) do
		if v[3] == timestamp then
			val_calc(v[1])
			return
		end
	end
	self._waiting[timestamp] = {val_calc}
end

function water:on_min_trigger(now)
	local now = math.floor(now)
	local list = self._sample_list
	local last = list[#list]

	--- if Sample list is empty check whether this tag has ben calculated
	if last and last.etime >= now then
		assert(last.etime == now, "End time is smaller!!!")
		return last
	end

	if #list == 0 then
		self._start = now
		return nil, "There is no sample data"
	end

	local start = self._start
	self._start = now
	self._sample_list = {}

	--- Calculate the upper tag first
	local upper_val =  nil
	if self._upper then
		local val, err = self._upper:on_min_trigger(now)
		if not val then
			return nil, err
		end
		upper_val = val
	end

	local val_t = 0
	local val_min = 0
	local val_max = 0

	for i, v in ipairs(list) do
		local val = v[1]
		local raw_val = v[2]
		val_min = raw_val < val_min and raw_val or val_min
		val_max = raw_val < val_max and raw_val or val_max

		val_t = val_t + val
	end

	if (self._last < now) then
		val_t = self._last_avg * (now - self._last)
	end

	local val_avg = 0
	if not self._upper then
		val_avg = val_t / (now - start)
	else
		val_avg = (val_t / upper_val.total) * (10 ^ -3)
	end

	local val = {
		total = val_t,
		avg = val_avg,
		min = val_min,
		max = val_max,
		stime = start,
		etime = now,
	}

	table.insert(self._min_list, val)

	return val
end

function water:on_hour_trigger(now)
	local now = math.floor(now)
	local list = self._min_list
	local last = list[#list]

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
	if self._upper then
		local val, err = self._upper:on_hour_trigger(now)
		if not val then
			return nil, err
		end
		upper_val = val
	end
	
	local start = list[1].stime
	local etime = start

	local val_t = 0
	local val_min = 0
	local val_max = 0

	for _, v in ipairs(list) do
		assert(v.stime > start, "Start time issue")
		assert(v.etime > etime, "Last time issue")
		etime = v.etime

		val_min = v.min < val_min  and v.min or val_min
		val_max = v.max > val_max and v.max or val_max

		val_t = val_t + v.total
	end

	assert(etime == now, "Min data list has been calculated before hour calculation")

	local val_avg = 0
	if not self._upper then
		val_avg = val_t / (now - start)
	else
		val_avg = (val_t / upper_val.total) * (10 ^ -3)
	end

	local val = {
		total = val_t,
		avg = val_avg,
		min = val_min,
		max = val_max,
		stime = start,
		etime = now,
	}

	table.insert(self._hour_list, val)

	return val
end

function water:on_day_trigger(now)
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

	local start = list[1].stime
	local etime = start

	local val_t = 0
	local val_min = 0
	local val_max = 0

	for _, v in ipairs(list) do
		assert(v.stime > start, "Start time issue")
		assert(v.etime > etime, "Last time issue")
		etime = v.etime

		val_min = v.min < val_min  and v.min or val_min
		val_max = v.max > val_max and v.max or val_max

		val_t = val_t + v.total
	end

	assert(etime == now, "Min data list has been calculated before hour calculation")

	local val_avg = 0
	if not self._upper then
		val_avg = val_t / (now - start)
	else
		val_avg = (val_t / upper_val.total) * (10 ^ -3)
	end

	local val = {
		total = val_t,
		avg = val_avg,
		min = val_min,
		max = val_max,
		stime = start,
		etime = now,
	}

	self._day = val

	return val
end

return water
