local logger = require 'hj212.logger'
local base = require 'hj212.calc.base'
local mgr = require 'hj212.calc.manager'
local types = require 'hj212.types'
local data_list = require 'hj212.calc.data_list'

local LA = base:subclass('hj212.calc.LA')

--[[
-- The COU is couting all sample values
-- The AVG is COU / sample count
--]]

local max_sample_per_min = 30

function LA:initialize(station, id, mask, min, max, zs_calc)
	base.initialize(self, station, id, mask, min, max, zs_calc)

	--- Current hour samples
	self._hour_sample_list = data_list:new('timestamp', nil, max_sample_per_min * 60, function()
		self:log('error', 'LA hour sample data droped')
	end)

	--- Current day samples
	self._day_sample_list = data_list:new('timestamp', nil, max_sample_per_min * 60 * 24, function()
		self:log('error', 'LA day sample data droped')
	end)
end

function LA:load_from_db()
	base.load_from_db(self)
	if not self._db then
		return
	end

	local day_start_time = self:day_start()
	self:debug('load day sample data since', os.date('%c', day_start_time))

	local sample_list, err = self._db:read_samples(day_start_time, self._start)
	if sample_list then
		self._day_sample_list:init(sample_list)
		local first_sample = self._day_sample_list:first()
		if first_sample then
			self:debug('loaded first day sample', os.date('%c', math.floor(first_sample.timestamp)))
		end
	else
		self:log('error', err)
	end

	local hour_start_time = self:hour_start()
	self:debug('load hour sample data since', os.date('%c', hour_start_time))

	local sample_list, err = self._db:read_samples(hour_start_time, self._start)
	if sample_list then
		self._hour_sample_list:init(sample_list)
		local first_sample = self._hour_sample_list:first()
		if first_sample then
			self:debug('loaded first hour sample', os.date('%c', math.floor(first_sample.timestamp)))
		end
	else
		self:log('error', err)
	end
end

function LA:push(value, timestamp, value_z, flag, quality, ex_vals)
	if timestamp < self._last_calc_time then
		return nil, 'older value skipped ts:'..timestamp..' last:'..self._last_calc_time
	end
	return base.push(self, value, timestamp, value_z, flag, quality, ex_vals)
end

local function flag_can_calc(flag)
	if flag == nil then
		return true
	end
	if flag == types.FLAG.Normal or flag == types.FLAG.Overproof then
		return true
	end
	return false
end

local function get_la_value(list, percent)
	local count = #list
	if count == 0 then
		return 0
	end
	local c = math.floor(count * percent / 100)
	if c == 0 then
		c = 1
	end
	return list[c].value or 0
end

