local base = require 'hj212.calc.base'

local simple = base:subclass('hj212.calc.simple')

function simple:initialize(callback)
	base.initialize(self, callback)

	self._waiting = {}
end

function simple:push(value, timestamp)
	local timestamp = math.floor(timestamp)
	table.insert(self._sample_list, {value, timestamp})
end

local function calc_list(list, start, now)
	local val_t = 0
	local val_min = 0
	local val_max = 0

	for i, v in ipairs(list) do
		local val = v[1]
		val_min = val < val_min and val or val_min
		val_max = val > val_max and val or val_max

		val_t = val_t + val
	end

	local val_avg = val_t / #list

	return {
		total = val_t,
		avg = val_avg,
		min = val_min,
		max = val_max,
		stime = start,
		etime = now,
	}
end

function simple:on_min_trigger(now, duration)
	local list = self._sample_list
	local last = self._min_list[#self._min_list]
	if last and last.etime >= now then
		assert(now == last.etime, "Last end time not equal to now")
		return last
	end

	if #list == 0 then
		return nil, "There is no sample data"
	end

	self._sample_list = {}

	while #list > 0 and list[1][2] < (now - duration) do
		last = self._min_list[#self._min_list]
		local start = last and last.etime or self:day_start()
		local item_start = list[1][2]
		while start + duration < item_start do
			start = start + duration
		end
		local etime = start + duration

		local old_list = {}
		local new_list = {}
		for i, v in ipairs(list) do
			if v[2] < etime then
				old_list[#old_list + 1] = v
			else
				new_list[#new_list + 1] = v
			end
		end
		list = new_list

		if #old_list > 0 then
			local val = calc_list(old_list, start, etime)
			table.insert(self._min_list, val)
			self._callback(mgr.TRYPES.MIN, val)
		end
	end
	if #list == 0 then
		return nil, "There is no sample data for current duration"
	end

	local start = now - duration

	local val = calc_list(list, start, now)

	table.insert(self._min_list, val)

	return val
end

local function calc_list_2(list, start, now)
	local etime = start
	local val_t = 0
	local val_t_avg = 0
	local val_min = 0
	local val_max = 0

	for i, v in ipairs(list) do
		assert(v.stime > start, "Start time issue")
		assert(v.etime > etime, "Last time issue")
		etime = v.etime

		val_min = v.min < val_min and v.min or val_min
		val_max = v.max > val_max and v.max or val_max

		val_t = val_t + v.total
		val_t_avg = val_t_avg + v.avg
	end

	assert(etime == now)

	local val_avg = val_t_avg / #list

	self._day = {
		total = val_t,
		avg = val_avg,
		min = val_min,
		max = val_max,
		stime = start,
		etime = now,
	}
end

function simple:on_hour_trigger(now)
	local now = math.floor(now)
	local list = self._min_list
	local last = self._hour_list[#self._hour_list]
	if last and last.etime >= now then
		assert(now == last.etime, "Last end time not equal to now")
		return last
	end

	if #list == 0 then
		return nil, "There is no sample data"
	end

	self._min_list = {}

	while #list > 0 and list[1][2] < (now - duration) do
		last = self._hour_list[#self._hour_list]
		local start = last and last.etime or self:day_start()
		local item_start = list[1][2]
		while start + duration < item_start do
			start = start + duration
		end
		local etime = start + duration

		local old_list = {}
		local new_list = {}
		for i, v in ipairs(list) do
			if v[2] < etime then
				old_list[#old_list + 1] = v
			else
				new_list[#new_list + 1] = v
			end
		end
		list = new_list

		if #old_list > 0 then
			local val = calc_list(old_list, start, etime)
			table.insert(self._min_list, val)
			self._callback(mgr.TRYPES.MIN, val)
		end
	end
	if #list == 0 then
		return nil, "There is no sample data for current duration"
	end

	local start = now - duration

	local val = calc_list_2(list, start, now)

	table.insert(self._hour_list, val)

	return val
end

function simple:on_day_trigger(now)
	local now = math.floor(now)
	if self._day and self._day.etime == now then
		assert(now == last.etime, "Last end time not equal to now")
		return self._day
	end

	local list = self._hour_list
	if #list == 0 then
		return nil, "There is no sample data"
	end

	self._hour_list = {}

	local start = self._day and self._day.etime or (now - duration)

	local val = calc_list_2(list, start, now)

	self._day = val

	return val
end

return simple
