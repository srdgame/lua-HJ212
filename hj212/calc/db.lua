local class = require 'middleclass'

local base = class('hj212.calc.db')

---
-- Database base class
-- Data Unit:
-- {
--   total = 
--   agv = 
--   min = 
--   max = 
--   stime = 
--   etime = 
-- }
--
function base:initialize()
	--self._samples = {}
end

function base:push_sample(timestamp, value, value2, value3)
	assert(nil, "Not implemented")
	--table.insert(self._samples, {timestamp, value, value2, value3})
end

function base:save_samples()
	assert(nil, "Not implemented")
end

function base:read(cate, start_time, end_time)
	assert(nil, "Not implemented")
end

function base:write(cate, data_list)
	assert(nil, "Not implemented")
end

return base
