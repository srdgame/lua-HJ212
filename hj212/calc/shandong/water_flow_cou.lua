local types = require 'hj212.types'
local base = require 'hj212.calc.base'
local helper = require 'hj212.calc.helper'
local flow_cou = require 'hj212.calc.shandong.water.flow_cou'
local flow = require 'hj212.calc.shandong.water.flow'

local water = base:subclass('hj212.calc.water')

function water:initialize(station, id, type_mask, min, max, zs_calc)
	base.initialize(self, station, id, type_mask, min, max, zs_calc)

	local min_interval = assert(self._station:min_interval())

	self._station:wait_poll('w00000_cou', function(cou_poll)
		if cou_poll then
			local cou_calc = cou_poll:cou_calc()
			self:push_pre_calc(cou_calc)

			local calc = flow_cou:new(self, cou_calc, min_interval)
			self:push_value_calc(calc)
		else
			--- fallback ????
			local calc = flow:new(self, min_interval)
			self:push_value_calc(calc)
		end
	end)
end

function water:push(value, timestamp, value_z, flag, quality, ex_vals)
	if timestamp < self._last_calc_time then
		return nil, 'older value skipped ts:'..timestamp..' last:'..self._last_calc_time
	end
	return base.push(self, value, timestamp, value_z, flag, quality, ex_vals)
end

local function calc_sample(list, start, etime, zs)
	local flag = nil
	local val_cou = 0
	local val_min = nil
	local val_max = nil
	local val_avg = 0
	local val_avg_t = 0

	local last = start - 0.0001 -- make sure the asserts work properly
	local val_count = 0

	for _, v in ipairs(list) do
		if helper.flag_can_calc(v.flag) then
			assert(v.timestamp > last, string.format('Timestamp issue:%f\t%f', v.timestamp, last))
			last = v.timestamp

			local val = v.value
			assert(type(val) == 'number', 'Type is not number but '..type(val))

			val_min = val_min and math.min(val or val_min, val_min) or val
			val_max = val_max and math.max(val or val_max, val_max) or val

			val_count = val_count + 1
			val_avg_t = val_avg_t + (val or 0)
		end
	end

	if val_count <= 0 then
		flag = types.FLAG.Connection
	else
		val_avg = val_avg_t / val_count
		val_cou = val_avg * (etime - start) / 1000
	end

	return {
		cou = val_cou, -- 排放量累计
		avg = val_avg, -- 算术平均值
		min = val_min,
		max = val_max,
		flag = flag,
		stime = start,  -- Duration start
		etime = etime,	-- Duration end
	}
end

function water:on_min_trigger(now, duration)
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
			local val = calc_sample(list, start, etime, self:has_zs())
			self._min_list:append(val)
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	local list = sample_list:pop(now)

	local val = calc_sample(list, start, now, self:has_zs())
	assert(self._min_list:append(val))

	return val
end

local function calc_cou_hour(list, start, etime, zs)
	local flag = nil
	local last = start - 0.0001 -- make sure etime assets works properly
	local val_cou = 0
	local val_min = nil
	local val_max = nil
	local val_avg = 0
	local val_avg_t = 0

	local val_count = 0
	for _, v in ipairs(list) do
		if helper.flag_can_calc(v.flag) then
			assert(v.stime >= start, "Start time issue:"..v.stime..'\t'..start)
			assert(v.etime >= last, "Last time issue:"..v.etime..'\t'..last)
			last = v.etime

			val_min = val_min and math.min(v.min or val_min, val_min) or v.min
			val_max = val_max and math.max(v.max or val_max, val_max) or v.max

			val_avg_t = val_avg_t + v.avg
			val_cou = val_cou + v.cou -- for each cou
			val_count = val_count + 1
		end
	end

	if val_count <= 0 then
		flag = types.FLAG.Connection
	else
		val_avg = val_avg_t / val_count
		--- ? for using avg?
		-- val_cou = val_avg * (val_count * 60) -- val_count is minutes
	end

	assert(last <= etime, 'last:'..last..'\tetime:'..etime)

	return {
		cou = val_cou,
		avg = val_avg,
		min = val_min,
		max = val_max,
		flag = flag,
		stime = start,
		etime = etime,
	}
end

function water:on_hour_trigger(now, duration)
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
			local val = calc_cou_hour(list, start, etime, self:has_zs())
			assert(self._hour_list:append(val))
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	local list = sample_list:pop(now)

	local val = calc_cou_hour(list, start, now, self:has_zs())
	assert(self._hour_list:append(val))

	return val
end

local function calc_cou_day(list, start, etime, zs)
	local flag = nil
	local last = start - 0.0001 -- make sure etime assets works properly
	local val_cou = 0
	local val_min = nil
	local val_max = nil
	local val_avg = 0
	local val_avg_t = 0

	local val_count = 0
	for _, v in ipairs(list) do
		if helper.flag_can_calc(v.flag) then
			assert(v.stime >= start, "Start time issue:"..v.stime..'\t'..start)
			assert(v.etime >= last, "Last time issue:"..v.etime..'\t'..last)
			last = v.etime

			val_min = val_min and math.min(v.min or val_min, val_min) or v.min
			val_max = val_max and math.max(v.max or val_max, val_max) or v.max

			val_avg_t = val_avg_t + v.avg
			val_cou = val_cou + v.cou -- for each cou
			val_count = val_count + 1
		end
	end

	if val_count <= 0 then
		flag = types.FLAG.Connection
	else
		val_avg = val_avg_t / val_count
	end

	assert(last <= etime, 'last:'..last..'\tetime:'..etime)

	return {
		cou = val_cou,
		avg = val_avg,
		min = val_min,
		max = val_max,
		flag = flag,
		stime = start,
		etime = etime,
	}
end

function water:on_day_trigger(now, duration)
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
			local val = calc_cou_day(list, start, etime, self:has_zs())
			assert(self._day_list:append(val))
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	local list = sample_list:pop(now)

	local val = calc_cou_day(list, start, now, self:has_zs())
	assert(self._day_list:append(val))

	return val
end

return water
