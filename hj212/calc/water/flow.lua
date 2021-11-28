local class = require 'middleclass'
local types = require 'hj212.types'
local mgr = require 'hj212.calc.manager'
local logger = require 'hj212.logger'

local flow = class('hj212.calc.helper.flow')

function flow:initialize(calc, sample_t, rdata_t)
	self._calc = calc
	self._last_sample_value = 0
	self._last_sample_time = os.time() - (sample_t or 5) -- Default 5 seconds
	self._last_rdata_value = 0
	self._last_rdata_time = os.time() - (rdata_r or 30) -- Default 30 seconds
end

local function flag_can_calc(flag)
	if flag == nil then
		return true
	end
	if flag == types.FLAG.Normal or flag == types.FLAG.Overproof then
		return true
	end
	return false
end

function flow:__call(typ, val, now)
	if typ == mgr.TYPES.SAMPLE then
		if flag_can_calc(val.flag) then
			assert(now ~= self._last_sample_time)
			val.cou = self._last_sample_value * (now - self._last_sample_time) * 0.001
			-- logger.log('debug', 'water.flow', 'cou', val.cou, 'value', val.value, 'time', now - self._last_sample_time)
			self._last_sample_value = val.value
			self._last_sample_time = now
		end
	elseif typ == mgr.TYPES.RDATA then
		if flag_can_calc(val.flag) then
			assert(now ~= self._last_rdata_time)
			val.cou = self._last_rdata_value * (now - self._last_rdata_time) * 0.001
			self._last_rdata_value = val.value
			self._last_rdata_time = now
		end
	else
		-- Nothing to do
	end

	return val
end

return flow
