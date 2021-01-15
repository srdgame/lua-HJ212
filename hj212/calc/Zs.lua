local mgr = require 'hj212.calc.manager'

local Zs = {}

local Zs_ver = 1

function Zs:sample_meta()
	local meta, ver = self._wrap_z.sample_meta(self)

	table.insert(meta, {
		name = 'value_z', type = 'DOUBLE', not_null = false 
	})

	return meta, (Zs_ver << 16) + ver
end

function Zs:on_value(typ, val, now)
	local calc = self._wrap_z.calc
	if typ == mgr.TYPES.RDATA then
		val.value_z = calc(val.value, 'RDATA')
	else
		val.avg_z = calc(val.avg, 'AVG')
		val.min_z = calc(val.min, 'MIN')
		val.max_z = calc(val.max, 'MAX')
	end
	return self._wrap_z.on_value(self, typ, val, now)
end

return function(base, calc)
	assert(base._wrap_z == nil)

	local wrap = { calc = calc }
	for k, v in pairs(Zs) do
		wrap[k] = base[k]
		base[k] = v
	end
	base._wrap_z = wrap

	return base
end
