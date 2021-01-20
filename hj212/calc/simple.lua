local logger = require 'hj212.logger'
local base = require 'hj212.calc.base'
local mgr = require 'hj212.calc.manager'
local types = require 'hj212.types'

local simple = base:subclass('hj212.calc.simple')

--[[
-- The COU is couting all sample values
-- The AVG is COU / sample count
--]]

function simple:initialize(station, name, mask, min, max, zs_calc)
	base.initialize(self, station, name, mask, min, max, zs_calc)
end

function simple:push(value, timestamp, value_z)
	if timestamp < self._last_calc_time then
		return nil, 'older value skipped ts:'..timestamp..' last:'..self._last_calc_time
	end
	return base.push(self, value, timestamp, value_z)
end

local function calc_sample(list, start, etime, zs)
	local flag = #list == 0 and types.FLAG.Connection or nil
	local val_cou = 0
	local val_min = 0
	local val_max = 0
	local val_cou_z = zs and 0 or nil
	local val_min_z = zs and 0 or nil
	local val_max_z = zs and 0 or nil

	local last = start - 0.0001 -- make sure the asserts work properly
	for i, v in ipairs(list) do
		assert(v.timestamp > last, string.format('Timestamp issue:%f\t%f', v.timestamp, last))
		last = v.timestamp
		local val = v.value
		assert(type(val) == 'number')
		val_min = val < val_min and val or val_min
		val_max = val > val_max and val or val_max
		val_cou = val_cou + val
		
		if zs then
			local val_z = v.value_z or 0
			--logger.log('debug', 'simple.calc_sample ZS', val_z, val_cou_z, val_min_z, val_max_z)
			val_min_z = val_z < val_min_z and val_z or val_min_z
			val_max_z = val_z > val_max_z and val_z or val_max_z
			val_cou_z = val_cou_z + val_z
		end
	end

	local val_avg = #list > 0 and val_cou / #list or 0
	local val_avg_z = zs and (#list > 0 and val_cou_z / #list or 0) or nil

	--logger.log('debug', 'simple.calc_sample', #list, val_cou, val_avg, val_min, val_max)
	--[[
	if zs then
		logger.log('debug', 'simple.calc_sample ZS', #list, val_cou_z, val_avg_z, val_min_z, val_max_z)
	end
	]]--

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
		stime = start,  -- Duration start
		etime = etime,	-- Duration end
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

local function calc_cou(list, start, etime, zs)
	local flag = #list == 0 and types.FLAG.Connection or nil
	local last = start - 0.0001 -- make sure etime assets works properly
	local val_cou = 0
	local val_t_avg = 0
	local val_min = 0
	local val_max = 0
	local val_cou_z = zs and 0 or nil
	local val_min_z = zs and 0 or nil
	local val_max_z = zs and 0 or nil
	local val_t_avg_z = zs and 0 or nil

	for i, v in ipairs(list) do
		assert(v.stime >= start, "Start time issue:"..v.stime..'\t'..start)
		assert(v.etime >= last, "Last time issue:"..v.etime..'\t'..last)
		last = v.etime

		val_min = v.min < val_min and v.min or val_min
		val_max = v.max > val_max and v.max or val_max
		val_cou = val_cou + v.cou
		val_t_avg = val_t_avg + v.avg

		if zs then
			val_min_z = (v.min_z or 0) < val_min_z and v.min_z or val_min_z
			val_max_z = (v.max_z or 0) > val_max_z and v.max_z or val_max_z
			val_cou_z = val_cou_z + (v.cou_z or 0)
			val_t_avg_z = val_t_avg_z + (v.avg_z or 0)
		end
	end

	assert(last <= etime, 'last:'..last..'\tetime:'..etime)

	local val_avg = #list > 0 and val_t_avg / #list or 0
	local val_avg_z = zs and (#list > 0 and val_t_avg_z / #list or 0) or nil

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

return simple
