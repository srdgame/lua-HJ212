local class = require 'middleclass'
local param_tag = require 'hj212.params.tag'

local info = class('hj212.client.info')

function info:initialize(poll)
	assert(poll)

	self._poll = poll

	self._value = nil
	self._timestamp = nil
	self._quality = nil
end

function info:poll()
	return self._poll
end

function info:set_value(value, timestamp, quality)
	self._value = value
	self._timestamp = timestamp
	self._quality = quality
	return true
end

function info:get_value()
	return self._value, self._timestamp, self._quality
end

function info:get_format(info_name)
	return nil
end

function info:data(timestamp)
	local timestamp = timestamp or self._timestamp

	local data = {}

	for k, v in pairs(self._value) do
		local fmt = self:get_format(k)
		table.insert(data, param_tag:new(k, { Info = v }, timestamp, fmt))
	end

	return data
end

return info
