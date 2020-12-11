local class = require 'middleclass'
local crc16 = require 'hj212.crc'
local pdata = require 'hj212.packet.data'

local pack = class('hj212.packet')

pack.static.HEADER	= '##' -- Packet Header fixed string
pack.static.TAIL	= '\r\n'

function pack:initialize(data)
	self._data = data
end

function pack:encode()
	assert(self._data, "Data is missing")

	local data = self._data:encode()
	local len = stream.len(data)

	local raw = {
		pack.static.HEADER
	}
	raw[#raw + 1] = string.format('%04d', len) -- 0000 ~ 9999
	raw[#raw + 1] = data
	raw[#raw + 1] = self:crc(data)
	raw[#raw + 1] = pack.static.TAIL

	return table.concat(raw)
end

function pack:decode(raw, index)
	local s, data_raw, e = string.match(raw, '()##(%w+)%w\r\n()', index)
	if not data_raw then
		return nil
	end

	if string.len(data_raw) < (s + 8 - 1) then
		return nil, "Incorrect packet found!"
	end

	local data_len = tonumber(string.sub(data_raw, s, s + 3))
	local crc = string.sub(data_raw, -4)
	data_raw = string.sub(data_raw, s + 4, -5)

	if data_len ~= string.len(data_raw) then
		return nil, "Data length error"
	end

	local calc_crc = self:crc(data_raw)
	if calc_crc ~= crc then
		return nil, "CRC error"
	end

	self._data = pdata:new()
	self._data:decode(data_raw)

	return e
end

function pack:encode_data()
	return ''
end

function pack:decode_data(raw)
end

function pack:crc(data_raw)
	local sum = crc16(data_raw)
	return string.format('%04X', sum)
end

return pack
