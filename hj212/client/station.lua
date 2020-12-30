local class = require 'middleclass'
local utils_sort = require 'hj212.utils.sort'
local cems = require 'hj212.client.station.cems'
local waitable = require 'hj212.client.station.waitable'

local station = class('hj212.client.station')

function station:initialize(system, id, sleep_func)
	assert(system, 'System code missing')
	assert(id, 'Device id missing')
	assert(sleep_func, 'Sleep function missing')
	self._system = tonumber(system)
	self._id = id
	self._sleep_func = sleep_func
	self._tag_list = {}
	self._meters = {}
	self._cems = cems:new(self)
	self._water = waitable:new(self, 'w00000')
	self._air = waitable:new(self, 'a00000')
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

function station:water()
	return self._water
end

function station:air()
	return self._air
end

function station:find_tag(name)
	return self._tag_list[name]
end

function station:find_tag_meter(name)
	local tag = self._tag_list[name]
	if tag then
		return tag:meter()
	end
	return nil, "Not found"
end

function station:tags()
	return self._tag_list
end

function station:init(calc_mgr)
	utils_sort.for_each_sorted_key(self._tag_list, function(tag)
		tag:init(calc_mgr)
	end)
end

function station:add_meter(meter)
	assert(meter)
	table.insert(self._meters, meter)
	for name, tag in pairs(meter:tag_list()) do
		assert(self._tag_list[name] == nil)
		self._tag_list[name] = tag
	end
end

--- Tags value
function station:set_tag_value(name, value, timestamp)
	assert(name ~= nil)
	assert(value ~= nil)
	assert(timestamp ~= nil)
	local tag = self._tag_list[name]
	if tag then
		return tag:set_value(value, timestamp)
	end
	return nil, "No such tag:"..name
end

function station:rdata(now, save)
	local data = {}
	for _, tag in pairs(self._tag_list) do
		if tag:upload() then
			local d = tag:query_rdata(now, save)
			if d then
				data[#data + 1] = d
			end
		end
	end
	return data
end

function station:min_data(start_time, end_time)
	local data = {}
	for _, tag in pairs(self._tag_list) do
		if tag:upload() then
			local vals = tag:query_min_data(start_time, end_time)
			table.move(vals, 1, #vals, #data + 1, data)
		end
	end
	return data
end

function station:hour_data(start_time, end_time)
	local data = {}
	for _, tag in pairs(self._tag_list) do
		if tag:upload() then
			local vals = tag:query_hour_data(start_time, end_time)
			table.move(vals, 1, #vals, #data + 1, data)
		end
	end
	return data
end

function station:day_data(start_time, end_time)
	local data = {}
	for _, tag in pairs(self._tag_list) do
		if tag:upload() then
			local vals = tag:query_day_data(start_time, end_time)
			table.move(vals, 1, #vals, #data + 1, data)
		end
	end
	return data
end

function station:info_data()
	local data = {}
	for _, info in pairs(self._info_list) do
		local value, timestamp = info:get_value()
		data[#data + 1] = {
			value = value,
			timestamp = timestamp,
		}
	end
	return data
end

return station
