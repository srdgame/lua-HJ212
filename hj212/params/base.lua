local class = require 'middleclass'

local base = class('hj212.params.base')

function base:initialize(name, value)
	self._name = name
	self._value = value
end

function base:name()
	return self._name
end

function base:value()
	return self._value
end

function base:encode()
	assert(nil, "Not implemented")
end

function base:decode(raw, index)
	assert(nil, "Not implemented")
end

return base
