local base = require 'hj212.calc.base'
local mgr = require 'hj212.calc.manager'
local types = require 'hj212.types'

local water = base:subclass('hj212.calc.water')

local MAX_TIMESTAMP_GAP = 5 -- tenseconds

--- The upper tag, e.g. [w00000]
-- If the upper tag not exists time will be used for caclue the (COU) value
--
function water:initialize(name, mask, min, max, upper_tag)
	base.initialize(self, name, mask, min, max)

	self._upper = upper_tag

	--- If we are waited by other tags
	self._value = nil
	self._timestamp = 0
	self._waiting = {}
end

function water:push(value, timestamp)
	local timestamp = math.floor(timestamp)
	assert(timestamp)
	if self._upper then
		return self._upper:get_value(timestamp, function(upper_value)
			return self:_push(upper_value, value, timestamp)
		end)
	else
		local last = self._sample_list:last()
		local t = timestamp - (last and last.timestamp or (os.time() - 5))
		return self:_push(t, value, timestamp)
	end
end

function water:_push(bvalue, value, timestamp)
	local val = bvalue * value * (10 ^ -3)

	local sample = {cou=val, value=value, timestamp=timestamp}
	local r, err = self._sample_list:append(sample)
	if not r then
		self:log('error', 'water:_push failed', err)
		return nil, err
	end

	self._value = val
	self._timestamp = timestamp

	if #self._waiting == 0 then
		return true
	end

	for _, v in ipairs(self._waiting) do
		if math.abs(v.timestamp - timestamp) < MAX_TIMESTAMP_GAP then
			v.callback(val)
		end
	end
	self._waiting = {}
	return true
end

function water:sample_meta()
	return {
		{ name = 'cou', type = 'DOUBLE', not_null = true },
		{ name = 'value', type = 'DOUBLE', not_null = true },
		{ name = 'timestamp', type = 'DOUBLE', not_null = true },
	}
end

function water:get_value(timestamp, val_calc)
	if math.abs(self._timestamp - timestamp) < MAX_TIMESTAMP_GAP then
		return val_calc(self._value)
	end

	table.insert(self._waiting, {
		timestamp = timestamp,
		callback = val_calc
	})
	return true
end

local function calc_sample(upper, upper_val, list, start, etime)
	if (upper and not upper_val) or #list == 0 then
		return {cou=0,avg=0,min=0,max=0,stime=start,etime=etime,flag=types.FLAG.CONNECTION}
	end
	local val_cou = 0
	local val_min = list[1].value
	local val_max = val_min

	local last = os.time() - 5
	local last_avg = 0

	for i, v in ipairs(list) do
		local cou = v.cou
		local value = v.value
		val_min = value < val_min and value or val_min
		val_max = value > val_max and value or val_max

		val_cou = val_cou + cou

		last_avg = val_cou / (v.timestamp - last)
		last = v.timestamp
	end

	if last < etime then
		val_cou = val_cou + last_avg * (etime - last)
	end

	local val_avg = 0
	if not upper_val then
		val_avg = val_cou / (etime - start)
		--print('water.calc_list 1', val_cou, now - start, val_avg, val_min, val_max)
	else
		if upper_val.cou > 0 then
			val_avg = (val_cou / upper_val.cou) * (10 ^ -3)
		else
			val_avg = 0
		end
		--print('water.calc_list 2', val_cou, upper_val.cou, val_avg, val_min, val_max)
	end

	return {
		cou = val_cou,
		avg = val_avg,
		min = val_min,
		max = val_max,
		stime = start,
		etime = etime,
	}
end

function water:on_min_trigger(now, duration)
	local now = math.floor(now)
	local sample_list = self._sample_list
	local last = self._min_list:find(now)
	if last then
		return last
	end

	--- Calculate the upper tag first
	local upper_val =  nil
	if self._upper then
		local val, err = self._upper:on_min_trigger(now, duration)
		if not val then
			self:log('error', 'water:on_min_trigger failed to get upper value', err)
		end
		upper_val = val
	end

	local start = base.calc_list_stime(sample_list, now, duration)
	while start < now - duration do
		local etime = start + duration
		local list = sample_list:pop(etime)

		if self._min_list:find(etime) then
			self:log('error', "WATER: older sample value skipped")
		else
			self:log('debug', 'WATER: calculate older sample value', start, etime)
			local upper_val = nil
			if self._upper then
				upper_val = self._upper:query_min(etime)
			end

			local val = calc_sample(self._upper, upper_val, list, start, etime)
			val = self:on_value(mgr.TYPES.MIN, val)
			assert(self._min_list:append(val))
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	local list = sample_list:pop(now)

	local val = calc_sample(self._upper, upper_val, list, start, now)
	val = self:on_value(mgr.TYPES.MIN, val)
	assert(self._min_list:append(val))

	return val
