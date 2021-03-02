local class = require 'middleclass'
local types = require 'hj212.types'
local logger = require 'hj212.logger'
local mgr = require 'hj212.calc.manager'
local data_list = require 'hj212.calc.data_list'
local date = require 'date'

local base = class('hj212.calc.base')

base.static.TYPES = mgr.static.TYPES
local type_names = {}
for k, v in pairs(mgr.static.TYPES) do
	type_names[v] = k
end
base.static.TYPE_NAMES = type_names


base.static.calc_list_stime = function(list, etime, duration)
	assert(list, "list missing")
	assert(etime, "etime missing")
	assert(duration, "duration missing")
	local first = list:first()
	local stime = etime - duration
	if not first then
		return stime
	end

	local first_start = first.stime or first.timestamp
	assert(first_start)
	while stime > first_start do
		stime = stime - duration
	end
	return stime
end

local function create_callback(obj, typ)
	local type_name = type_names[typ]
	return function(val)
		local val, err = obj:_on_value(typ, val, val.etime, val.quality)
		if val then
			obj:_db_write(type_name, val)
			return val
		end
		obj:log('error', string.format('calc.on_value[%s] error:%s', type_name, err))
		return nil, err
	end
end

local function create_zs(calc)
	assert(calc)
	local zs_calc = calc
	return function (typ, val, now)
		assert(typ, 'Type missing')
		assert(val, 'Value missing')
		assert(now, 'Now missing')
		if typ == mgr.TYPES.SAMPLE then
			assert(val.value ~= nil, 'Value missing')
			val.value_z = zs_calc(val.value, now, 'SAMPLE')
			assert(val.value_z ~= nil)
		elseif typ == mgr.TYPES.RDATA then
			assert(val.value ~= nil, 'Value missing')
			val.value_z = zs_calc(val.value, now, 'RDATA')
			assert(val.value_z ~= nil)
		else
			--[[
			assert(val.avg ~= nil, 'AVG missing')
			assert(val.min ~= nil, 'MIN missing')
			assert(val.max ~= nil, 'MAX missing')
			val.avg_z = zs_calc(val.avg, now, 'AVG')
			val.min_z = zs_calc(val.min, now, 'MIN')
			val.max_z = zs_calc(val.max, now, 'MAX')
			]]--
		end
		return val
	end
end

function base:initialize(station, name, type_mask, min, max, zs_calc)
	assert(station, "Station missing")
	assert(name, "Name missing")
	self._station = station
	self._type_mask = type_mask ~= nil and type_mask or mgr.static.TYPES.ALL
	self._callback = callback
	self._name = name
	self._min = min
	self._max = max

	self._start = os.time()
	self._last_calc_time = 0
	--- Sample data list for minutes calculation
	self._sample_list = data_list:new('timestamp', function(val)
		local val, err = self:_on_value(mgr.TYPES.SAMPLE, val, val.timestamp, val.quality)
		if not val then
			self:log('error', string.format('calc.on_value[%s] error:%s', 'SAMPLE', err))
			return nil, err
		end
		if self._db then
			self._db:push_sample(val)
		end
		return val
	end, 60 * 60)
	--- Calculated
	self._rdata_list = data_list:new('timestamp', create_callback(self, mgr.TYPES.RDATA), 60 * 6)
	self._min_list = data_list:new('etime', create_callback(self, mgr.TYPES.MIN))
	self._hour_list = data_list:new('etime', create_callback(self, mgr.TYPES.HOUR))
	self._day_list = data_list:new('etime', create_callback(self, mgr.TYPES.DAY))
	self._value_calc = {}
	self._pre_calc = {}
	self._zs_calc = nil
	self._last_sample = nil

	if zs_calc then
		self:_set_zs_calc(zs_calc)
	end
end

function base:set_callback(callback)
	self._callback = callback
end

function base:_db_write(type_name, val)
	if self._db then
		local r, err = self._db:write(type_name, val)
		if not r then
			self:log('error', "DB write "..type_name.." error:"..err)
		end
	end
	return true
end

