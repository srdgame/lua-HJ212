local class = require 'middleclass'
local types = require 'hj212.types'
local water_calc = require 'hj212.calc.simple'
local air_calc = require 'hj212.calc.air'

local tag = class('hj212.client.tag')

--- Calc name
function tag:initialize(meter, name, calc, min, max)
	assert(name, "Tag name missing")
	self._meter = meter
	self._name = name
	if not calc then
		if string.sub(name, 1, 1) == 'w' then
			calc = 'water'
		else
			calc = 'air'
		end
	end
	
	if type(calc) == 'string'  then
		if calc == 'water' then
			calc = water_calc:new(function(typ, val)
				self:on_calc_value(typ, val)
			end)
		end
		if calc == 'air' then
			calc = air_calc:new(function(typ, val)
				self:on_calc_value(typ, val)
			end)
		end
	end

	self._calc = calc
	self._min = min
	self._max = max
	self._value = 0
	self._timestamp = os.time()
	self._flag = types.FLAG.Normal
end

function tag:meter()
	return self._meter
end

function tag:name()
	return self._name
end

function tag:calc()
	return self._calc
end

function tag:set_value(value, timestamp)
	if self._min and self._value < self._min then
		self._flag = types.FLAG.Overproof
	end
	if self._max and self._value > self._max then
		self._flag = types.FLAG.Overproof
	end

	if self._calc then
		self._value, self._timestamp = self._calc:set_value(value, timestamp)
	else
		self._value = value
		self._timestamp = timestamp
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

function tag:on_calc_value(typ, val)
	assert(nil, "Not implmented")
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
