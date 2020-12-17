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
end

function base:read(cate, start_time, end_time)
	assert(nil, "Not implemented")
end

function base:write(cate, data_list)
	assert(nil, "Not implemented")
end

return base
