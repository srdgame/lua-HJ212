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
		obj:_db_write(type_name, val)
	end
end

function base:initialize(name, type_mask, min, max)
	assert(name, "Name missing")
	self._type_mask = type_mask ~= nil and type_mask or mgr.static.TYPES.ALL
	self._callback = callback
	self._name = name
	self._min = min
	self._max = max

	self._start = os.time()
	--- Sample data list for minutes calculation
	self._sample_list = data_list:new('timestamp', function(val)
		if self._db then
			self._db:push_sample(val)
		end
	end)
	--- Calculated
	self._min_list = data_list:new('etime', create_callback(self, mgr.TYPES.MIN))
	self._hour_list = data_list:new('etime', create_callback(self, mgr.TYPES.HOUR))
	self._day_list = data_list:new('etime', create_callback(self, mgr.TYPES.DAY))
end

function base:set_callback(callback)
	self._callback = callback
end

function base:_db_write(type_name, val)
	if self._db then
		return self._db:write(type_name, val)
	end
	return true
end

function base:on_value(typ, val, timestamp)
	assert(typ, 'type missing')
	assert(val, 'value missing')
	assert(timestamp, 'timestamp missing')
	local name = type_names[typ]
	assert(name, string.format('type is unknown %s', typ))

	val.timestamp = val.timestamp or val.etime
	val.flag = val.flag or self:value_flag(val.avg or val.value)

	if self._callback then
		self._callback(name, val, timestamp)
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

		local hour_list, err = self._db:read('HOUR', day_start_time + 1, self._start)
		if hour_list then
			self._hour_list:init(hour_list)
		else
			self:log('error', err)
		end

		local last_hour_item = self._hour_list:last()
		local hour_start_time = last_hour_item and last_hour_item.etime or day_start_time
		self:debug('load min data since', os.date('%c', hour_start_time))

		local min_list, err = self._db:read('MIN', hour_start_time + 1, self._start)
		if min_list then
			self._min_list:init(min_list)
		else
			self:log('error', err)
		end

		local last_min_item = self._min_list:last()
		local min_start_time = last_min_item and last_min_item.etime or hour_start_time
		self:debug('load sample data since', os.date('%c', min_start_time))

		local sample_list, err = self._db:read_samples(min_start_time + 0.001, self._start)
		if sample_list then
			self._sample_list:init(sample_list)
			local first_sample = self._sample_list:first()
			if first_sample then
				self:debug('loaded first sample', os.date('%c', math.floor(first_sample.timestamp)))
			end
		else
			self:log('error', err)
		end
	end
end

function base:push(value, timestamp)
	assert(nil, "Not implemented")
end

function base:sample_meta()
	assert(nil, "Not implemented")
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

function base:push_rdata(timestamp, value, flag, now)
	local val = {timestamp=timestamp, value=value, flag=flag}
	val = self:on_value(mgr.TYPES.RDATA, val, now)
	if self._db then
		return self:_db_write(type_names[mgr.TYPES.RDATA], val)
	else
		return true
	end
end

function base:on_trigger(typ, now, duration)
	local now = math.floor(now)
	if (self._type_mask & typ) == typ then
		if typ == mgr.TYPES.MIN then
			assert(self.on_min_trigger)
			assert(duration % 60 == 0)
			local val, err = self:on_min_trigger(now, duration)
			if val then
				self:on_value(mgr.TYPES.MIN, val, now)
			end
		end
		if typ == mgr.TYPES.HOUR then
			assert(self.on_hour_trigger)
			assert(duration % 3600 == 0)
			local val = self:on_hour_trigger(now, duration)
			if val then
				self:on_value(mgr.TYPES.HOUR, val, now)
			end
		end
		if typ == mgr.TYPES.DAY then
			assert(self.on_day_trigger)
			assert(duration % (3600 * 24) == 0)
			local val = self:on_day_trigger(now, duration)
			if val then
				self:on_value(mgr.TYPES.DAY, val, now)
			end
		end
		return true
	else
		return nil, "Unexpected trigger type"..typ
	end
end

--- Query data by etime
function base:query_min_data(start_time, end_time)
	local first = self._min_list:first()
	if first and first.etime < start_time then
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
		return self._min_list:query(start_time, end_time)
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
