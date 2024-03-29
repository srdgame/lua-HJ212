local class = require 'middleclass'
local logger = require 'hj212.logger'
local has_queue, queue = pcall(require, 'skynet.queue')

local mgr = class('hj212.calc.manager')

mgr.static.TYPES = {
	SAMPLE = -1, -- hack for sample calc
	RDATA = 0, -- This not called by trigger only used for history saving
	MIN = 1,
	HOUR = 2,
	DAY = 4,
	SEC = 8,
	ALL = 0xFF,
}

function mgr:initialize()
	self._sec_list = {}
	self._min_list = {}
	self._hour_list = {}
	self._day_list = {}
	self._cs = has_queue and queue() or function(f, ...)
		return f(...)
	end
end

function mgr:reg(calc)
	local mask = calc:mask()
	if (mask & mgr.TYPES.SEC) == mgr.TYPES.SEC then
		table.insert(self._sec_list, calc)
	end
	if (mask & mgr.TYPES.MIN) == mgr.TYPES.MIN then
		table.insert(self._min_list, calc)
	end
	if (mask & mgr.TYPES.HOUR) == mgr.TYPES.HOUR then
		table.insert(self._hour_list, calc)
	end
	if (mask & mgr.TYPES.DAY) == mgr.TYPES.DAY then
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

function mgr:unreg(calc)
	local mask = calc:mask()
	if (mask & mgr.TYPES.SEC) == mgr.TYPES.SEC then
		unreg_list_obj(self._sec_list, now)
	end
	if (mask & mgr.TYPES.MIN) == mgr.TYPES.MIN then
		unreg_list_obj(self._min_list, now)
	end
	if (mask & mgr.TYPES.HOUR) == mgr.TYPES.HOUR then
		unreg_list_obj(self._hour_list, now)
	end
	if (mask & mgr.TYPES.DAY) == mgr.TYPES.DAY then
		unreg_list_obj(self._day_list, now)
	end	
end

local function on_trigger_list(calc_list, typ, now, duration)
	for _, v in ipairs(calc_list) do
		local r, rr, err = xpcall(v.on_trigger, debug.traceback, v, typ, now, duration)
		if not r then
			logger.log('error', rr)
		end
		if not rr then
			logger.log('error', err)
		end
	end
end

--
-- type: TYPES
-- now: time in seconds
function mgr:trigger(typ, now, duration)
	local now = math.floor(now)
	if typ == mgr.TYPES.SEC then
		self._cs(on_trigger_list, self._sec_list, mgr.TYPES.SEC, now, duration)
	end
	if typ == mgr.TYPES.MIN then
		self._cs(on_trigger_list, self._min_list, mgr.TYPES.MIN, now, duration)
	end
	if typ == mgr.TYPES.HOUR then
		self._cs(on_trigger_list, self._hour_list, mgr.TYPES.HOUR, now, duration)
	end
	if typ == mgr.TYPES.DAY then
		self._cs(on_trigger_list, self._day_list, mgr.TYPES.DAY, now, duration)
	end
end

return mgr
