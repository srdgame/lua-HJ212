local class = require 'middleclass'
local param_tag = require 'hj212.params.tag'

local info = class('hj212.client.info')

function info:initialize(poll)
	assert(poll, "Poll missing")

	self._poll = poll

	self._value = nil
	self._timestamp = nil
	self._quality = nil
end

function info:poll()
	return assert(self._poll)
end

function info:set_value(value, timestamp, quality)
	assert(value)
	assert(timestamp and type(timestamp) == 'number')
	self._value = value
	self._timestamp = timestamp
	self._quality = quality
	return true
end

function info:get_value()
	return self._value, self._timestamp, self._quality
end

function info:data(timestamp)
	local timestamp = timestamp or self._timestamp
	assert(timestamp and type(timestamp) == 'number')

	local data = {}

	for k, v in pairs(self._value) do
		table.insert(data, param_tag:new(k, { Info = v }, timestamp))
	end

	return data
end

return info
