local crc16 = require 'hj212.crc'
local base = require 'hj212.packet.data'

local pack = base:subclass('hj212.packet')

pack.static.HEADER	= '##' -- Packet Header fixed string
pack.static.TAIL	= '\r\n'
pack.static.MFMT = '##(%w+)\r\n()'

local function packet_crc(data_raw)
	local sum = crc16(data_raw)
	return string.format('%04X', sum)
end

function pack.static.parse(raw, index, on_crc_err)
	local index = string.find(raw, pack.static.HEADER, index or 1, true)
	if not index then
		if string.sub(raw, -1) == '#' then
			return nil, '#' --- Keep the last #
		end
		return nil, ''
	end

	-- Read the data_len XXXX
	local data_len = tonumber(string.sub(raw, index + 2, index + 5))
	local raw_len = string.len(raw)
	if data_len + 12 > raw_len - index - 1 then
		if index ~= 1 then
			return nil, string.sub(raw)
		end
		return nil, raw
	end

	--- Check TAIL
	local s_end = index + data_len + 2 + 4 + 4
	if string.sub(raw, s_end, s_end + 1) ~= pack.static.TAIL then 
		local index = string.find(raw, pack.static.HEADER, index + 2,  true)
		if index then
			return nil, string.sub(raw, index)
		end
		return nil
	end

	local s_data = index + 6
	local data_raw = string.sub(raw, s_data, s_data + data_len - 1)

	local s_crc = index + 6 + data_len
	local crc = string.sub(raw, s_crc, s_crc + 3)

	local calc_crc = packet_crc(data_raw)
	if calc_crc ~= crc then
		if on_crc_err then
			on_crc_err(data_raw)
		else
			print('CRC error') -- TODO:
		end
		return nil, string.sub(raw, se + 2)
	end

	local obj = pack:new()
	obj:decode(data_raw)

	return obj, string.sub(raw, se + 2)
end

function pack:initialize(...)
	base.initialize(self, ...)
end

function pack:encode()
	local data = base.encode(self)

	local len = stream.len(data)

	local raw = {
		pack.static.HEADER
	}
	raw[#raw + 1] = string.format('%04d', len) -- 0000 ~ 9999
	raw[#raw + 1] = data
	raw[#raw + 1] = packet_crc(data)
	raw[#raw + 1] = pack.static.TAIL

	return table.concat(raw)
end

return pack