local function calc_la(list)
	local calc_list = {}

	for i, v in ipairs(list) do
		if flag_can_calc(v.flag) then
			calc_list[#calc_list + 1] = v
		end
	end
	local LA = {
		avg = 0,
		min = 0,
		max = 0,
		L5 = 0,
		L10 = 0,
		L50 = 0,
		L90 = 0,
		L95 = 0,
	}
	if #calc_list == 0 then
		return LA
	end

	table.sort(calc_list, function(a, b)
		return (a.value or 0) < (b.value or 0)
	end)
	LA.L5 = get_la_value(calc_list, 5)
	LA.L10 = get_la_value(calc_list, 10)
	LA.L50 = get_la_value(calc_list, 50)
	LA.L90 = get_la_value(calc_list, 90)
	LA.L95 = get_la_value(calc_list, 95)

	return LA
end

local function calc_la_day(list, is_day)
	local day_list = {}
	local night_list = {}

	for i, v in ipairs(list) do
		if is_day(v.timestamp) then
			day_list[#day_list + 1] = v
		else
			night_list[#night_list + 1] = v
		end
	end

	local LA = calc_la(list)
	LA.DAY = calc_la(day_list)
	LA.NIGHT = calc_la(night_list)

	return LA
end

local function calc_sample(list, start, etime)
	local flag = #list == 0 and types.FLAG.Connection or nil
	local val_cou = 0
	local val_min = 0
	local val_max = 0
	local val_t = 0

	local last = start - 0.0001 -- make sure the asserts work properly
	for i, v in ipairs(list) do
		if flag_can_calc(v.flag) then
			assert(v.timestamp > last, string.format('Timestamp issue:%f\t%f', v.timestamp, last))
			last = v.timestamp
			local val = v.value or 0
			assert(type(val) == 'number', 'Type is not number but '..type(val))
			val_min = val < val_min and val or val_min
			val_max = val > val_max and val or val_max
			val_cou = val_cou + (10 ^ (0.1 * val))
			val_t = val_t + 1

			--logger.log('debug', 'LA.calc_sample', val_cou, v.cou or val, val_min, val_max)
		end
	end

	local val_avg = val_t > 0 and 10 * math.log((val_cou / val_t), 10) or 0

	--logger.log('debug', 'LA.calc_sample', #list, val_cou, val_avg, val_min, val_max)

	return {
		cou = val_cou,
		avg = val_avg,
		min = val_min,
		max = val_max,
		flag = flag,
		stime = start,  -- Duration start
		etime = etime,	-- Duration end
		LC = val_t,
		LA = LA,
	}
end

function LA:on_min_trigger(now, duration)
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
			self:log('error', "LA: older sample value skipped", etime)
			local cjson = require 'cjson.safe'
			for _, v in pairs(list) do
				self:log('error', ' Skip: '..cjson.encode(v))
			end
		else
			self:log('debug', 'LA: calculate older sample value', start, etime, #list, list[1].timestamp)
			local val = calc_sample(list, start, etime)
			self._min_list:append(val)
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	local list = sample_list:pop(now)

	local val = calc_sample(list, start, now)
	assert(self._min_list:append(val))

	val.ex_vals = cjson.encode(calc_la(list))

	return val
end

local function calc_cou(list, start, etime)
	local flag = #list == 0 and types.FLAG.Connection or nil
	local last = start - 0.0001 -- make sure etime assets works properly
	local val_cou = 0
	local val_t = 0
	local val_min = 0
	local val_max = 0

	for i, v in ipairs(list) do
		assert(v.stime >= start, "Start time issue:"..v.stime..'\t'..start)
		assert(v.etime >= last, "Last time issue:"..v.etime..'\t'..last)
		last = v.etime

		val_min = v.min < val_min and v.min or val_min
		val_max = v.max > val_max and v.max or val_max
		val_cou = val_cou + v.cou
		val_t = val_t + v.LC
	end

	assert(last <= etime, 'last:'..last..'\tetime:'..etime)

	local val_avg = val_t > 0 and 10 * math.log((val_cou / val_t), 10) or 0

	return {
		cou = val_cou,
		avg = val_avg,
		min = val_min,
		max = val_max,
		flag = flag,
		stime = start,
		etime = etime,
		LC = val_t,
	}
end

function LA:on_hour_trigger(now, duration)
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
			self:log('error', "LA: older min value skipped")
			local cjson = require 'cjson.safe'
			for _, v in pairs(list) do
				self:log('error', ' Skip: '..cjson.encode(v))
			end
		else
			self:log('debug', 'LA: calculate older min value', start, etime, #list, list[1].stime)
			local val = calc_cou(list, start, etime)
			assert(self._hour_list:append(val))
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	local list = sample_list:pop(now)

	local val = calc_cou(list, start, now)
	assert(self._hour_list:append(val))

	local slist = self._hour_sample_list:pop(now)
	val.ex_vals = cjson.encode(calc_la(slist))

	return val
end

local function calc_cou_day(list, start, etime)
	local flag = #list == 0 and types.FLAG.Connection or nil
	local last = start - 0.0001 -- make sure etime assets works properly
	local val_cou = 0
	local val_t = 0
	local val_min = 0
	local val_max = 0

	for i, v in ipairs(list) do
		assert(v.stime >= start, "Start time issue:"..v.stime..'\t'..start)
		assert(v.etime >= last, "Last time issue:"..v.etime..'\t'..last)
		last = v.etime

		val_min = v.min < val_min and v.min or val_min
		val_max = v.max > val_max and v.max or val_max
		val_cou = val_cou + v.cou
		val_t = val_t + v.LC
	end

	assert(last <= etime, 'last:'..last..'\tetime:'..etime)

	local val_avg = val_t > 0 and 10 * math.log((val_cou / val_t), 10) or 0

	return {
		cou = val_cou,
		avg = val_avg,
		min = val_min,
		max = val_max,
		flag = flag,
		stime = start,
		etime = etime,
		LC = val_t,
	}
end

function LA:on_day_trigger(now, duration)
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
			self:log('error', "LA: older hour value skipped")
			local cjson = require 'cjson.safe'
			for _, v in pairs(list) do
				self:log('error', ' Skip: '..cjson.encode(v))
			end
		else
			self:log('debug', 'LA: calculate older hour value', start, etime, #list, list[1].stime)
			local val = calc_cou(list, start, etime)
			assert(self._day_list:append(val))
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	local list = sample_list:pop(now)

	local val = calc_cou_day(list, start, now)
	assert(self._day_list:append(val))

	local slist = self._day_sample_list:pop(now)
	local station_la = self._station:LA()
	val.ex_vals = cjson.encode(calc_la_day(slist, station_la.is_day))

	return val
end

return LA
