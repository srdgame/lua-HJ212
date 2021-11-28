local logger = require 'hj212.logger'
local helper = require 'hj212.calc.helper'
local base = require 'hj212.calc.base'
local mgr = require 'hj212.calc.manager'
local types = require 'hj212.types'
local flow = require 'hj212.calc.water.flow'
local pollut = require 'hj212.calc.water.pollut'

local water = base:subclass('hj212.calc.water')

local MIN_TIME_DIFF = 0.000001

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

	local min_interval = assert(self._station:min_interval())

	if id ~= 'w00000' then
		self._station:water(function(water)
			if water then
				self._flow_calc = water:cou_calc()
				self:push_pre_calc(self._flow_calc)

				local calc = pollut:new(self, self._flow_calc, min_interval)
				self:push_value_calc(calc)
				self._cou_calc = calc
			else
				local calc = flow:new(self, min_interval)
				self:push_value_calc(calc)
				self._cou_calc = calc
			end
		end)
	else
		local calc = flow:new(self, min_interval)
		self:push_value_calc(calc)
		self._cou_calc = calc
	end

	self._last_valid_sample = nil
	self._last_sample_cou_begin = 0
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

function water:last_valid_sample()
	return self._last_valid_sample
end

function water:sample_cou(stime, etime)
	assert(self._id == 'w00000')
	assert(stime and etime)
	if stime >= etime then
		return 0 -- why this happened???
	end

	-- self:log('debug', "WATER.sample_cou start", stime, etime, etime - stime)

	local val_cou = 0
	--- Check sample begine time with etime
	if self._last_sample_cou_begin >= etime then
		self:log('error', "WATER.sample_cou: last valid sample value error")
		return val_cou
	end

	--- check sample begin time
	if stime < self._last_sample_cou_begin then
		self:log('error', "WATER.sample_cou: last valid sample value error stime")
		stime = self._last_sample_cou_begin
	end
 
	local last = self._last_valid_sample
	local first_sample = nil
	local ll_time = stime

	local i = 1
	--print('sample_cou #sample', self._sample_list:size())
	--- start from 0 make sure we process all items
	self._sample_list:travel(0, etime, function(val)
		if helper.flag_can_calc(val.flag) then
			if val.timestamp < stime then
				last = val -- record last
				-- print('put last', val.timestamp, stime)
				return
			end

			if not first_sample then
				first_sample = val
			end

			if last and (val.timestamp - ll_time) > MIN_TIME_DIFF then
				local t_cou = last.value * (val.timestamp - ll_time)
				val_cou = val_cou + t_cou
				--print('sample_cou i', i, t_cou, last.value, val.timestamp - ll_time, val.value)
			else
				-- print(last, val.timestamp, ll_time)
			end

			-- record last
			last = val
			ll_time = val.timestamp
			i = i + 1
		else
			if val.timestamp < stime then
				i = i + 1
				--print('sample_cou i flag', i, val.flag, val.value, val.timestamp)
			end
		end
	end)
	-- self:log('debug', "WATER.sample_cou cou 1", val_cou, ll_time)

	-- tail cou
	if last and (etime - ll_time) > MIN_TIME_DIFF then
		local t_cou = last.value * (etime - ll_time)
		--print('sample_cou tail', t_cou, last.value, etime - ll_time, ll_time)
		val_cou = val_cou + t_cou
		-- self:log('debug', "WATER.sample_cou cou 3", cou, t_cou, last.value, etime - ll_time)
		-- print('sample_cou', t_cou, last.value, etime - ll_time)
	end

	--print('sample_cou total', val_cou)

	--[[
	self:log('debug', "WATER.sample_cou calc", val_cou, 'time', etime - stime)
	if last then
		self:log('debug', "WATER.sample_cou last", last.cou, 'value', last.value, 'timestamp', last.timestamp)
	end
	]]--

	return val_cou
end


