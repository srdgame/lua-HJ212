local class = require 'middleclass'

local station = class('hj212.client.station')

function station:initialize(system, id)
	self._system = tonumber(system)
	self._id = id
	self._tag_list = {}
	self._meters = {}
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

function station:rdata()
	local data = {}
	for _, tag in ipairs(self._tag_list) do
		data[#data + 1] = tag:query_rdata()
	end
	return data
end

function station:min_data(start_time, end_time)
	local data = {}
	for _, tag in ipairs(self._tag_list) do
		local vals = tag:query_min_data(start_time, end_time)
		table.move(vals, 1, #vals, #data + 1, data)
	end
	return data
end

function station:hour_data(start_time, end_time)
	local data = {}
	for _, tag in ipairs(self._tag_list) do
		local vals = tag:query_hour_data(start_time, end_time)
		table.move(vals, 1, #vals, #data + 1, data)
	end
	return data
end

function station:day_data(start_time, end_time)
	local data = {}
	for _, tag in ipairs(self._tag_list) do
		local vals = tag:query_day_data(start_time, end_time)
		table.move(vals, 1, #vals, #data + 1, data)
	end
	return data
end

function station:info_data()
	local data = {}
	for _, info in ipairs(self._info_list) do
		local value, timestamp = info:get_value()
		data[#data + 1] = {
			value = value,
			timestamp = timestamp,
		}
	end
	return data
end

return station