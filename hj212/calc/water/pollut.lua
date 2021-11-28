local class = require 'middleclass'
local mgr = require 'hj212.calc.manager'
local base = require 'hj212.calc.base'
local logger = require 'hj212.logger'
local helper = require 'hj212.calc.helper'

local pollut = class('hj212.calc.helper.pollut')

function pollut:initialize(pollut, flow)
	assert(pollut)
	assert(flow)
	self._pollut = pollut
	self._flow = flow
	self:reset(os.time())
end

function pollut:reset(now)
	assert(now)
	self._last_sample_time = now
end

function pollut:last_sample_value()
	assert(false, "should not been called")
end

function pollut:__call(typ, val, now)
	local flow = self._flow

	if typ == mgr.TYPES.SAMPLE then
		local cou_val = flow:sample_cou(self._last_sample_time, now)
		if cou_val == 0 then
			val.cou = 0
		else
			val.cou = cou_val * val.value / 1000
			-- logger.log('debug', 'water.'..self._pollut._id, 'cou', val.cou, 'flow_cou', cou_val, 'value', val.value)
			if val.value_z then
				val.cou_z = cou_val * val.value_z / 1000
			end
		end

		if helper.flag_can_calc(val.flag) then
			self._last_sample_time = now
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
		local flow_cou = math.floor(fval.cou * 10000) / 10000
		if flow_cou < 0.001 then
			logger.log('warning', 'flow cou is zero', self._pollut._id)
			val.avg = 0
			if val.avg_z then
				val.avg_z = 0
			end
		else
			local val_cou = math.floor(val.cou * 10000000) / 10000000
			val.avg = (val_cou / flow_cou) * 1000
			-- logger.log('debug', 'water.'..self._pollut._id, 'cou', val.cou, 'flow_cou', fval.cou, 'avg', val.avg, 'min', val.min, 'max', val.max)
			if val.cou_z then
				local val_cou_z = math.floor(val.cou_z * 10000000) / 10000000
				val.avg_z = (val_cou_z / flow_cou) * 1000
			end
		end
	else
		self._pollut:log('error', 'No COU value of water Flow', type_name, val.etime)
	end

	return val
end

return pollut
