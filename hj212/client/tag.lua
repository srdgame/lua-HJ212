local class = require 'middleclass'
local types = require 'hj212.types'
local param_tag = require 'hj212.params.tag'

local tag = class('hj212.client.tag')

--- Calc name
function tag:initialize(name, min, max, his_calc)
	assert(name, "Tag name missing")
	self._name = name
	self._min = min
	self._max = max
	self._his_calc = his_calc
	self._meter = nil
	self._value = 0
	self._timestamp = os.time()
	self._flag = types.FLAG.Normal
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

function tag:his_calc()
	return self._his_calc
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

function tag:set_value(value, timestamp)
	self._value = value
	self._timestamp = timestamp
	self._flag = self:value_flag(value)
	if self._his_calc then
		self._his_calc:push(value, timestamp)
	end
end

function tag:get_value()
	return self._value, self._timestamp
end

--- Wait until value is available
function tag:wait(timestamp)
	assert(nil, "Not Implemented")
end

function tag:query_rdata(now, save)
	if save and self._his_calc then
		self._his_calc:push_rdata(self._timestamp, self._value, self._flag, now)
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
		rdata[#rdata + 1] = param_tag:new(self._name, {
			Avg = v.avg,
			Min = v.min,
			Max = v.max,
		}, v.stime)
	end
	return rdata
end

function tag:query_min_data(start_time, end_time)
	local data = self._his_calc:query_min_data(start_time, end_time)
	return self:convert_data(data)
end

function tag:query_hour_data(start_time, end_time)
	local data = self._his_calc:query_hour_data(start_time, end_time)
	return self:convert_data(data)
end

function tag:query_day_data(start_time, end_time)
	local data = self._his_calc:query_day_data(start_time, end_time)
	return self:convert_data(data)
end

return tag
