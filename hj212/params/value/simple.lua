local base = require 'hj212.params.value.base'

local simple = base:subclass('hj212.params.value.simple')

local parsers = {
	C = {
		encode = function(fmt, val)
			local count = tonumber(fmt:sub(2))
			assert(count)

			local raw = tostring(val)
			if string.len(raw) > count then
				return raw:sub(0 - count)
			end
			return raw
		end,
		decode = function(fmt, raw)
			local count = tonumber(fmt:sub(2))
			assert(count)

			local val = raw
			if string.len(val) > count then
				val = val:sub(0 - count)
			end
			return val, string.len(val)
		end,
	},
	N = {
		encode = function(fmt, val)
			local i, f = string.match(fmt, 'N(%d+).?(%d*)')
			i = tonumber(i)
			f = tonumber(f)
			assert(i)
			assert(val)
			local raw = nil
			raw = string.format('%d', math.floor(val + 0.1))
			if string.len(raw) > i then
				raw = string.sub(raw, 0 - i)
			end
			if f and string.len(f) > 0 then
				val = (val % 1) * (10 ^ f)
				local fraw = string.format('%d', math.floor(val))
				raw = raw..'.'..fraw
			end
			return raw
		end,
		decode = function(fmt, raw)
			--[[
			local i, f = string.match(fmt, 'N(%d+).?(%d*)')
			i = tonumber(i)
			f = tonumber(f)
			assert(i)
			local raw, index = string.match(raw, '^(%d+)()')
			assert(string.len(raw) <= i)

			if f and index < string.len(raw) then
				if string.sub(raw, index) == '.' then
					sub_raw = string.match(raw, '^(%d+)', index)
					if string.len(sub_raw) > f then
						sub_raw = string.sub(sub_raw, 0 - f)
					end
					index = index + string.len(sub_raw) + 1
					raw = raw..'.'..sub_raw
				else
					assert(false, "Error string")
				end
			end

			return tonumber(raw), index
			]]
			return tonumber(raw), string.len(raw)
		end,
	},
}

function simple:initialize(name, value, fmt)
	base.initialize(self, name, value)
	self._format = fmt
end

function simple:format()
	return self._format
end

function simple:encode()
	assert(self._value)
	if not self._format then
		return tostring(self._value)
	end

	local fmt = string.sub(self._format, 1, 1)
	local parser = assert(parsers[fmt])

	return parser.encode(self._format, self._value)
end

function simple:decode(raw)
	if not self._format then
		return tonumber(raw) or raw
	end

	local fmt = string.sub(self._format, 1, 1)
	local parser = assert(parsers[fmt])

	self._value, index = parser.decode(self._format, raw)
	return index
end

simple.static.EASY = function(pn, fmt)
	local sub = simple:subclass(pn)
	function sub:initialize(name, value)
		simple.initialize(self, name, value, fmt)
	end
	return sub
end

return simple
