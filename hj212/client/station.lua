local class = require 'middleclass'
local cems = require 'hj212.client.station.cems'

local station = class('hj212.client.station')

function station:initialize(system, id, Kv)
	self._system = tonumber(system)
	self._id = id
	self._tag_list = {}
	self._meters = {}
	self._cems = cems:new(self, Kv or 1)
end

function station:system()
	return self._system
end

function station:id()
	return self._id
end

function station:meters()
	return self._meters
end

function station:cems()
	return self._cems
end

function station:water_tag()
	return self:find_tag('w00000')
end

function station:air_tag()
	return self:find_tag('a00000')
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
	local tag = self._tag_list[name]
	if tag then
		return tag:set_value(value, timestamp)
	end
	return nil, "No such tag:"..name
end

function station:rdata(now)
	local data = {}
	for _, tag in pairs(self._tag_list) do
		data[#data + 1] = tag:query_rdata(now)
	end
	return data
end

function station:min_data(start_time, end_time)
	local data = {}
	for _, tag in pairs(self._tag_list) do
		local vals = tag:query_min_data(start_time, end_time)
		table.move(vals, 1, #vals, #data + 1, data)
	end
	return data
end

function station:hour_data(start_time, end_time)
	local data = {}
	for _, tag in pairs(self._tag_list) do
		local vals = tag:query_hour_data(start_time, end_time)
		table.move(vals, 1, #vals, #data + 1, data)
	end
	return data
end

function station:day_data(start_time, end_time)
	local data = {}
	for _, tag in pairs(self._tag_list) do
		local vals = tag:query_day_data(start_time, end_time)
		table.move(vals, 1, #vals, #data + 1, data)
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
