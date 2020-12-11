local class = require 'middleclass'
local params = require 'hj212.params'
local packet = require 'hj212.packet'

local base = class('hj212.command.base')

function base:initialize(cmd, ATTRS)
	assert(ATTRS)
	self._command = cmd
	self._attrs = ATTRS
	for k, v in pairs(ATTRS) do
		assert(not self[k], 'Invalid attribute key')
		self[k] = v
	end
end

function base:command()
	return self._command
end

function base:encode()
	local data = {}
	for k,v in pairs(self._attrs) do
		data[k] = v
	end
	return params:new(data)
end

function base:decode(params)
	for k,v in pairs(self._attrs) do
		self[k] = params:get(k)
	end
end

return base
