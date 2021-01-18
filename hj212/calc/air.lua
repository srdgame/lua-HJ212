local base = require 'hj212.calc.simple'
local mgr = require 'hj212.calc.manager'
local flow = require 'hj212.calc.air.flow'
local pullut = require 'hj212.calc.air.pullut'

local air = base:subclass('hj212.calc.air')

local Zs_ver = 1

function create_zs(calc)
	assert(calc)
	local zs_calc = calc
	return function (typ, val, now)
		assert(typ, 'Type missing')
		assert(val, 'Value missing')
		assert(now, 'Now missing')
		if typ == mgr.TYPES.SAMPLE then
			assert(val.value ~= nil, 'Value missing')
			val.value_z = zs_calc(val.value, now, 'SAMPLE')
		elseif typ == mgr.TYPES.RDATA then
			assert(val.value ~= nil, 'Value missing')
			val.value_z = zs_calc(val.value, now, 'RDATA')
		else
			--[[
			assert(val.avg ~= nil, 'AVG missing')
			assert(val.min ~= nil, 'MIN missing')
			assert(val.max ~= nil, 'MAX missing')
			val.avg_z = zs_calc(val.avg, now, 'AVG')
			val.min_z = zs_calc(val.min, now, 'MIN')
			val.max_z = zs_calc(val.max, now, 'MAX')
			]]--
		end
		return val
	end
end

function air:initialize(station, name, type_mask, min, max, zs_calc)
	base.initialize(self, station, name, type_mask, min, max)
	if name ~= 'a00000' then
		self._station:air(function(air)
			if air then
				local air_calc = air:cou_calc()
				self:push_pre_calc(air_calc)
				local calc = pullut:new(self, air_calc)
				self:push_value_calc(calc)
			else
				self:push_value_calc(flow:new(self))
			end
		end)
	else
		self:push_value_calc(flow:new(self))
	end

	if zs_calc then
		self:set_zs_calc(create_zs(zs_calc))
	end
end

return air
