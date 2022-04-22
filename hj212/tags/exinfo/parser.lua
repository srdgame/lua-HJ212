local ftcsv = require 'ftcsv'
local log = require 'utils.logger'.new()

---
-- [1] info name
-- [2] info description
-- [3] hj212 2017 info name
-- [4] hj212 2005 info name
local function load_tpl(name, err_cb)
	local path = tpl_dir..name..'.csv'
	local t = ftcsv.parse(path, ",", {headers=false})

	local NAME_CHECKING = {}

	local function valid_prop(prop, err_cb)
		local log_cb = function(...)
			if err_cb then
				err_cb(...)
			end
			return false
		end

		if NAME_CHECKING[prop.name] then
			return log_cb("Duplicated prop name found", prop.name)
		end
		NAME_CHECKING[prop.name] = true

		return true
	end

	local props = {}

	for i,v in ipairs(t) do
		if i ~= 1 and  #v > 1 then
			local prop = {
				name = v[1],
				desc = v[2],
				info_2017 = v[3],
				info_2005 = v[4],
			}

			if valid_prop(prop, err_cb) then
				props[prop.name] = prop
			end
		end
	end

	return function(name, key, value)
		local prop = props[name]
		if not prop then
			return key, value
		end
		local rate = prop[key]
		if not rate then
			return key, value
		end
		--log.debug(name, key, value, rate, value * rate)
		return key, value * rate
	end
end

return {
	load_tpl = load_tpl,
	init = function(dir)
		tpl_dir = dir.."/info_tpl/"
	end
}
