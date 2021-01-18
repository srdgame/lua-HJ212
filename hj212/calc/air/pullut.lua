local class = require 'middleclass'
local mgr = require 'hj212.calc.manager'
local base = require 'hj212.calc.base'

local pullut = class('hj212.calc.helper.pullut')

function pullut:initialize(pullut, pullut_flow)
	self._pullut = pullut
	self._flow = pullut_flow
end

function pullut:__call(typ, val, now)
	assert(self._flow)
	if typ == mgr.TYPES.RDATA or typ == mgr.TYPES.SAMPLE then
		return val
	end

	local flow = self._flow
	local type_name = base.TYPE_NAMES[typ]
	local fn = 'query_'..string.lower(type_name)
	assert(flow[fn], 'Missing function:'..fn)

	local cou_value = flow[fn](flow, val.etime)
	if cou_value then
		val.cou = cou_value.cou * val.avg * (10 ^ -6)
	else
		self._pullut:log('debug', 'No COU base value')
	end

	return val
end

return pullut
