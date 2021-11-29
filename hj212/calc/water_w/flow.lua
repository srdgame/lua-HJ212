local class = require 'middleclass'
local types = require 'hj212.types'
local helper = require 'hj212.calc.helper'
local mgr = require 'hj212.calc.manager'
local logger = require 'hj212.logger'

local flow = class('hj212.calc.helper.flow')

function flow:initialize(flow_calc, min_interval)
	self._calc = flow_calc
	self._min_interval = min_interval

	self._last_sample_value = 0
	self._last_rdata_value = 0

	local stime = os.time() -- math.floor(os.time() / (min_interval * 60)) * min_interval * 60
	self:reset(stime)
end

function flow:reset(now)
	assert(now)
	self._last_sample_time = now
	self._last_rdata_time = now
end

function flow:last_sample_value()
	return self._last_sample_value
end

function flow:__call(typ, val, now)
	if typ == mgr.TYPES.SAMPLE then
		if (now - self._last_sample_time) > (self._min_interval * 60) then
			self._last_sample_value = 0
		end

		val.cou = self._last_sample_value * (now - self._last_sample_time)
		if helper.flag_can_calc(val.flag) then
			-- logger.log('debug', 'water.flow', 'cou', val.cou, 'value', val.value, 'time', now - self._last_sample_time)
			self._last_sample_value = val.value
			self._last_sample_time = now
		end
	elseif typ == mgr.TYPES.RDATA then
		if (now - self._last_rdata_time) > (self._min_interval * 60) then
			self._last_rdata_value = 0
		end

		val.cou = self._last_rdata_value * (now - self._last_rdata_time)
		if helper.flag_can_calc(val.flag) then
			self._last_rdata_value = val.value
			self._last_rdata_time = now
		end
	elseif typ == mgr.TYPES.MIN then
		val.cou = val.cou / 1000
	else
		-- Nothing to do
	end

	return val
end

return flow
