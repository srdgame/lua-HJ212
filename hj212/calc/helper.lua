local types = require 'hj212.types'

local _M = {}

function _M.flag_can_calc(flag)
	if flag == nil then
		return true
	end
	if flag == types.FLAG.Normal or flag == types.FLAG.Overproof then
		return true
	end
	return false
end

return _M
