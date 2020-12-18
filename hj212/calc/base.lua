local class = require 'middleclass'
local mgr = require 'hj212.calc.manager'
local date = require 'date'

local base = class('hj212.calc.base')

base.static.TYPES = mgr.static.TYPES
local type_names = {}
for k, v in pairs(mgr.static.TYPES) do
	type_names[v] = k
end
base.static.TYPE_NAMES = type_names

function base:initialize(callback, db)
	local callback = callback
	self._db = db
	self._callback = function(typ, val)
		if db then
			local name = type_names[typ]
			if name then
				db:write(name, {val})
			end
		end
		if callback then
			callback(typ, val)
		end
	end

	self._start = os.time()
	--- Sample data list for minutes calculation
	self._sample_list = {}
	--- Calculated
	self._min_list = {}
	self._hour_list = {}
	self._day = nil
end

function base:day_start()
	return os.time() + date():getbias() * 60
end

function base:init()
	if self._db then
		local day_start_time = self:day_start()
		self._hour_list = self._db:read('HOUR', day_start_time, self._start)
		local hour_start_time = day_start_time
		if #self._hour_list > 0 then
			hour_start_time = self._hour_list[#self._hour_list].etime
		end
		self._min_list = self._db:read('MIN', hour_start_time, self._start)
		local min_start_time = hour_start_time
		if #self._min_list > 0 then
			min_start_time = self._min_list[#self._min_list].etime
		end
		self._sample_list = self._db:read('SAMPLE', min_start_time, self._start)
	end
end

function base:save_sample(timestamp, value, ...)
	if self._db then
		self._db:push_sample(timestamp, value, ...)
	end
end

function base:push(value, timestamp)
	assert(nil, "Not implemented")
end

function base:set_mask(mask)
	self._type_mask = mask
end

function base:on_trigger(typ, now, duration)
	print(typ, now, duration)
	if (self._type_mask & typ) == typ then
		if typ == mgr.TYPES.MIN then
			assert(self.on_min_trigger)
			local val = self:on_min_trigger(now, duration)
			self._callback(mgr.TYPES.MIN, val)
		end
		if typ == mgr.TYPES.HOUR then
			assert(self.on_hour_trigger)
			local val = self:on_hour_trigger(now, duration)
			self._callback(mgr.TYPES.HOUR, val)
		end
		if typ == mgr.TYPES.DAY then
			assert(self.on_day_trigger)
			local val = self:on_day_trigger(now, duration)
			self._callback(mgr.TYPES.DAY, val)
		end
	else
		return nil, "Unexpected trigger type"..typ
	end
end

function base:get_current_data(list, start_time, end_time)
	local data = {}
	for i = #list, #list, -1 do
		local v = list[i]
		if v.stime >= start_time and v.stime <= end_time then
			data[#data + 1] = v
		end
		if v.stime < start_time then
			break
		end
	end
	return data
end

function base:query_min_data(start_time, end_time)
	if start_time >= self:day_start() then
		return self:get_current_data(self._min_list, start_time, end_time)
	end
	-- TODO:
end

function base:query_hour_data(start_time, end_time)
	if start_time >= self:day_start() then
		return self:get_current_data(self._hour_list, start_time, end_time)
	end
	-- TODO:
end

function base:query_day_data(start_time, end_time)
	if end_time == start_time and end_time == self._day.etime then
		return {self._day}
	end
	-- TODO:
end

return base
