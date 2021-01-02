local class = require 'middleclass'

local list = class('hj212.calc.data_list')

function list:initialize(time_key, insert_callback)
	self._key = time_key
	self._keys = {}
	self._vals = {}
	self._insert_callback = insert_callback
end

function list:init(vals, cb)
	self:clean()
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
	local time = data[self._key]
	local keys = self._keys
	local vals = self._vals

	if keys[time] ~= nil then
		print('EEEEEEEEEEEEEE')
		return nil, "Duplicated time found"
	end

	if #vals > 0 then
		local last_time = vals[#vals][key]
		assert(last_time < time, "Last time bigger than current. Last:"..last_time.."\tTime:"..time)
	end

	keys[time] = data
	vals[#vals + 1] = data

	if cb then
		cb(data)
	end
	return true
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