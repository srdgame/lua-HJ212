local class = require 'middeclass'

local mgr = class('hj212.client.calc.manager')

mgr.static.TYPES = {
	MIN = 1,
	HOUR = 2,
	DAY = 4,
}

function mgr:initialize()
	self._min_list = {}
	self._hour_list = {}
	self._day_list = {}
end

function mgr:reg(type_mask, calc)
	if (typ & mgr.TYPES.MIN) = mgr.TYPES.MIN then
		table.insert(self._min_list, calc)
	end
	if (typ & mgr.TYPES.HOUR) == mgr.TYPES.HOUR then
		table.insert(self._hour_list, calc)
	end
	if (typ & mgr.TYPES.DAY) == mgr.TYPES.DAY then
		table.insert(self._day_list, calc)
	end	
end

local function unreg_list_obj(list, val)
	for i, v in ipairs(list) do
		if v == val then
			table.remove(list, i)
		end
	end
end

function mgr:unreg(type_mask, calc)
	if (typ & mgr.TYPES.MIN) = mgr.TYPES.MIN then
		unreg_list_obj(self._min_list, now)
	end
	if (typ & mgr.TYPES.HOUR) == mgr.TYPES.HOUR then
		unreg_list_obj(self._hour_list, now)
	end
	if (typ & mgr.TYPES.DAY) == mgr.TYPES.DAY then
		unreg_list_obj(self._day_list, now)
	end	
end

local function on_trigger_list(calc_list, typ, now)
	for _, v in ipairs(calc_list) do
		local r, err = v:on_trigger(typ, now)
		if not r then
			print(err)
		end
	end
end

-- 
-- type: TYPES
-- now: time in seconds
function mgr:trigger(typ, now)
	if (typ & mgr.TYPES.MIN) = mgr.TYPES.MIN then
		on_trigger_list(self._min_list, mgr.TYPES.MIN, now)
	end
	if (typ & mgr.TYPES.HOUR) == mgr.TYPES.HOUR then
		on_trigger_list(self._hour_list, mgr.TYPES.HOUR, now)
	end
	if (typ & mgr.TYPES.DAY) == mgr.TYPES.DAY then
		on_trigger_list(self._day_list, mgr.TYPES.DAY, now)
	end
end

return mgr