---
-- Package finder utility
--

return function(types, base_pn)
	assert(types ~= nil and type(types) == 'table')
	assert(base_pn ~= nil and type(base_pn) == 'string')
	local codes = {}
	for k,v in pairs(types) do
		codes[v] = string.lower(k)
	end

	return function(code, appendix)
		local key = codes[code]
		if not key then
			return nil, "No package found:"..code
		end

		local p_name = base_pn..'.'..key
		p_name = appendix and p_name..'.'..appendix or p_name
		local r, p = pcall(require, p_name)
		if not r then
			return nil, p
		end
		return p, p_name
	end
end