function base:push_value_calc(calc)
	table.insert(self._value_calc, calc)
end

function base:push_pre_calc(pre)
	table.insert(self._pre_calc, pre)
end

function base:_set_zs_calc(calc)
	if type(calc) == 'boolean' then
		if calc then
			self._zs_calc = function(typ, val, now)
				return val
			end
		else
			self._zs_calc = nil
		end
	else
		self._zs_calc = create_zs(calc)
	end
end

function base:has_zs()
	return self._zs_calc ~= nil
end

function base:_on_value(typ, val, timestamp, quality)
	assert(typ, 'type missing')
	assert(val, 'value missing')
	assert(timestamp, 'timestamp missing')

	local name = type_names[typ]
	assert(name, string.format('type is unknown %s', typ))

	-- Asserts on value missing
	assert(val.avg or val.value, self._name..[['s value missing]])

	--- Make sure timestamp is present which required for saving in DB
	val.timestamp = assert(val.timestamp or val.etime)

	--- Calculate the Value Flag by min/max
	--val.flag = val.flag or self:value_flag(val.avg or val.value)
	if not val.flag or val.flag == types.FLAG.Normal then
		val.flag = self:value_flag(val.avg or val.value)
	end

	--- Call the calculators
	local err
	for _, calc in ipairs(self._value_calc) do
		--self:debug('_value_calc', _, name, typ, val, timestamp)
		val, err = calc(typ, val, timestamp)
		if not val then
			return nil, err
		end
	end

	if self._zs_calc then
		val, err = self._zs_calc(typ, val, timestamp)
		if not val then
			return nil, err
		end
	end

	if self._callback then
		val, err = self._callback(name, val, timestamp, quality)
		if not val then
			return nil, err
		end
	end

	return val
end

function base:value_flag(value)
	local flag = types.FLAG.Normal
	if self._min and value < self._min then
		flag = types.FLAG.Overproof
	end
	if self._max and value > self._max then
		flag = types.FLAG.Overproof
	end
	return flag
end

function base:set_db(db)
	self._db = db
	if self._db then
		self:load_from_db()
	end
end

function base:log(level, fmt, ...)
	logger.log(level, '['..self._name..']'..fmt, ...)
end

function base:debug(fmt, ...)
	logger.log('debug', '['..self._name..']'..fmt, ...)
end

function base:db()
	return self._db
end

function base:set_mask(mask)
	self._type_mask = mask
end

function base:mask()
	return self._type_mask
end

function base:day_start(timestamp)
	local d = timestamp and date(timestamp):tolocal() or date(false) --- local time
	d:setseconds(0)
	d:setminutes(0)
	d:sethours(0)
	return date.diff(d:toutc(), date(0)):spanseconds()
end

function base:hour_start(timestamp)
	local d = timestamp and date(timestamp):tolocal() or date(false) --- local time
	d:setseconds(0)
	d:setminutes(0)
	return date.diff(d:toutc(), date(0)):spanseconds()
end

function base:load_from_db()
	if self._db then
		local day_start_time = self:day_start()
		self:debug('load hour data since', os.date('%c', day_start_time))

		local hour_list, err = self._db:read('HOUR', day_start_time, self._start)
		if hour_list then
			self._hour_list:init(hour_list)
		else
			self:log('error', err)
		end

		local last_hour_item = self._hour_list:last()
		local hour_start_time = last_hour_item and last_hour_item.etime or day_start_time
		self:debug('load min data since', os.date('%c', hour_start_time))

		local min_list, err = self._db:read('MIN', hour_start_time, self._start)
		if min_list then
			self._min_list:init(min_list)
		else
			self:log('error', err)
		end

		local last_min_item = self._min_list:last()
		local min_start_time = last_min_item and last_min_item.etime or hour_start_time
		self:debug('load sample data since', os.date('%c', min_start_time))

		local sample_list, err = self._db:read_samples(min_start_time, self._start)
		if sample_list then
			self._sample_list:init(sample_list)
			local first_sample = self._sample_list:first()
			if first_sample then
				self:debug('loaded first sample', os.date('%c', math.floor(first_sample.timestamp)))
			end
		else
			self:log('error', err)
		end

		self:debug('load rdata since', os.date('%c', min_start_time))
		local rdata_list, err = self._db:read('RDATA', min_start_time, self._start)
		if rdata_list then
			self._rdata_list:init(rdata_list)
		else
			self:log('error', err)
		end
	end
end

function base:push(value, timestamp, value_z, flag, quality)
	-- self:debug('pushing sample', value, timestamp, value_z, flag, quality)
	local last = self._sample_list:last()
	if last and last.timestamp == timestamp then
		assert(last.value == value)
		assert(not value_z or value_z == last.value_z)
		assert(not last.value_z or last.value_z == value_z)
		return nil, "Already has this data"
	end

	local val, err = self._sample_list:append({value = value, timestamp = timestamp, value_z = value_z, flag = flag, quality = quality})
	if val then
		self._last_sample = val
		return true
	end
	return nil, err
end

function base:sample_last()
	return self._sample_list:last()
end

function base:query_rdata(now, readonly)
	local val = self._rdata_list:find(now)
	if val then
		return val
	end
	if readonly or not self._last_sample then
		return nil, "No rdata for this time:"..now
	end

	--- Genereate RDATA
	local val = {}
	for k, v in pairs(self._last_sample) do
		val[k] = v
	end
	val.src_time = val.timestamp
	val.timestamp = now
	val.etime = now --- For callback usage

	-- Clean the last sample as we expect the new sample arrived before next query_rdata called
	self._last_sample = nil

	assert(self._rdata_list:append(val))

	return assert(self._rdata_list:find(now))
end

function base:query_min(etime)
	local v = self._min_list:find(etime)
	if v then
		return v
	end
	return nil, "No value end with "..etime
end

function base:query_hour(etime)
	local v = self._hour_list:find(etime)
	if v then
		return v
	end
	return nil, "No value end with "..etime
end

function base:query_day(etime)
	local v = self._day_list:find(etime)
	if v then
		return v
	end
	return nil, "No value end with "..etime
end

function base:on_trigger(typ, now, duration)
	local now = math.floor(now)
	for _, v in ipairs(self._pre_calc) do
		v:on_trigger(typ, now, duration)
	end

	if (self._type_mask & typ) == typ then
		if typ == mgr.TYPES.MIN then
			assert(self.on_min_trigger)
			assert(duration % 60 == 0)
			assert(self._last_calc_time <= now, 'now:'..now..'\tstart:'..self._last_calc_time)
			self._last_calc_time = now
			return self:on_min_trigger(now, duration)
		end
		if typ == mgr.TYPES.HOUR then
			assert(self.on_hour_trigger)
			assert(duration % 3600 == 0)
			return self:on_hour_trigger(now, duration)
		end
		if typ == mgr.TYPES.DAY then
			assert(self.on_day_trigger)
			assert(duration % (3600 * 24) == 0)
			return self:on_day_trigger(now, duration)
		end
	end
	return nil, "Unexpected trigger type"..typ
end

--- Query data by etime
function base:query_min_data(start_time, end_time)
	local first = self._min_list:first()
	if first and first.etime <= start_time then
		return self._min_list:query(start_time, end_time)
	elseif self._db then
		local name = type_names[mgr.TYPES.MIN]
		return self._db:read(name, start_time, end_time)
	else
		return nil
	end
end

--- Query data by etime
function base:query_hour_data(start_time, end_time)
	local first = self._hour_list:first()
	if first and first.etime <= start_time then
		return self._hour_list:query(start_time, end_time)
	elseif self._db then
		local name = type_names[mgr.TYPES.HOUR]
		return self._db:read(name, start_time, end_time)
	else
		return nil
	end
end

--- Query data by etime
function base:query_day_data(start_time, end_time)
	local first = self._day_list:first()
	if first and first.etime <= start_time then
		return self._day_list:query(start_time, end_time)
	elseif self._db then
		local name = type_names[mgr.TYPES.DAY]
		return self._db:read(name, start_time, end_time)
	else
		return nil
	end
end

return base
