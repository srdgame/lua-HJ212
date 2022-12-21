local class = require 'middleclass'
local mgr = require 'hj212.calc.manager'
local base = require 'hj212.calc.base'
local helper = require 'hj212.calc.helper'

local pollut = class('hj212.calc.water.pollut')

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
		self._pollut:log('error', 'air.pollut etime~=now', type_name, now, val.etime, val.timestamp)
	end

	local fval = flow[fn](flow, val.etime)
	if fval and helper.flag_can_calc(fval.flag) then
		if typ == mgr.TYPES.MIN then
			val.cou = (fval.cou or 0) * val.avg * (10 ^ -3)  -- calculate cou from avg
			if val.avg_z then
				val.cou_z = (fval.cou or 0) * val.avg_z * (10 ^ -3)
			end
		else
			if fval.cou > 0.000001 then
				-- kg -> mg : 1000 * 1000
				-- m^3 -> L : 1000
				val.avg = ((val.cou or 0) * 1000) / fval.cou  --- calculate avg from cou / flow_cou
				if val.cou_z then
					val.avg_z = ((val.cou_z or 0) * 1000) / fval.cou
				end
			else
				val.avg = 0
				if val.cou_z then
					val.avg_z = 0
				end
			end
		end
	else
		self._pollut:log('debug', 'No COU value of Water Flow', type_name, val.etime)
		val.cou = 0
		val.avg = 0
		if val.cou_z or val.avg_z then
			val.cou_z = 0
			val.avg_z = 0
		end
	end

	return val
end

return pollut
