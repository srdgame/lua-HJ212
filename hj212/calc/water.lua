local logger = require 'hj212.logger'
local base = require 'hj212.calc.base'
local mgr = require 'hj212.calc.manager'
local types = require 'hj212.types'
local flow = require 'hj212.calc.water.flow'
local pollut = require 'hj212.calc.water.pollut'

local water = base:subclass('hj212.calc.water')

--[[
-- COU: cou of sample is V.this * (T.sthis -  T.last)
--		cou of others is couting all sample's cou
-- AVG: COU / (T.start -  T.last)
--]]

--- The upper pollut id, e.g. [w00000]
-- If the upper pollut not exists time will be used for caclue the (COU) value
--
function water:initialize(station, id, mask, min, max, zs_calc)
	base.initialize(self, station, id, mask, min, max, zs_calc)

	local upper_calc = nil
	if id ~= 'w00000' then
		self._station:water(function(water)
			if water then
				self._upper = water
				local water_calc = water:cou_calc()
				self:push_pre_calc(water_calc)
				self:push_value_calc(pollut:new(self, water_calc))
			else
				self:push_value_calc(flow:new(self))
			end
		end)
	else
		self:push_value_calc(flow:new(self))
	end
end

function water:push(value, timestamp, value_z, flag, quality, ex_vals)
	assert(timestamp)
	if timestamp < self._last_calc_time then
		local err = 'older value skipped ts:'..timestamp..' last:'..self._last_calc_time
		self:log('error', err)
		return nil, err
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

local function calc_sample(list, start, etime, zs)
	local flag = #list == 0 and types.FLAG.CONNECTION or nil
	local val_cou = 0
	local val_min = 0
	local val_max = 0
	local val_cou_z = zs and 0 or nil
	local val_min_z = zs and 0 or nil
	local val_max_z = zs and 0 or nil 

	local last = #list > 0 and (list[1].timestamp - 5) or nil
	local last_avg = nil
	local last_avg_z = nil

	for i, v in ipairs(list) do
		if flag_can_calc(v.flag) then
			assert(v.timestamp > last, string.format('Timestamp issue:%f\t%f', v.timestamp, last))
			local value = v.value
			val_min = value < val_min and value or val_min
			val_max = value > val_max and value or val_max

			local cou = v.cou
			last_avg = cou / (v.timestamp - last)
			val_cou = val_cou + cou

			if zs then
				local value_z = v.value_z or 0
				val_min_z = value_z < val_min_z and value_z or val_min_z
				val_max_z = value_z > val_max_z and value_z or val_max_z

				local cou_z = v.cou_z
				last_avg_z = cou_z / (v.timestamp - last)
				val_cou_z = val_cou_z + cou_z
			end

			last = v.timestamp
		end
	end

	if #list > 0 and last < etime then
		val_cou = val_cou + last_avg * (etime - last)
		val_cou_z = zs and (val_cou_z + last_avg_z * (etime - last)) or nil
	end

	local val_avg = val_cou / (etime - start)
	local val_avg_z = zs and val_cou_z / (etime - start) or nil
	--[[
	if (list[1].timestamp - start) < 5 then
		val_avg = val_cou / (etime - start)
	else
		val_avg = val_cou / (etime - list[1].timestamp)
	end
	]]--

	--logger.log('debug', 'water.calc_sample', val_cou, etime - start, val_avg, val_min, val_max)

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

function water:on_min_trigger(now, duration)
	local sample_list = self._sample_list
	local last = self._min_list:find(now)
	if last then
		return last
	end

	local start = base.calc_list_stime(sample_list, now, duration)
	while start < now - duration do
		local etime = start + duration
		local list = sample_list:pop(etime)

		if self._min_list:find(etime) then
			self:log('error', "WATER: older sample value skipped")
			local cjson = require 'cjson.safe'
			for _, v in pairs(list) do
				self:log('error', ' Skip: '..cjson.encode(v))
			end
		else
			self:log('debug', 'WATER: calculate older sample value', start, etime, #list, list[1].timestamp)

			local val = calc_sample(list, start, etime, self:has_zs())
			assert(self._min_list:append(val))
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
	local last = start
	local flag = #list == 0 and types.FLAG.CONNECTION or nil
	local val_cou = 0
	local val_min = 0
	local val_max = 0
	local val_cou_z = zs and 0 or nil
	local val_min_z = zs and 0 or nil
	local val_max_z = zs and 0 or nil

	for _, v in ipairs(list) do
		assert(v.stime >= start, "Start time issue:"..v.stime..'\t'..start)
		assert(v.etime >= last, "Last time issue:"..v.etime..'\t'..last)
		last = v.etime

		val_min = v.min < val_min and v.min or val_min
		val_max = v.max > val_max and v.max or val_max
		val_cou = val_cou + v.cou

		if zs then
			val_min_z = (v.min_z or 0) < val_min_z and v.min_z or val_min_z
			val_max_z = (v.max_z or 0) > val_max_z and v.max_z or val_max_z
			val_cou_z = val_cou + (v.cou_z or 0)
		end
	end

	assert(last <= etime, 'last:'..last..'\tetime:'..etime)

	local val_avg = val_cou / (etime - start)
	local val_avg_z = zs and val_cou_z / (etime - start) or nil

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

function water:on_hour_trigger(now, duration)
	local sample_list = self._min_list
	local last = self._hour_list:find(now)
	if last then
		return last
	end

	local start = base.calc_list_stime(sample_list, now, duration)
	while start < now - duration do
		local etime = start + duration
		local list = sample_list:pop(etime)

		if self._hour_list:find(etime) then
			self:log('error', "WATER: older min value skipped")
			local cjson = require 'cjson.safe'
			for _, v in pairs(list) do
				self:log('error', ' Skip: '..cjson.encode(v))
			end
		else
			self:log('debug', 'WATER: calculate older min value', start, etime, #list, list[1].stime)
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

function water:on_day_trigger(now, duration)
	local sample_list = self._hour_list
	local last = self._day_list:find(now)
	if last then
		return last
	end

	local start = base.calc_list_stime(sample_list, now, duration)
	while start < now - duration do
		local etime = start + duration
		local list = sample_list:pop(etime)

		if self._hour_list:find(etime) then
			self:log('error', "WATER: older hour value skipped")
			local cjson = require 'cjson.safe'
			for _, v in pairs(list) do
				self:log('error', ' Skip: '..cjson.encode(v))
			end
		else
			self:log('debug', 'WATER: calculate older hour value', start, etime, #list, list[1].stime)
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

return water
