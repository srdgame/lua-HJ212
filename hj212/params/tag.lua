local class = require 'middleclass'
local datetime = require 'hj212.params.value.datetime'
local simple = require 'hj212.params.value.simple'
local tag = require 'hj212.params.value.tag'

local params = class('hj212.params.tag')

local fmts = {}
local function ES(fmt)
	local pn = 'hj212.params.tag.ES_'..fmt

	if not fmts[fmt] then
		fmts[fmt] = simple.EASY(pn, fmt)
	end

	return fmts[fmt]
end

local TAG_PARAMS = {
	SampleTime = datetime,
	Rtd = tag,
	Min = tag,
	Avg = tag,
	Max = tag,
	ZsRtd = tag,
	ZsMin = tag,
	ZsAvg = tag,
	Flag = ES('C1'),
	EFlag = ES('C4'),
	Cou	= tag, -- TODO:
	Data = ES('N3.1'),
	DayDate = ES('N3.1'),
	NightData = ES('N3.1'),
	Info = info,
	SN = ES('C24')
}

function params:initialize(tag_name, obj)
	self._name = tag_name
	self._items = {}
	for k, v in pairs(obj or {}) do
		self:set(k, v)
	end
end

function params:get(name)
	local p = self._items[name]
	if p then
		return p:value()
	end
	return nil, "Not exists!"
end

function params:set(name, value)
	local p = self._items[name]
	if p then
		return p:set_value(value)
	end

	if PARAMS[name] then
		p = PARAMS[name]:new(name, value)
	else
		p = simple:new(name, value, 'N32')
	end
	self._items[name] = p
end

function params:encode()
	local raw = {}
	local sort = {}
	for k, v in pairs(self._items) do
		sort[#sort + 1] = k
	end
	table.sort(sort)
	for _, v in ipairs(sort) do
		local val = self._items[v]
		raw[#raw + 1] = string.format('%s-%s=%s', self._name, v, val:encode())
	end
	return table.concat(raw, ',')
end

function params:decode(raw, index)
	self._items = {}

	for param in string.gmatch(raw, '([^;,]+),?') do
		local name, key, val = string.match(param, '^([^%-]+)%-([^=]+)=(%w+)')
		if name == self._name then
			self:set(key, val)
		else
			print('Error tag attr', name, key, val)
		end
	end
end

return params
