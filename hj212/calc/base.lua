local class = require 'middleclass'
local mgr = require 'hj212.calc.manager'
local date = require 'date'

local base = class('hj212.calc.base')

base.static.TYPES = mgr.static.TYPES

function base:initialize(callback, db)
	self._callback = callback
	self._db = db

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

return base
