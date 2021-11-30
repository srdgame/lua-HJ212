local class = require 'middleclass'
local types = require 'hj212.types'
local mgr = require 'hj212.calc.manager'
local helper = require 'hj212.calc.helper'

local flow = class('hj212.calc.helper.flow')

function flow:initialize(flow_calc, min_interval)
	self._calc = flow_calc
	self._min_interval = min_interval

	local stime = os.time() -- math.floor(os.time() / (min_interval * 60)) * min_interval * 60

	self._last_sample_value = 0
	self._last_sample_time = stime
	self._last_rdata_value = 0
	self._last_rdata_time = stime
end

function flow:__call(typ, val, now)
	if typ == mgr.TYPES.SAMPLE then
		if (now - self._last_sample_time) > (self._min_interval * 60) then
			self._last_sample_value = 0
		end

		val.cou = self._last_sample_value * (now - self._last_sample_time) / 1000 -- L to m^3
		if helper.flag_can_calc(val.flag) then
			--assert(now ~= self._last_sample_time)
			self._last_sample_value = val.value
			self._last_sample_time = now
		else
			-- clear val.cou???
		end
	elseif typ == mgr.TYPES.RDATA then
		if (now - self._last_rdata_time) > (self._min_interval * 60) then
			self._last_rdata_value = 0
		end

		val.cou = self._last_rdata_value * (now - self._last_rdata_time) / 1000 -- L to m^3
		if helper.flag_can_calc(val.flag) then
			--assert(now ~= self._last_rdata_time)
			self._last_rdata_value = val.value
			self._last_rdata_time = now
		else
			-- clear val.cou???
		end
	else
		--val.avg = val.cou / (val.etime - val.stime)
		--val.cou = val.avg * (val.etime - val.stime)
	end

	return val
end

return flow
