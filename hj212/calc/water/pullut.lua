local class = require 'middleclass'
local mgr = require 'hj212.calc.manager'
local base = require 'hj212.calc.base'

local pullut = class('hj212.calc.helper.pullut')

function pullut:initialize(pullut, flow)
	assert(pullut)
	assert(flow)
	self._pullut = pullut
	self._flow = flow
end

function pullut:__call(typ, val, now)
	local flow = self._flow
	if typ == mgr.TYPES.SAMPLE then
		local cou_val = flow:sample_last()
		if not cou_val then
			val.cou = 0
		else
			val.cou = cou_val.cou * val.value * (10 ^ -3)
		end
		return val
	end
	if typ == mgr.TYPES.RDATA then
		return val
	end

	local type_name = base.TYPE_NAMES[typ]
	local fn = 'query_'..string.lower(type_name)
	assert(flow[fn], 'Missing function:'..fn)

	local fval = flow[fn](flow, val.etime)
	if fval then
		if fval.cou == 0 then
			val.avg = 0
		else
			val.avg = (val.cou / fval.cou) * (10 ^ -3)
		end
	end

	return val
end

return pullut
