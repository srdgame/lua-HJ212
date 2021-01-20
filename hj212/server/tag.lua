local class = require 'middleclass'
local logger = require 'hj212.logger'
local types = require 'hj212.types'
local param_tag = require 'hj212.params.tag'
local calc_mgr_m = require 'hj212.calc.manager'

local tag = class('hj212.client.tag')

--- Calc name
-- Has COU is nil will using auto detect
function tag:initialize(station, name, min, max, calc_name, has_cou)
	assert(name, "Tag name missing")
	self._station = station
	self._name = name
	self._min = min
	self._max = max
	self._meter = nil
	self._flag = types.FLAG.Normal
	self._calc_name = calc_name
	self._has_cou = has_cou
	self._cou_calc = nil
	self._inited = false
end

function tag:init(calc_mgr)
	if self._inited then
		return
	end

	local tag_name = self._name
	local has_cou = self._has_cou
	assert(tag and tag_name)
	local calc_name = self._calc_name
	if not calc_name then
		if string.sub(tag_name, 1, 1) == 'w' then
			calc_name = 'water'
		elseif string.sub(tag_name, 1, 1) == 'a' then
			calc_name = 'air'
		else
			calc_name = 'simple'
		end
	end
	if not has_cou then
		calc_name = 'simple'
	end
	assert(calc_name)

	local m = assert(require('hj212.calc.'..calc_name))

	local upper_tag = nil
	if has_cou and calc_name == 'water' then
		local w, err = self._station:water()
		if not w then
			logger.log('error', 'Fetch WATER flow failed. err:'..err)
		end
		upper_tag = w and w:tag() or nil
	end
	if has_cou and calc_name == 'air' then
		local w, err = self._station:air()
		if not w then
			logger.log('error', 'Fetch AIR flow failed. err:'..err)
		end
		upper_tag = w and w:tag() or nil
	end
	--- w00000 a00000 has cou, but they are the COU Base
	if upper_tag == self then
		upper_tag = nil
	end
	if upper_tag then
		-- Make sure upper is inited
		upper_tag:init(calc_mgr)
	end

	logger.log('info', string.format('TAG [%06s] calc_type:%s\tcou:%s\tupper:%s',
		tag_name, calc_name, has_cou, upper_tag ~= nil))

	local cou_base = upper_tag and upper_tag:cou_calc() or nil
	local mask = calc_mgr_m.TYPES.ALL

	self._cou_calc = m:new(tag_name, mask, self._min, self._max, cou_base)

	self._cou_calc:set_callback(function(type_name, val, timestamp)
		return self:on_calc_value(type_name, val, timestamp)
	end)

	calc_mgr:reg(self._cou_calc)

	self._inited = true

	return true
end

function tag:set_meter(mater)
	self._meter = mater
end

function tag:meter()
	return self._meter
end

function tag:tag_name()
	return self._name
end

function tag:cou_calc()
	return self._cou_calc
end

function tag:upload()
	assert(nil, "Not implemented")
end

function tag:value_flag(value)
	local flag = types.FLAG.Normal
	if self._min and value < self._min then
		flag = types.FLAG.Overproof
	end
	if self._max and value > self._max then
		flag = types.FLAG.Overproof
	end
	return flag
end

function tag:on_calc_value(type_name, val, timestamp)
	assert(nil, "Not implemented")
end

function tag:set_value(value, timestamp, value_z)
	self._value = value
	self._value_z = value_z
	self._timestamp = timestamp
	self._flag = self:value_flag(value)
	if self._cou_calc then
		return self._cou_calc:push(value, timestamp, value_z)
	end
	return true
end

function tag:get_value()
	return self._value, self._timestamp
end

function tag:query_rdata(timestamp, readonly)
	assert(false)
	if not self._value then
		return
	end

	if save and self._cou_calc then
		self._cou_calc:push_rdata(self._timestamp, self._value, self._flag, now)
	end

	return param_tag:new(self._name, {
		Rtd = self._value,
		Flag = self._flag,
		--- EFlag is optional
		SampleTime = self._timestamp
	}, now)
end

function tag:convert_data(data)
	local rdata = {}
	for k, v in ipairs(data) do
		if self._has_cou then
			rdata[#rdata + 1] = param_tag:new(self._name, {
				Cou = v.cou,
				Flag = v.flag,
				Avg = v.avg,
				Min = v.min,
				Max = v.max,
			}, v.stime)
		else
			rdata[#rdata + 1] = param_tag:new(self._name, {
				Flag = v.flag,
				Avg = v.avg,
				Min = v.min,
				Max = v.max,
			}, v.stime)
		end
	end
	return rdata
end

function tag:query_min_data(start_time, end_time)
	local data = self._cou_calc:query_min_data(start_time, end_time)
	return self:convert_data(data)
end

function tag:query_hour_data(start_time, end_time)
	local data = self._cou_calc:query_hour_data(start_time, end_time)
	return self:convert_data(data)
end

function tag:query_day_data(start_time, end_time)
	local data = self._cou_calc:query_day_data(start_time, end_time)
	return self:convert_data(data)
end

return tag
