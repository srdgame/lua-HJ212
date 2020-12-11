local class = require 'middleclass'
local copy = require 'hj212.utils.copy'
local dtime  require 'hj212.params.value.time'
local datetime = require 'hj212.params.value.datetime'
local simple = require 'hj212.params.value.simple'
local dev_param = require 'hj212.params.device'
local tag_param = require 'hj212.params.tag'

local params = class('hj212.params')

local params.static.DEV_MAX_COUNT = 128
local params.static.TAG_MAX_COUNT = 128

local fmts = {}
local function ES(fmt)
	local pn = 'hj212.params.ES_'..fmt

	if not fmts[fmt] then
		fmts[fmt] = simple.EASY(pn, fmt)
	end

	return fmts[fmt]
end

local PARAMS = {
	SystemTime = datetime,
	QnRtn = ES('N3'),
	ExeRtn = ES('N3'),
	RtdInterval = ES('N4'),
	MinInterval = ES('N2'),
	RestartTime = datetime,
	PolId = ES('C6'),
	BeginTime = datetime,
	EndTime = datetime,
	DataTime = datetime,
	NewPW = ES('C6'),
	OverTime = ES('N2'),
	ReCount = ES('N2'),
	VaseNo = ES('N2'),
	CstartTime = dtime,
	Ctime = ES('N2'),
	Stime = ES('N4'),
	InfoId = ES('C6'),
}

function params:initialize(obj)
	self._devs = {}
	self._tags = {}
	for k, v in pairs(obj) do
		sefl:set(k, v)
	end
end

function params:get(name)
	local p = self._params[name]
	if p then
		return p:value()
	end
	return nil, "Not exists!"
end

function params:set(name, value)
	local p = self._params[name]
	if p then
		return p:set_value(value)
	end

	if PARAMS[name] then
		p = PARAMS[name]:new(name, value)
	else
		p = simple:new(name, value, 'N32')
	end
	self._params[name] = p
end

function params:add_device(data_time, dev)
	local t = self._devs[data_time] or {}
	table.insert(t, dev)
	self._devs[data_time] = t
	self._params['DataTime'] = nil
end

function params:add_tag(data_time, tag)
	local t = self._tags[data_time] or {}
	table.insert(t, tag)
	self._tags[data_time] = t
	self._params['DataTime'] = nil
end

function params:encode_devices(base)
	local data = {}
	for data_time, devs in pairs(self._devs) do
		local dt_val = datetime:new(data_time)

		local data_sub = copy.deep(base)
		table.insert(data_sub, string.format('DataTime=%s', dt_val))

		local count = 0
		for i, dev in ipairs(devs) do
			if count < params.static.DEV_MAX_COUNT then
				table.insert(data_sub, dev:encode())
				count = count + 1
			else
				if i ~= #devs then
					table.insert(data, data_sub)
					data_sub = copy.deep(base)
					table.insert(data_sub, string.format('DataTime=%s', dt_val))
				end
			end
		end
		-- Insert data_sub to data
		table.insert(data, data_sub)
	end

	return data
end

function params:encode_tags(base)
	local data = {}
	for data_time, tags in pairs(self._tags) do
		local count = 0

		local data_sub = copy.deep(base)
		table.insert(data_sub, string.format('DataTime=%s', data_time))

		for i, tag in ipairs(tags) do
			if count < params.static.TAG_MAX_COUNT then
				table.insert(data_sub, tag:encode())
			else
				if i ~= #tags then
					table.insert(data, data_sub)
					data_sub = copy.deep(base)
					table.insert(data_sub, string.format('DataTime=%s', data_time))
				end
			end
		end
		-- Insert data_sub to data
		table.insert(data, data_sub)
	end

	return data
end

function params:encode()
	--- Sort the base keys
	local sort = {}
	for k, v in pairs(self._params) do
		sort[#sort + 1] = k
	end
	table.sort(sort)

	local raw = {}
	for _, v in ipairs(sort) do
		local val = self._params[v]
		raw[#raw + 1] = string.format('%s=%s', v, val:encode())
	end

	local devs = self:encode_devices(raw)
	local tags = self:encode_tags(raw)
	if #devs == 0 and #tags == 0 then
		return table.concat(raw, ';')
	else
		local data = {}
		for _, v in ipairs(devs) do
			table.insert(data, v)
		end
		for _, v in ipairs(tags) do
			table.insert(data, v)
		end
		return data
	end
end

function params:decode(raw, index)
	self._params = {}
	self._devs = {}
	self._tags = {}

	for param in string.gmatch(raw, '([^;]+);?') do
		local key, val = string.match(param, '^([^=]+)=(%w+)')
		if PARAMS[key] then
			self:set(key, val)
		else
			if string.sub(name, 1, 2) == 'SB' then
				local m = '^SB([^%-]+)%-(%w+)='
				local dev_name, type_name = string.match(name, m)
				if dev_name and type_name then
					if self._devs[tag_name] then
						print('WARN: duplicated '..dev_name)
					end
					dev = dev_param:new(tag_name)
					dev:decode(param)
					self._devs[tag_name] = dev
				else
					print('Error SB found')
				end
			else
				local m = '^([^%-]+)%-(%w+)='
				local tag_name, type_name = string.match(name, m)
				if tag_name and type_name then
					if self._tags[tag_name] then
						print('WARN: duplicated '..tag_name)
					end
					tag = tag_param:new(tag_name)
					tag:decode(param)
					self._tags[tag_name] = tag
				end
			end
		end
	end
end

return params
