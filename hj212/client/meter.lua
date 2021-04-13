local class = require 'middleclass'

local meter = class('hj212.client.meter')

function meter:initialize(sn, poll_list)
	assert(sn, 'Device SN missing')
	assert(poll_list, 'Device polls missing')
	self._sn = sn

	for k, v in pairs(poll_list) do
		v:set_meter(self)
	end
	self._poll_list = poll_list
	self._flag = nil
end

function meter:sn()
	return self._sn
end

function meter:find_poll(id)
	return self._poll_list[id]
end

function meter:poll_list()
	return self._poll_list
end

function meter:set_flag(flag)
	self._flag = flag
end

function meter:get_flag()
	return self._flag
end


function meter:init(err_cb)
	--[[
	for k, v in pairs(self._info_list) do
		local r, err = v:init()
		if not r then
			err_cb(v:info_name(), err)
		end
	end
	]]--
end

--- Tags value
function meter:set_poll_value(id, value, timestamp, value_z, flag, quality)
	local poll = self._poll_list[id]
	if poll then
		return poll:set_value(value, timestamp, value_z, flag, quality)
	end
	return nil, "No such poll:"..id
end

--- Tags info value
function meter:set_info_value(poll_id, info_list)
	local poll = self._poll_list[poll_id]
	if not poll then
		return nil, "No such poll:"..poll_id
	end

	return poll:set_info(info_list)
end

function meter:rdata(timestamp, readonly)
	local data = {}
	for _, poll in ipairs(self._poll_list) do
		local d = poll:query_rdata(timestamp, readonly)
		if d then
			data[#data + 1] = d
		end
	end
	return data
end

function meter:min_data(start_time, end_time)
	local data = {}
	for _, poll in ipairs(self._poll_list) do
		local vals = poll:query_min_data(start_time, end_time)
		table.move(vals, 1, #vals, #data + 1, data)
	end
	return data
end

function meter:hour_data(start_time, end_time)
	local data = {}
	for _, poll in ipairs(self._poll_list) do
		local vals = poll:query_hour_data(start_time, end_time)
		table.move(vals, 1, #vals, #data + 1, data)
	end
	return data
end

function meter:day_data(start_time, end_time)
	local data = {}
	for _, poll in ipairs(self._poll_list) do
		local vals = poll:query_day_data(start_time, end_time)
		table.move(vals, 1, #vals, #data + 1, data)
	end
	return data
end

function meter:info_data()
	local data = {}
	for _, poll in ipairs(self._poll_list) do
		local d, err = poll:info_data()
		if d then
			table.insert(data, d)
		end
	end
	return data
end

return meter