end

local function calc_cou(upper, upper_val, list, start, now)
	if (upper and not upper_val) or #list == 0 then
		return {cou=0,avg=0,min=0,max=0,stime=start,etime=now,flag=types.FLAG.CONNECTION}
	end
	local etime = start
	local val_cou = 0
	local val_min = list[1].min
	local val_max = list[1].max

	for _, v in ipairs(list) do
		assert(v.stime >= start, "Start time issue:"..v.stime..'\t'..start)
		assert(v.etime >= etime, "Last time issue:"..v.etime..'\t'..etime)
		etime = v.etime

		val_min = v.min < val_min and v.min or val_min
		val_max = v.max > val_max and v.max or val_max

		val_cou = val_cou + v.cou
	end

	assert(etime <= now)

	local val_avg = 0
	if not upper_val then
		val_avg = val_cou / (now - start)
	else
		if upper_val.cou > 0 then
			val_avg = (val_cou / upper_val.cou) * (10 ^ -3)
		else
			val_avg = 0
		end
	end

	return {
		cou = val_cou,
		avg = val_avg,
		min = val_min,
		max = val_max,
		stime = start,
		etime = now,
	}
end

function water:on_hour_trigger(now, duration)
	local now = math.floor(now)
	local sample_list = self._min_list
	local last = self._hour_list:find(now)
	if last then
		return last
	end

	--- Calculate the upper tag first
	local upper_val =  nil
	if self._upper then
		local val, err = self._upper:on_hour_trigger(now, duration)
		if not val then
			self:log('error', 'water:on_hour_trigger failed to get upper value', err)
		end
		upper_val = val
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
			self:log('debug', 'WATER: calculate older min value', start, etime)
			local upper_val = nil
			if self._upper then
				upper_val = self._upper:query_hour(etime)
			end

			local val = calc_cou(self._upper, upper_val, list, start, etime)
			val = self:on_value(mgr.TYPES.HOUR, val)
			assert(self._hour_list:append(val))
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	local list = sample_list:pop(now)

	local val = calc_cou(self._upper, upper_val, list, start, now)
	val = self:on_value(mgr.TYPES.HOUR, val)
	assert(self._hour_list:append(val))

	return val
end

function water:on_day_trigger(now, duration)
	local now = math.floor(now)
	local sample_list = self._hour_list
	local last = self._day_list:find(now)
	if last then
		return last
	end

	--- Calculate the upper tag first
	local upper_val =  nil
	if self._upper then
		local val, err = self._upper:on_day_trigger(now, duration)
		if not val then
			self:log('error', 'water:on_day_trigger failed to get upper value', err)
		end
		upper_val = val
	end

	local start = base.calc_list_stime(sample_list, now, duration)
	while start < now - duration do
		local etime = start + duration
		local list = sample_list:pop(etime)

		if self._hour_list:find(etime) then
			self:log('error', "WATER: older hour value skipped")
		else
			self:log('debug', 'WATER: calculate older hour value', start, etime)
			local upper_val = nil
			if self._upper then
				upper_val = self._upper:query_day(etime)
			end

			local val = calc_cou(self._upper, upper_val, list, start, etime)
			val = self:on_value(mgr.TYPES.DAY, val)
			assert(self._day_list:append(val))
		end

		start = base.calc_list_stime(sample_list, now, duration)
	end

	assert(start == now - duration)

	local list = sample_list:pop(now)

	local val = calc_cou(self._upper, upper_val, list, start, now)
	val = self:on_value(mgr.TYPES.DAY, val)
	assert(self._day_list:append(val))

	return val
end

return water
