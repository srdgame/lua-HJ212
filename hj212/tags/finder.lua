local TAGS = require 'hj212.tags.info'
local EX_TAGS = require 'hj212.tags.exinfo'

local TAG_INFO = {}

return function(id)
	local info = TAG_INFO[id] or EX_TAGS.find(id)
	if info then
		return info
	end

	local tag = nil
	for _, v in ipairs(TAGS) do
		local v_id = v.id
		if v_id == id then
			tag = v
			break
		end
		if v.org_id and v.org_id == id then
			tag = v
			break
		end
		if string.len(v_id) == string.len(id) then
			local km = nil
			if string.sub(v_id, -2) == 'xx' then
				km = string.sub(v_id, 1, -3)..'(%d%d)'
			else
				if string.sub(v_id, -1) == 'x' then
					km = string.sub(v_id, 1, -2)..'(%d)'
				end
			end
			if km then
				if string.match(id, km) then
					tag = v
					break
				end
			end
		end
	end

	if tag then
		TAG_INFO[id] = tag
		return tag
	end

	return nil
end

