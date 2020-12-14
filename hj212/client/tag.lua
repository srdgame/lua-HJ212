local class = require 'middleclass'
local tag_calc = require 'hj212.client.calc.tag'

local tag = class('hj212.client.tag')

function tag:initialize(name)
	assert(name, "Tag name missing")
	self._name = name
	self._value = 0
	self._timestamp = os.time()
	self._quality = 1 -- Invalid at begging
	self._calc = nil
end

function tag:start(db)
	if not self._calc then
		self._calc = tag_calc:new(name)
		self._calc:start(db)
	end
end

function tag:stop()
	if self._calc then
		self._calc:stop()
		self._calc = nil
	end
end

function tag:__gc()
	self:stop()
end

function tag:set_value(value, timestamp, quality)
end

function tag:get_value()
end

return tag
