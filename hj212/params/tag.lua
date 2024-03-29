local logger = require 'hj212.logger'
local class = require 'middleclass'
local datetime = require 'hj212.params.value.datetime'
local simple = require 'hj212.params.value.simple'
local tag_val = require 'hj212.params.value.tag'

local tag = class('hj212.params.tag')

local fmts = {}
local function ES(fmt)
	local pn = 'hj212.params.tag.ES_'..fmt

	if not fmts[fmt] then
		fmts[fmt] = simple.EASY(pn, fmt)
	end

	return fmts[fmt]
end

local PARAMS = {
	SampleTime = datetime,
	Rtd = tag_val,
	Min = tag_val,
	Avg = tag_val,
	Max = tag_val,
	ZsRtd = tag_val,
	ZsMin = tag_val,
	ZsMax = tag_val,
	ZsAvg = tag_val,
	Flag = ES('C1'),
	EFlag = ES('C4'),
	Cou	= tag_val, -- TODO:
	Data = ES('N3.1'),
	DayDate = ES('N3.1'),
	NightData = ES('N3.1'),
	SN = ES('C24'),
	Info = tag_val,
}

tag.static.PARAMS = PARAMS

function tag:initialize(tag_id, obj, data_time, default_fmt)
	assert(tag_id)
	assert(not data_time or type(data_time) == 'number')
	self._id = tag_id
	self._data_time = data_time
	self._default_fmt = default_fmt
	self._items = {}
	self._cloned = nil
	for k, v in pairs(obj or {}) do
		self:set(k, v)
	end
end

function tag:clone(new_tag_id)
	local new_obj = tag:new(new_tag_id)
	new_obj._cloned = true
	new_obj._data_time = self._data_time
	new_obj._default_fmt = self._default_fmt
	for k, v in pairs(self._items) do
		new_obj._items[k] = v
	end
	return new_obj
end

function tag:transform(func)
	assert(func)
	local new_obj = tag:new(self._id)
	new_obj._data_time = self._data_time
	new_obj._items = {}
	new_obj._default_fmt = self._default_fmt
	for k, v in pairs(self._items) do
		local key, val = func(k, v:value())
		-- logger.debug("transform from", self._id, key, val)
		new_obj:set(key, val)
		-- logger.debug("transform result", self._id, key, self._items[key]:value())
	end
	return new_obj
end

function tag:id()
	return self._id
end

function tag:data_time()
	return self._data_time
end

function tag:set_data_time(time)
	self._data_time = time
end

function tag:default_format()
	return self._default_fmt
end

function tag:get(key)
	local p = self._items[key]
	if p then
		return p:value()
	end
	return nil, "Not exists!"
end

function tag:remove(key)
	-- remove won't need check _cloned flag
	self._items[key] = nil
end

function tag:set(key, value, def_fmt)
	assert(not self._cloned)
	local def_fmt = def_fmt or self._default_fmt
	local p = self._items[key]
	if p then
		return p:set_value(value)
	end

	if PARAMS[key] then
		p = PARAMS[key]:new(self._id, value, def_fmt)
	else
		p = simple:new(key, value, def_fmt)
	end
	self._items[key] = p
end

function tag:_set_from_raw(key, value)
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

function tag:encode()
	local raw = {}
	local sort = {}
	for k, v in pairs(self._items) do
		sort[#sort + 1] = k
	end
	table.sort(sort)
	for _, v in ipairs(sort) do
		local val = self._items[v]
		raw[#raw + 1] = string.format('%s-%s=%s', self._id, v, val:encode())
	end
	return table.concat(raw, ',')
end

function tag:decode(raw)
	self._items = {}

	for param in string.gmatch(raw, '([^;,]+),?') do
		local id, key, val = string.match(param, '^([^%-]+)%-([^=]+)=(.+)')
		if self._id == nil then
			self._id = id
		end
		if id == self._id then
			self:_set_from_raw(key, val)
		else
			logger.error('Error tag attr', id, key, val)
		end
	end
end

return tag
