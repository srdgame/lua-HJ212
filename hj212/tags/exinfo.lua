local EX_TAGS = {}
local logger = require 'hj212.logger'

local _M = {}

_M.add = function(id, desc, format, org_id, unit, cou_unit)
	--print(id, desc, format, org_id, unit, cou_unit)
	assert(id)
	assert(desc)
	if EX_TAGS[id] then
		logger.error("Duplicated id found", id)
		return
	end
	EX_TAGS[id] = {
		id = id,
		desc = desc,
		format = format,
		org_id = org_id,
		unit = unit,
		cou_unit = cou_unit
	}
end

_M.load = function(cate)
	local info_list = require 'hj212.tags.'..cate..'.info'
	for k, v in pairs(info_list) do
		_M.add(k, v.desc, v.format, v.org_id, v.unit, v.cou_unit)
	end
end

_M.find = function(id)
	return EX_TAGS[id]
end

return _M
