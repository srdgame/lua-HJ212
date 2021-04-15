local class = require 'middleclass'
local utils_sort = require 'hj212.utils.sort'
local cems = require 'hj212.client.station.cems'

local station = class('hj212.client.station')

function station:initialize(system, id, sleep_func)
	assert(system, 'System code missing')
	assert(id, 'Device id missing')
	assert(sleep_func, 'Sleep function missing')
	self._system = tonumber(system)
	self._id = id
	self._sleep_func = sleep_func
	self._handlers = {}
	self._settings = {}
	self._poll_list = {}
	self._meters = {}
	self._cems = cems:new(self)
	self._water = nil
	self._air = nil
	self._calc_mgr = nil
end

function station:set_handlers(handlers)
	self._handlers = handlers or {}
end

function station:set_settings(settings)
	--- Copy the settings table
	for k, v in pairs(settings) do
		self._settings[k] = v
	end
end

function station:get_setting(key)
	return self._settings[key]
end

function station:system()
	return self._system
end

function station:id()
	return self._id
end

function station:sleep(ms)
	return self._sleep_func(ms)
end

function station:meters()
	return self._meters
end

function station:cems()
	return self._cems
end

function station:water(func)
	if self._water then
		func(self._water)
	else
		self:wait_poll('w00000', function(poll)
			self._water = poll
			func(self._water)
		end)
	end
end

function station:air(func)
	if self._air then
		func(self._air)
	else
		self:wait_poll('a00000', function(poll)
			self._air = poll
			func(self._air)
		end)
	end
end

function station:wait_poll(name, func)
	assert(self._poll_waits, "Cannot call this function out of initing")
	table.insert(self._poll_waits, {
		poll = name,
		func = func
	})
end

function station:find_poll(name)
	return self._poll_list[name]
end

function station:find_poll_meter(name)
	local poll = self._poll_list[name]
	if poll then
		return poll:meter()
	end
	return nil, "Not found"
end

function station:polls()
	return self._poll_list
end

function station:calc_mgr()
	return self._calc_mgr
end

function station:init(calc_mgr, err_cb)
	assert(self._calc_mgr == nil)
	self._calc_mgr = calc_mgr
	self._poll_waits = {}

	for _, v in ipairs(self._meters) do
		v:init(err_cb)
	end

	utils_sort.for_each_sorted_key(self._poll_list, function(poll)
		local r, err = poll:init(self)
		if not r then
			err_cb(poll:id(), err)
		end
	end)

	local waits = self._poll_waits
	self._poll_waits = nil
	for _, v in ipairs(waits) do
		local poll = self:find_poll(v.poll)
		v.func(poll)
	end
end

function station:add_meter(meter)
	assert(meter)
	table.insert(self._meters, meter)
	for name, poll in pairs(meter:poll_list()) do
		assert(self._poll_list[name] == nil)
		self._poll_list[name] = poll
	end
end

--- Tags value
function station:set_poll_value(name, value, timestamp, value_z, flag, quality)
	assert(name ~= nil)
	assert(value ~= nil)
	assert(timestamp ~= nil)
	local poll = self._poll_list[name]
	if poll then
		return poll:set_value(value, timestamp, value_z, flag, quality)
	end
	return nil, "No such poll:"..name
end

function station:rdata(timestamp, readonly)
	local data = {}
	for _, poll in pairs(self._poll_list) do
		if poll:upload() then
			local d = poll:query_rdata(timestamp, readonly)
			if d then
				data[#data + 1] = d
			end
		end
	end
	return data
end

function station:min_data(start_time, end_time)
	local data = {}
	for _, poll in pairs(self._poll_list) do
		if poll:upload() then
			local vals = poll:query_min_data(start_time, end_time)
			if vals then
				table.move(vals, 1, #vals, #data + 1, data)
			end
		end
	end
	return data
end

function station:hour_data(start_time, end_time)
	local data = {}
	for _, poll in pairs(self._poll_list) do
		if poll:upload() then
			local vals = poll:query_hour_data(start_time, end_time)
			if vals then
				table.move(vals, 1, #vals, #data + 1, data)
			end
		end
	end
	return data
end

function station:day_data(start_time, end_time)
	local data = {}
	for _, poll in pairs(self._poll_list) do
		if poll:upload() then
			local vals = poll:query_day_data(start_time, end_time)
			if vals then
				table.move(vals, 1, #vals, #data + 1, data)
			end
		end
	end
	return data
end

function station:update_rdata_interval(interval)
	self._rdata_interval = interval
	if self._handlers.rdata_interval then
		local r, rr, err = pcall(self._handlers.rdata_interval, interval)
		if r then
			return rr, err
		end
		return nil, "Program failure!!"
	end
end

function station:update_min_interval(interval)
	self._min_interval = interval
	if self._handlers.min_interval then
		local r, rr, err = pcall(self._handlers.min_interval, interval)
		if r then
			return rr, err
		end
		return nil, "Program failure!!"
	end
end

function station:set_rdata_interval(interval)
	self._rdata_interval = interval
end

function station:rdata_interval()
	return self._rdata_interval
end

function station:set_min_interval(interval)
	self._min_interval = interval
end

function station:min_interval()
	return self._min_interval
end

return station
