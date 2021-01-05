local base = require 'hj212.params.value.simple'
local datetime = require 'hj212.params.value.datetime'
local tag_info = require 'hj212.tags.info'

local tv = base:subclass('hj212.params.value.tag')

local TAGS = tag_info
local TAGS_FMT = {}

local function get_tag_format(name)
	local fmt = TAGS_FMT[name]
	if fmt then
		return fmt
	end

	local tag = nil
	for _, v in ipairs(TAGS) do
		local v_name = v.name
		if v_name == name then
			tag = v
			break
		end
		if v.org_name and v.org_name == name then
			tag = v
			break
		end
		if string.len(v_name) == string.len(name) then
			local km = nil
			if string.sub(v_name, -2) == 'xx' then
				km = string.sub(v_name, 1, -3)..'(%d%d)'
			else
				if string.sub(v_name, -1) == 'x' then
					km = string.sub(v_name, 1, -2)..'(%d)'
				end
			end
			if km then
				if string.match(name, km) then
					tag = v
					break
				end
			end
		end
	end

	if tag then
		-- Quicker founder
		TAGS_FMT[name] = fmt
		return tag.format
	end

	return nil
end

function tv:initialize(name, value, fmt)
	local fmt = fmt or get_tag_format(name)
	base.initialize(self, name, value, fmt)
end

function tv:encode()
	if self._format == 'YYYYMMDDHHMMSS' then
		local d = datetime(self._name, self._value)		
		return d:encode()
	else
		return base.encode(self)
	end
end

function tv:decode(raw, index)
	if self._format == 'YYYYMMDDHHMMSS' then
		local d = datetime(self._name, self._value)		
		local index = d:encode(raw, index)
		self._value = d:value()
	else
		return base.encode(self, raw, index)
	end
end

return tv
