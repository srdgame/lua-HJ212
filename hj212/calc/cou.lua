local helper = require 'hj212.calc.helper'
local base = require 'hj212.calc.base'
local types = require 'hj212.types'

local cou = base:subclass('hj212.calc.cou')

--[[
-- The COU is couting all sample values
-- The AVG is COU / sample count
--]]

local COU_DIFF_MIN = 100
local COU_TIME_MIN = 0.0001

function cou:initialize(station, id, mask, min, max, zs_calc)
	base.initialize(self, station, id, mask, min, max, zs_calc)
end

function cou:push(value, timestamp, value_z, flag, quality, ex_vals)
	if timestamp < self._last_calc_time then
		return nil, 'older value skipped ts:'..timestamp..' last:'..self._last_calc_time
	end
	if value and value < 0 then
		self:log('error', "COU: Negative value set to zero", value)
		value = 0
	end
	if value_z and value_z < 0 then
		self:log('error', "COU: Negative value_z set to zero", value_z)
		value_z = 0
	end
	return base.push(self, value, timestamp, value_z, flag, quality, ex_vals)
end

local function calc_sample_min_max()
	local val_base = 0
	return function(val, val_min, val_max)
		if not val_min then
			val_min = val
		else
			if val - val_min < COU_DIFF_MIN then
				--- cou has been reset
				val_base = val_base + val_max -- the max pre
				val_base = val_base - val
			end
		end
		if not val_max then
			val_max = val + val_base
		else
			val_max = math.max(val + val_base, val_max)
		end
		return val_min, val_max
	end
end

local function calc_sample(list, start, etime, zs)
	local flag = nil -- set the nil
	local val_cou = 0
	local val_min = nil
	local val_max = nil
	local val_avg = 0

	local val_cou_z = zs and 0 or nil
	local val_min_z = nil
	local val_max_z = nil
	local val_avg_z = zs and 0 or nil

	local last = start - COU_TIME_MIN -- make sure the asserts work properly
	local first_stime = nil

	local calc_min_max = calc_sample_min_max()
	local calc_min_max_z = zs and calc_sample_min_max() or nil

	for _, v in ipairs(list) do
		if helper.flag_can_calc(v.flag) then
			assert(v.timestamp > last, string.format('Timestamp issue:%f\t%f', v.timestamp, last))
			last = v.timestamp
			if v.value then
				first_stime = last
				val_min, val_max = calc_min_max(v.value, val_min, val_max)
			end

			if zs and v.value_z then
				val_min_z, val_max_z = calc_min_max_z(v.value_z, val_min_z, val_max_z)
			end
		end
	end

	if not first_stime then
		flag = types.FLAG.Connection
	else
		val_cou = val_max - val_min
		if val_cou > 0 and (etime - first_stime) > COU_TIME_MIN then
			val_avg = val_cou / (etime - first_stime)
		end
		if zs and val_min_z then
			val_cou_z = val_max_z - val_min_z
			if val_cou_z > 0 and (etime - first_stime) > COU_TIME_MIN then
				val_avg_z = val_cou_z / (etime - first_stime) -- assume same start time
			end
		end
	end

	return {
		cou = val_cou, -- 排放量累计
		avg = val_avg, -- 平均值
		min = val_min,
		max = val_max,
		cou_z = val_cou_z,
		avg_z = val_avg_z,
		min_z = val_min_z,
		max_z = val_max_z,
		flag = flag,
		stime = start,  -- Duration start
		etime = etime,	-- Duration end
	}
end

function cou:on_min_trigger(now, duration)
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

local function calc_cou_min_max()
	local val_base = 0
	return function(v_min, v_max, val_min, val_max)
		if not val_min then
			val_min = v_min
		end
		if not val_max then
			val_max = v_max + val_base
		else
			if v_min - val_max < COU_DIFF_MIN then
				--- cou has been reset
				val_base = val_base + val_max -- the max pre
				val_base = val_base - v_min
			else
				val_max = math.max(v_max + val_base, val_max)
			end
		end
		return val_min, val_max
	end
end

local function calc_cou(list, start, etime, zs)
	local flag = nil
	local val_cou = 0
	local val_min = nil
	local val_max = nil
	local val_t_avg = 0
	local val_avg = 0

	local val_cou_z = zs and 0 or nil
	local val_min_z = nil
	local val_max_z = nil
	local val_t_avg_z = zs and 0 or nil
	local val_avg_z = zs and 0 or  nil

	local last = start - COU_TIME_MIN -- make sure etime assets works properly
	local val_count = 0

	local cou_min_max = calc_cou_min_max()
	local cou_min_max_z = zs and calc_cou_min_max() or nil

	for _, v in ipairs(list) do
		if helper.flag_can_calc(v.flag) then
			assert(v.stime >= start, "Start time issue:"..v.stime..'\t'..start)
			assert(v.etime >= last, "Last time issue:"..v.etime..'\t'..last)
			last = v.etime

			val_count = val_count + 1

			val_min, val_max = cou_min_max(v.min, v.max, val_min, val_max)
			val_t_avg = val_t_avg + v.avg
			if zs then
				val_min_z, val_max_z = cou_min_max_z(v.min_z, v.max_z, val_min, val_max)
				val_t_avg_z = val_t_avg_z + v.avg_z
			end
		end
	end

	assert(last <= etime, 'last:'..last..'\tetime:'..etime)

	if val_count > 0 then
		val_cou = val_max - val_min
		val_avg = val_t_avg / val_count
		if zs and val_min_z then
			val_cou_z = val_max_z - val_min_z
			val_avg_z = val_t_avg_z / val_count
		end
	else
		flag = types.FLAG.Connection
	end

	return {
		cou = val_cou,
		avg = val_avg,
		min = val_min,
		max = val_max,
		cou_z = val_cou_z,
		avg_z = val_avg_z,
		min_z = val_min_z,
		max_z = val_max_z,
		flag = flag,
		stime = start,
		etime = etime,
	}
end

function cou:on_hour_trigger(now, duration)
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
			local val = calc_cou(list, start, etime, self:has_zs())
			assert(self._hour_list:append(val))
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	local list = sample_list:pop(now)

	local val = calc_cou(list, start, now, self:has_zs())
	assert(self._hour_list:append(val))

	return val
end

function cou:on_day_trigger(now, duration)
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
			local val = calc_cou(list, start, etime, self:has_zs())
			assert(self._day_list:append(val))
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	local list = sample_list:pop(now)

	local val = calc_cou(list, start, now, self:has_zs())
	assert(self._day_list:append(val))

	return val
end

return cou
