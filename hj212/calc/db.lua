local class = require 'middleclass'

local base = class('hj212.calc.db')

function base:initialize()
end

function base:push_sample(data)
	assert(nil, "Not implemented")
end

function base:read_samples(start_time, end_time)
	assert(nil, "Not implemented")
end

function base:save_samples()
	assert(nil, "Not implemented")
end

--- Return list of data
-- time by etime
function base:read(cate, start_time, end_time)
	assert(nil, "Not implemented")
end

--- Data the data item or array list
function base:write(cate, data, is_array)
	assert(nil, "Not implemented")
end

return base
