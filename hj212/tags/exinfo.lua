local EX_TAGS = {}
local logger = require 'hj212.logger'

return {
	add = function(id, desc, format, org_id, unit, cou_unit)
		print(id, desc, format, org_id, unit, cou_unit)
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
	end,
	find = function(id)
		return EX_TAGS[id]
	end
}
