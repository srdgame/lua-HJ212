local simple = require 'hj212.params.simple'
local tag_info = require 'hj212.tags.info'

local tv = simple:subclass('hj212.params.tag_value')

local tv.static.DEFAULT_FMT = 'N32'

local TAGS = tag_info
local TAGS_FMT = {}

local function get_tag_format(name)
	local p = TAGS_FMT[name]
	if p then
		return p
	end

	local tag = nil
	for k, v in pairs(TAGS) do
		if k == name then
			tag = v
			break
		end
		if string.len(k) == string.len(name) then
			local km = nil
			if string.sub(k, -2) == 'xx' then
				km = string.sub(k, 1, -3)..'(%d%d)'
			else
				if string.sub(k, -1) == 'x' then
					km = string.sub(k, 1, -2)..'(%d)'
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

	local fmt = (tag and tag.format) and tag.format or tv.DEFAULT_FMT
	p = simple.EASY('hj212.params.tags.'..name, fmt)

	TAGS_FMT[name] = p

	return p
end

function tv:initialize(name, value)
	local fmt = get_tag_format(name)
	base.initialize(name, value, fmt)
end

return tv
