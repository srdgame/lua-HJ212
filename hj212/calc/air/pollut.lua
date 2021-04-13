local class = require 'middleclass'
local mgr = require 'hj212.calc.manager'
local base = require 'hj212.calc.base'

local pollut = class('hj212.calc.helper.pollut')

function pollut:initialize(pollut, pollut_flow)
	self._pollut = pollut
	self._flow = pollut_flow
end

function pollut:__call(typ, val, now)
	assert(self._flow)
	if typ == mgr.TYPES.RDATA or typ == mgr.TYPES.SAMPLE then
		return val
	end

	local flow = self._flow
	local type_name = base.TYPE_NAMES[typ]
	local fn = 'query_'..string.lower(type_name)
	assert(flow[fn], 'Missing function:'..fn)

	if val.etime ~= now then
		print(type_name, now, val.etime, val.timestamp)
	end

	local cou_value = flow[fn](flow, val.etime)
	if cou_value then
		val.cou = cou_value.cou * val.avg * (10 ^ -6)
		if val.avg_z then
			val.cou_z = cou_value.cou * val.avg_z * (10 ^ -6)
		end
	else
		self._pollut:log('debug', 'No COU value of AIR Flow', type_name, val.etime)
	end

	return val
end

return pollut
