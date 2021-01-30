local class = require 'middleclass'
local mgr = require 'hj212.calc.manager'
local base = require 'hj212.calc.base'

local pollut = class('hj212.calc.helper.pollut')

function pollut:initialize(pollut, flow)
	assert(pollut)
	assert(flow)
	self._pollut = pollut
	self._flow = flow
end

function pollut:__call(typ, val, now)
	local flow = self._flow
	if typ == mgr.TYPES.SAMPLE then
		local cou_val = flow:sample_last()
		if not cou_val then
			val.cou = 0
		else
			val.cou = cou_val.cou * val.value * (10 ^ -3)
			if val.value_z then
				val.cou_z = cou_val.cou * val.value_z * (10 ^ -3)
			end
		end
		return val
	end
	if typ == mgr.TYPES.RDATA then
		--- Not calc for cou and cou_z as RDATA is not using for COU calculation
		return val
	end

	local type_name = base.TYPE_NAMES[typ]
	local fn = 'query_'..string.lower(type_name)
	assert(flow[fn], 'Missing function:'..fn)

	local fval = flow[fn](flow, val.etime)
	if fval then
		if fval.cou == 0 then
			val.avg = 0
			if val.avg_z then
				val.avg_z = 0
			end
		else
			val.avg = (val.cou / fval.cou) * (10 ^ -3)
			if val.cou_z then
				val.avg_z = (val.cou_z / fval.cou) * (10 ^ -3)
			end
		end
	end

	return val
end

return pollut
