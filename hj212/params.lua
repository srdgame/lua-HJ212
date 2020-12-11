local class = require 'middleclass'
local dtime  require 'hj212.params.value.time'
local datetime = require 'hj212.params.value.datetime'
local simple = require 'hj212.params.value.simple'
local dev_param = require 'hj212.params.device'
local tag_param = require 'hj212.params.tag'

local params = class('hj212.params')

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

function params:devices()
	return self._devs
end

function params:tags()
	return self._tags
end

function params:encode()
	local raw = {}
	local sort = {}
	for k, v in pairs(self._params) do
		sort[#sort + 1] = k
	end
	table.sort(sort)
	for _, v in ipairs(sort) do
		local val = self._params[v]
		raw[#raw + 1] = string.format('%s=%s', v, val:encode())
	end
	return table.concat(raw, ',')
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
