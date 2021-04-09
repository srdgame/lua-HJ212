local class = require 'middleclass'
local param_tag = require 'hj212.params.tag'

local info = class('hj212.client.info')

function info:initialize(tag, name, options)
	assert(tag)
	assert(name)
	assert(options)

	self._tag = tag
	self._name = name
	self._fmt = options.fmt

	self._value = nil
	self._timestamp = nil
end

function info:info_name()
	return self._name
end

function info:tag()
	return self._tag
end

function info:set_value(value, timestamp)
	self._value = value
	self._timestamp = timestamp
	return true
end

function info:get_value()
	return self._value, self._timestamp
end

function info:data(timestamp)
	local timestamp = timestamp or self._timestamp

	if type(self._value) ~= 'table' then
		return param_tag:new(self._name, {
			Info = self._info
		}, timestamp, self._fmt)
	else
		return param_tag:new(self._name, self._value, timestamp, self._fmt)
	end
end

return info
