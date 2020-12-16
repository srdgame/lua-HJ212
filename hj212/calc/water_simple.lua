local base = require 'hj212.calc.base'

local water = base:subclass('hj212.calc.water_simple')

function water:initialize(callback)
	base.initialize(self, callback)

	self._start = os.time()
	self._last = os.time()
	self._last_avg = nil
	--- Sample data list for minutes calculation
	self._simple_list = {}
	--- Calculated
	self._min_list = {}
	self._hour_list = {}
	self._day = nil

	self._waiting = {}
end

function water:set_value(value, timestamp, quality)
	local timestamp = math.floor(timestamp)
	table.insert(self._sample_list, {value, timestamp, quality})
end

function water:on_min_trigger(now)
	local now = math.floor(now)
	local list = self._sample_list
	local last = list[#list]
	if last and last.etime >= now then
		return last
	end

	if #list == 0 then
		self._start = now
		return nil, "There is no sample data"
	end

	local start = self._start
	self._start = now
	self._sample_list = {}

	local val_t = 0
	local val_min = 0
	local val_max = 0

	for i, v in ipairs(list) do
		local val = v[1]
		val_min = val < val_min and val or val_min
		val_max = val > val_max and val or val_max

		val_t = val_t + val
	end

	if self._last < now then
		val_t = self._last_avg * (now - self._last)
	end

	local val_avg = val_t / (now - start)

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
	if last and last.etime >= now then
		return last
	end

	if #list == 0 then
		return nil, "There is no sample data"
	end

	self._min_list = {}

	local start = list[#list].stime
	local etime = start

	local val_t = 0
	local val_min = 0
	local val_max = 0

	for i, v in ipairs(list) do
		assert(v.stime > start, "Start time issue")
		assert(v.etime > etime, "Last time issue")
		etime = v.etime

		val_min = v.min < val_min and v.min or val_min
		val_max = v.max > val_max and v.max or val_max

		val_t = val_t + v.total
	end

	assert(etime == now)

	local val_avg = val_t / (now - start)

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
		return self.-day
	end

	local list = self._hour_list
	if #list == 0 then
		return nil, "There is no sample data"
	end

	self._hour_list = {}

	local start = list[#list].stime
	local etime = start

	local val_t = 0
	local val_min = 0
	local val_max = 0

	for i, v in ipairs(list) do
		assert(v.stime > start, "Start time issue")
		assert(v.etime > etime, "Last time issue")
		etime = v.etime

		val_min = v.min < val_min and v.min or val_min
		val_max = v.max > val_max and v.max or val_max

		val_t = val_t + v.total
	end

	assert(etime == now)

	local val_avg = val_t / (now - start)

	self._day = {
		total = val_t,
		avg = val_avg,
		min = val_min,
		max = val_max,
		stime = start,
		etime = now,
	}

	return self._day
end

return water
