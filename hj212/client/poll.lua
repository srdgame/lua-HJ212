local class = require 'middleclass'
local cjson = require 'cjson.safe'
local logger = require 'hj212.logger'
local types = require 'hj212.types'
local param_tag = require 'hj212.params.tag'
local calc_mgr_m = require 'hj212.calc.manager'
local poll_info = require 'hj212.client.info'

local poll = class('hj212.client.poll')

--- Calc name
-- Has COU is nil will using auto detect
function poll:initialize(station, id, options, info_creator)
	assert(station)
	assert(id, "Poll Id missing")
	self._station = station
	self._meter = nil

	-- Options
	self._id = id
	self._min = options.min
	self._max = options.max
	self._cou = options.cou -- {calc='simple', cou=0, params = {...}}
	self._fmt = options.fmt
	self._zs_calc = options.zs_calc
	self._info_creator = info_creator

	-- Data current
	self._value = nil
	self._flag = types.FLAG.Normal
	self._timestamp = nil
	self._quality = nil
	self._flag = nil

	-- COU calculator
	self._cou_calc = nil
	self._inited = false

	-- Info
	self._info = nil
end

--- Guess the proper calculator name
local function guess_calc_name(poll_id)
	if string.sub(poll_id, 1, 1) == 'w' then
		return 'water'
	elseif string.sub(poll_id, 1, 1) == 'a' then
		return 'air'
	else
		-- Default is simple calculator
		return 'simple'
	end
end

function poll:init()
	if self._inited then
		return
	end
	local calc_mgr = self._station:calc_mgr()

	local poll_id = self._id
	assert(poll and poll_id)

	local calc_name = self._cou.calc or guess_calc_name(poll_id)
	assert(calc_name)

	local m = assert(require('hj212.calc.'..calc_name))

	local msg = string.format('TAG [%06s] COU:%s ZS:%d', poll_id, calc_name, self._zs_calc and 1 or 0)
	local params = self._cou.params or {}
	if #params > 0 then
		msg = msg .. ' with '..cjson.encode(params)
	end
	logger.log('info', msg)

	local cou_base = upper_poll and upper_poll:cou_calc() or nil
	local mask = calc_mgr_m.TYPES.ALL

	local cou_calc = m:new(self._station, poll_id, mask, self._min, self._max, self._zs_calc, table.unpack(params))

	cou_calc:set_callback(function(type_name, val, timestamp, quality)
		if val.cou ~= nil and type(self._cou.cou) == 'number' then
			val.cou = has_cou
		end

		return self:on_calc_value(type_name, val, timestamp, quality)
	end)

	self._cou_calc = cou_calc
	calc_mgr:reg(self._cou_calc)

	self._inited = true

	return true
end

function poll:inited()
	return self._inited
end

function poll:set_meter(mater)
	self._meter = mater
end

function poll:meter()
	return self._meter
end

function poll:station()
	return self._station
end

function poll:id()
	return self._id
end

function poll:cou_calc()
	return self._cou_calc
end

function poll:upload()
	assert(nil, "Not implemented")
end

function poll:on_calc_value(type_name, val, timestamp)
	assert(nil, "Not implemented")
end

--- Ex vals will not be saved
function poll:set_value(value, timestamp, value_z, flag, quality, ex_vals)
	local flag = flag == nil and self._meter:get_flag() or nil
	self._value = value
	self._value_z = value_z
	self._timestamp = timestamp
	self._flag = flag
	self._quality = quality
	self._ex_vals = ex_vals
	return self._cou_calc:push(value, timestamp, value_z, flag, quality)
end

function poll:get_value()
	return self._value, self._timestamp, self._value_z, self._flag, self._quality, self._ex_vals
end

function poll:query_rdata(timestamp, readonly)
	local val, err = self._cou_calc:query_rdata(timestamp, readonly)
	if not val then
		logger.log('warning', self._id..' rdata missing', err)
		return nil, err
	end

	local rdata = {
		Rtd = val.value,
		Flag = val.flag,
		ZsRtd = val.value_z,
		--- EFlag is optional
		SampleTime = val.src_time or val.timestamp,
	}

	if self._ex_vals and val.timestamp == self._timestamp then
		for k, v in pairs(self._ex_vals) do
			rdata[k] = v
		end
	end

	return param_tag:new(self._id, rdata, timestamp, self._fmt)
end

function poll:convert_data(data)
	local rdata = {}
	local has_cou = self._cou.cou
	for k, v in ipairs(data) do
		if has_cou ~= false then
			rdata[#rdata + 1] = param_tag:new(self._id, {
				Cou = v.cou,
				Avg = v.avg,
				Min = v.min,
				Max = v.max,
				ZsAvg = v.avg_z,
				ZsMin = v.min_z,
				ZsMax = v.max_z,
				Flag = v.flag,
			}, v.stime, self._fmt)
		else
			rdata[#rdata + 1] = param_tag:new(self._id, {
				Avg = v.avg,
				Min = v.min,
				Max = v.max,
				ZsAvg = v.avg_z,
				ZsMin = v.min_z,
				Flag = v.flag,
			}, v.stime, self._fmt)
		end
	end
	return rdata
end

function poll:query_min_data(start_time, end_time)
	local data = self._cou_calc:query_min_data(start_time, end_time)
	return self:convert_data(data)
end

function poll:query_hour_data(start_time, end_time)
	local data = self._cou_calc:query_hour_data(start_time, end_time)
	return self:convert_data(data)
end

function poll:query_day_data(start_time, end_time)
	local data = self._cou_calc:query_day_data(start_time, end_time)
	return self:convert_data(data)
end

function poll:set_info_value(value, timestamp, quality)
	if not self._info then
		self._info = self._info_creator(self)
	end

	return self._info:set_value(value, timestamp, quality)
end

function poll:info_data(...)
	if not self._info then
		return nil, "No info found"
	end

	return self._info:data(...)
end

function poll:info()
	return self._info
end

return poll
