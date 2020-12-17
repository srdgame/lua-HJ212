local class = require 'middleclass'
local types = require 'hj212.types'

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

function tag:name()
	return self._name
end

function tag:his_calc()
	return self._his_calc
end

function tag:set_value(value, timestamp)
	self._value = value
	self._timestamp = timestamp

	if self._min and value < self._min then
		self._flag = types.FLAG.Overproof
	end
	if self._max and value > self._max then
		self._flag = types.FLAG.Overproof
	end

	if self._his_calc then
		print(self._his_calc)
		self._his_calc:push(value, timestamp)
	end
end

function tag:get_value()
	return self._value, self._timestamp
end

function tag:query_rdata()
	return {
		Rtd = self._value,
		Flag = self._flag,
		--- EFlag is optional
		SampleTime = self._timestamp
	}
end

function tag:query_min_data(start_time, end_time)
	assert(nil, "Not implmented")
end

function tag:query_hour_data(start_time, end_time)
	assert(nil, "Not implmented")
end

function tag:query_day_data(start_time, end_time)
	assert(nil, "Not implmented")
end

return tag
