local class = require 'middleclass'

local logger = {}

-- Default is print
logger.print = function(...)
	print(...)
end

logger.dump = function(info, raw, index)
	local r, basexx = pcall(require, 'basexx')
	if r then
		if index then
			logger.print(info, basexx.to_hex(string.sub(raw, index)))
		else
			logger.print(info, basexx.to_hex(raw))
		end
	end
end

logger.log = function(level, fmt, ...)
	logger.print(level, string.format(fmt, ...))
end

return logger
