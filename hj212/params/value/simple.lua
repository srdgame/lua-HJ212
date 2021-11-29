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
			local i, f = string.match(fmt, 'N(%d*)%.?(%d*)')
			i = tonumber(i)
			f = tonumber(f)
			assert(i)
			assert(val)
			if f then
				local ffmt = '%.'..f..'f'
				return string.format(ffmt, val)
			else
				return string.format('%.0f', val)
			end
		end,
		decode = function(fmt, raw)
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
		self._value = raw
		return string.len(raw)
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
