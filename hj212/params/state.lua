local class = require 'middleclass'
local logger = require 'hj212.logger'
local simple = require 'hj212.params.value.simple'

local state = class('hj212.params.state')

local fmts = {}
local function ES(fmt)
	local pn = 'hj212.state.ES_'..fmt

	if not fmts[fmt] then
		fmts[fmt] = simple.EASY(pn, fmt)
	end

	return fmts[fmt]
end

local PARAMS = {
	RS = ES('N1'),
	RT = ES('N2.2'),
}

state.static.PARAMS = PARAMS

function state:initialize(dev_id, obj)
	self._id = dev_id
	self._items = {}
	for k, v in pairs(obj or {}) do
		self:set(k, v)
	end
end

function state:id()
	return self._id
end

function state:get(key)
	local p = self._items[key]
	if p then
		return p:value()
	end
	return nil, "Not exists!"
end

function state:set(key, value)
	local p = self._items[key]
	if p then
		return p:set_value(value)
	end

	if PARAMS[key] then
		p = PARAMS[key]:new(key, value)
	else
		p = simple:new(key, value, 'N32')
	end
	self._items[key] = p
end

function state:_set_from_raw(key, value)
	local p = self._items[key]
	if p then
		return p:decode(value)
	end
	if PARAMS[key] then
		p = PARAMS[key]:new(self._id)
	else
		p = simple:new(key)
	end
	self._items[key] = p
	return p:decode(value)
end

function state:encode()
	local raw = {}
	local sort = {}
	for k, v in pairs(self._items) do
		sort[#sort + 1] = k
	end
	table.sort(sort)
	for _, v in ipairs(sort) do
		local val = self._items[v]
		raw[#raw + 1] = string.format('SB%s-%s=%s', self._id, v, val:encode())
	end
	return table.concat(raw, ',')
end

function state:decode(raw)
	self._items = {}

	for param in string.gmatch(raw, '([^,;]+),?') do
		local id, key, val = string.match(param, '^SB([^%-]+)%-([^=]+)=(%w+)')
		if id == self._id then
			self:_set_from_raw(key, val)
		else
			logger.error("Error found", id, key, val)
		end
	end
end

return state