function water:_calc_sample(list, start, etime, zs)
	local flag = #list == 0 and types.FLAG.CONNECTION or nil
	local val_cou = 0
	local val_min = #list > 0 and list[1].value or 0
	local val_max = val_min
	local first_value_z = #list > 0 and list[1].value_z or 0
	local val_cou_z = zs and 0 or nil
	local val_min_z = zs and first_value_z or nil
	local val_max_z = zs and first_value_z or nil 
	local val_avg = 0
	local val_avg_z = zs and 0 or nil

	local last = #list > 0 and (list[1].timestamp - 0.0001) or nil
	local last_val = 0
	local last_val_z = zs and 0 or nil
	local val_count = 0

	--print('calc_sample #list', #list)
	local last_vs = self._last_valid_sample

	for i, v in ipairs(list) do
		if helper.flag_can_calc(v.flag) then
			val_count = val_count + 1
			assert(v.timestamp > last, string.format('Timestamp issue:%f\t%f', v.timestamp, last))
			local value = v.value
			val_min = value < val_min and value or val_min
			val_max = value > val_max and value or val_max

			local cou = v.cou or 0
			val_cou = val_cou + cou
			last_val = value
			--print('calc_sample i' ,i, cou, last_vs and last_vs.value, last_vs and (v.timestamp - last_vs.timestamp) or (v.timestamp - start), v.value)
			last_vs = v

			if zs then
				local value_z = v.value_z or 0
				val_min_z = value_z < val_min_z and value_z or val_min_z
				val_max_z = value_z > val_max_z and value_z or val_max_z

				local cou_z = v.cou_z
				val_cou_z = val_cou_z + cou_z
				last_val_z = value_z
			end

			last = v.timestamp
		else
			--print('calc_sample i flag', i, v.flag, v.value, v.timestamp)
		end
	end


	--- Calc the value which not reached etime ???
	if val_count > 0 and (etime - last) > MIN_TIME_DIFF then
		local t_cou = 0
		if self._flow_calc then
			-- pollution
			local last_flow_sample = self._flow_calc:last_valid_sample()
			if last_flow_sample then
				local t_flow_cou = last_flow_sample.value * (etime - last)
				if t_flow_cou > 0 then
					t_cou = t_flow_cou * last_val
				end
			end
		else
			-- flow
			t_cou = last_val * (etime - last)
		end

		-- in case this is not initialized correctly, so we cannot know this is flow or pollution
		if not self._cou_calc then
			t_cou = 0
		end

		--print('calc_sample tail', t_cou, last_val, last, etime - last)
		val_cou = val_cou + t_cou

		if zs then
			assert(false, "zs not supported")
			--local cou_z = ( last_val_z * (etime - last)) / 1000
			--val_cou_z = val_cou_z + cou_z
		end
	else
		--print(etime, last)
	end

	--print('calc_sample total', val_cou)

	local first_stime = start -- for using start tiem
	if val_count > 0 and (etime - first_stime) > 0 then
		val_avg = val_cou / (etime - first_stime)
		if zs then
			val_avg_z = val_cou_z / (etime - first_stime)
		end
	end

	-- self:log('debug', 'water.calc_sample', self._id, val_cou, etime - start, val_avg, val_min, val_max)

	--print('calc_sample', val_cou)

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
			self:log('error', 'WATER: calculate older sample value', start, etime, #list, list[1].timestamp)

			local val = self:_calc_sample(list, start, etime, self:has_zs())
			local r, err = self._min_list:append(val)
			if not r then
				self:log('error', err)
			end
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	--[[
	local sample_cou = 0
	if self._id == 'w00000' then
		sample_cou = self:sample_cou(now - duration, now)
	end
	]]--

	local list = sample_list:pop(now)

	local val = self:_calc_sample(list, start, now, self:has_zs())
	assert(self._min_list:append(val))

	--- Buffer last valid sample value
	local i = #list
	while i > 0 do
		if helper.flag_can_calc(list[i].flag) then
			self._last_valid_sample = list[i]
			break
		end
		i = i - 1
	end
	if i == 0 then
		self._last_valid_sample = nil
		self._last_sample_cou_begin = 0
	else
		self._last_sample_cou_begin = now
	end

	if self._cou_calc then
		self._cou_calc:reset(now)
	end

	--print('MIN calc', sample_cou, val.cou)

	return val
end

function water:_calc_cou(list, start, etime, zs)
	local last = start
	local flag = #list == 0 and types.FLAG.CONNECTION or nil
	local val_cou = 0
	local val_min = #list > 1 and list[1].min or 0
	local val_max = #list > 1 and list[1].max or 0
	local val_cou_z = zs and 0 or nil
	local val_min_z = zs and #list > 1 and list[1].min_z or nil
	local val_max_z = zs and #list > 1 and list[1].max_z or nil
	local val_avg = 0
	local val_avg_z = zs and 0 or nil

	local first_stime = nil
	for _, v in ipairs(list) do
		assert(v.stime >= start, "Start time issue:"..v.stime..'\t'..start)
		assert(v.etime >= last, "Last time issue:"..v.etime..'\t'..last)
		last = v.etime
		if not first_stime then
			first_stime = v.stime
		end

		val_min = v.min < val_min and v.min or val_min
		val_max = v.max > val_max and v.max or val_max
		val_cou = val_cou + (v.cou or 0)

		if zs then
			val_min_z = (v.min_z or 0) < val_min_z and v.min_z or val_min_z
			val_max_z = (v.max_z or 0) > val_max_z and v.max_z or val_max_z
			val_cou_z = val_cou + (v.cou_z or 0)
		end
	end

	assert(last <= etime, 'last:'..last..'\tetime:'..etime)

	if not first_stime then
		first_stime = start
	end
	if (etime - first_stime) > 0 then
		--- this only worked for flow, the pollution will be calced in water/pollut.lua
		val_avg = (1000 * val_cou) / (etime - first_stime)
		if zs then
			val_avg_z = (1000 * val_cou_z) / (etime - first_stime)
		end
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
			self:log('error', 'WATER: calculate older min value', start, etime, #list, list[1].stime)
			local val = self:_calc_cou(list, start, etime, self:has_zs())
			assert(self._hour_list:append(val))
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	local list = sample_list:pop(now)

	local val = self:_calc_cou(list, start, now, self:has_zs())
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
			self:log('error', 'WATER: calculate older hour value', start, etime, #list, list[1].stime)
			local val = self:_calc_cou(list, start, etime, self:has_zs())
			assert(self._day_list:append(val))
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	local list = sample_list:pop(now)

	local val = self:_calc_cou(list, start, now, self:has_zs())
	assert(self._day_list:append(val))

	return val
end

return water
