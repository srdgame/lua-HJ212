local logger = require 'hj212.logger'
local class = require 'middleclass'

local list = class('hj212.calc.data_list')

function list:initialize(time_key, insert_callback, max_count, drop_callback)
	self._key = time_key
	self._keys = {}
	self._vals = {}
	self._insert_callback = insert_callback
	self._max_count = max_count
	self._drop_callback = drop_callback
end

function list:init(vals, cb)
	self:clean()
	for _, v in ipairs(vals) do
		self:_append(v, cb)
	end
end

function list:append_list(vals)
	for _, v in ipairs(vals) do
		self:_append(v, cb)
	end
end

function list:append(data)
	local cb = self._insert_callback
	return self:_append(data, cb)
end

function list:_append(data, cb)
	local key = self._key
	if not data[self._key] then
		logger.debug('EEEEEEEEEEEEeeee')
		return
	end
	local time = data[self._key]
	local keys = self._keys
	local vals = self._vals

	if keys[time] ~= nil then
		logger.debug('EEEEEEEEEEEEEE')
		return nil, "Duplicated time found"
	end

	if #vals > 0 then
		local last_time = vals[#vals][key]
		if last_time >= time then
			logger.log('warning', "Last time bigger than current. Last:"..last_time.."\tTime:"..time)
			return nil, "Time error"
		end
	end

	local err
	if cb then
		data, err = cb(data)
		if not data then
			return nil, err
		end
	end

	keys[time] = data
	vals[#vals + 1] = data

	if self._max_count ~= nil then
		if #vals > self._max_count then
			local val = vals[1]
			table.remove(vals, 1)
			if self._drop_callback then
				self._drop_callback(val)
			end
		end
	end

	return data
end

function list:find(key)
	return self._keys[key]
end

function list:query(stime, etime, time_key)
	local key = time_key or self._key

	local data = {}
	for _, v in ipairs(self._vals) do
		local time = v[key]
		if time >= stime and time <= etime then
			table.insert(data, v)
		end
		if time > etime then
			break
		end
	end
	return data
end

function list:first()
	return self._vals[1]
end

function list:last()
	local vals = self._vals
	return vals[#vals]
end

function list:clean()
	self._vals = {}
	self._keys = {}
end

function list:pop(etime, time_key)
	local key = self._key
	local tkey = time_key or key
	assert(tkey)
	assert(key)
	local vals = self._vals
	if #vals == 0 then
		return {}
	end

	local last_time = vals[#vals][tkey]

	if last_time <= etime then
		self:clean()
		return vals
	end

	self._vals = {}
	self._keys = {}

	for i = 1, #vals do
		local v = vals[i]
		local time = v[tkey]
		if time > etime then
			self:_append(v)
			vals[i] = nil
		end
	end

	return vals
end

return list
