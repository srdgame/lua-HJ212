local class = require 'middleclass'

local base = class('hj212.calc.db')

local DB_VER = 7 --version

function base:initialize()
end

function base:sample_meta()
	return {
		{ name = 'timestamp', type = 'DOUBLE', not_null = true },
		-- Values
		{ name = 'value', type = 'DOUBLE', not_null = true },
		{ name = 'flag', type = 'CHAR(1)', not_null = true },
		-- COU
		{ name = 'cou', type = 'DOUBLE', not_null = false },
		--- Zs
		{ name = 'value_z', type = 'DOUBLE', not_null = false },
		{ name = 'cou_z', type = 'DOUBLE', not_null = false },
		--- Extented vals
		{ name = 'ex_vals', type = 'STRING', not_null = false},
	}, DB_VER
end

function base:rdata_meta()
	return {
		{ name = 'timestamp', type = 'DOUBLE', not_null = true },
		-- Values
		{ name = 'value', type = 'DOUBLE', not_null = true },
		{ name = 'flag', type = 'CHAR(1)', not_null = true },
		-- Time
		{ name = 'src_time', type = 'DOUBLE', not_null = true },
		-- COU
		{ name = 'cou', type = 'DOUBLE', not_null = false },
		--- Zs
		{ name = 'value_z', type = 'DOUBLE', not_null = false },
		{ name = 'cou_z', type = 'DOUBLE', not_null = false },
	}, DB_VER
end

function base:cou_meta()
	return {
		{ name = 'timestamp', type = 'DOUBLE', not_null = true },
		-- Values
		{ name = 'cou', type = 'DOUBLE', not_null = true },
		{ name = 'avg', type = 'DOUBLE', not_null = true },
		{ name = 'min', type = 'DOUBLE', not_null = true },
		{ name = 'max', type = 'DOUBLE', not_null = true },
		{ name = 'flag', type = 'CHAR(1)', not_null = true },
		-- Time
		{ name = 'stime', type = 'INTEGER', not_null = true },
		{ name = 'etime', type = 'INTEGER', not_null = true },
		--- Zs
		{ name = 'cou_z', type = 'DOUBLE', not_null = false },
		{ name = 'avg_z', type = 'DOUBLE', not_null = false },
		{ name = 'min_z', type = 'DOUBLE', not_null = false },
		{ name = 'max_z', type = 'DOUBLE', not_null = false },

		--- LA
		{ name = 'L5', type = 'DOUBLE', not_null = false }
		{ name = 'L5-Day', type = 'DOUBLE', not_null = false }
		{ name = 'L5-Night', type = 'DOUBLE', not_null = false }
		{ name = 'L10', type = 'DOUBLE', not_null = false }
		{ name = 'L10-Day', type = 'DOUBLE', not_null = false }
		{ name = 'L10-Night', type = 'DOUBLE', not_null = false }
		{ name = 'L50', type = 'DOUBLE', not_null = false }
		{ name = 'L50-Day', type = 'DOUBLE', not_null = false }
		{ name = 'L50-Night', type = 'DOUBLE', not_null = false }
		{ name = 'L90', type = 'DOUBLE', not_null = false }
		{ name = 'L90-Day', type = 'DOUBLE', not_null = false }
		{ name = 'L90-Night', type = 'DOUBLE', not_null = false }
		{ name = 'L95', type = 'DOUBLE', not_null = false }
		{ name = 'L95-Day', type = 'DOUBLE', not_null = false }
		{ name = 'L95-Night', type = 'DOUBLE', not_null = false }

		--{ name = 'Leq', type = 'DOUBLE', not_null = false } -- use avg

		-- { name = 'Ldn', type = 'DOUBLE', not_null = false } -- use avg
		-- { name = 'LMx', type = 'DOUBLE', not_null = false } -- max 
		-- { name = 'LMn', type = 'DOUBLE', not_null = false } -- min

		{ name = 'Ld-Day', type = 'DOUBLE', not_null = false }
		{ name = 'LMx-Day', type = 'DOUBLE', not_null = false }
		{ name = 'LMn-Day', type = 'DOUBLE', not_null = false }

		{ name = 'Ln-Night', type = 'DOUBLE', not_null = false }
		{ name = 'LMx-Night', type = 'DOUBLE', not_null = false }
		{ name = 'LMn-Night', type = 'DOUBLE', not_null = false }
	}, DB_VER
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
