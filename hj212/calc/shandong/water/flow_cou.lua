local class = require 'middleclass'
local mgr = require 'hj212.calc.manager'
local base = require 'hj212.calc.base'

local flow = class('hj212.calc.shandong.water.flow_cou')

function flow:initialize(flow_calc, flow_cou_calc)
	self._calc = flow_calc
	self._cou_calc = flow_cou_calc
end

function flow:__call(typ, val, now)
	assert(self._cou_calc)
	if typ == mgr.TYPES.RDATA or typ == mgr.TYPES.SAMPLE then
		return val
	end

	local cou_calc = self._cou_calc
	local type_name = base.TYPE_NAMES[typ]
	local fn = 'query_'..string.lower(type_name)
	assert(cou_calc[fn], 'Missing function:'..fn)

	if val.etime ~= now then
		self._calc:log('error', 'water.flow_cou etime~=now', type_name, now, val.etime, val.timestamp)
	end

	local fval = cou_calc[fn](cou_calc, val.etime)
	if fval then
		val.cou = fval.cou
	else
		self._calc:log('debug', 'No COU value of Water Cou', type_name, val.etime)
	end

	return val
end

return flow 
