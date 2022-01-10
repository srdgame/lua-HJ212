local types = require 'hj212.types'

local _M = {
	_calc_flags = {
		[types.FLAG.Maintain] = true,
		[types.FLAG.Error] = true,
		[types.FLAG.Calibration] = true,
	}
}

function _M.add_calc_flag(flag)
	_M._calc_flags[flag] = true
end

function _M.remove_calc_flag(flag)
	_M._calc_flags[flag] = nil
end

function _M.flag_can_calc(flag)
	if flag == nil then
		return true
	end
	if flag == types.FLAG.Normal or flag == types.FLAG.Overproof then
		return true
	end

	if _M._calc_flags[flag] then
		return true
	end

	return false
end

return _M
