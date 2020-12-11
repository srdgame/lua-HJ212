local class = require 'middleclass'
local date = require 'date' -- date module for encoding/decoding
local time = require 'hj212.time'

local date = class('hj212.data')

local date_fmt = '%Y%m%d%H%M%S'

function data:initialize(sys, cmd, passwd, devid, need_ack, params)
	self.session = math.floor(time.now())
	self._sys = sys
	self._cmd = cmd
	self._passwd = passwd
	self._devid = devid
	self._need_ack = need_ack
	self._params = params
end

-- TODO: Packet spilit
function data:encode()
	local d = date(self.session)
	local pn = d:fmt(date_fmt) + string.format('%04d', d:getticks()//1000)
	local flag = (1 << 2 ) + (self._need_ack and 1 or 0)

	local function encode(data, count, cur)
		local raw = {}
		raw[#raw + 1] = string.format('QN=%s', pn)
		raw[#raw + 1] = string.format('ST=%s', self._sys)
		raw[#raw + 1] = string.format('CN=%s', self._cmd)
		raw[#raw + 1] = string.format('PW=%s', self._passwd)
		raw[#raw + 1] = string.format('MN=%s', self._devid)

		if count then
			raw[#raw + 1] = string.format('Flag=%s', string.format('%d', flag + 2))
			raw[#raw + 1] = string.format('PNUM=%d', count)
			raw[#raw + 1] = string.format('PNO=%d', cur)
		end

		raw[#raw + 1] = 'CP=&&'
		raw[#raw + 1] = data
		raw[#raw + 1] = '&&'
		return table.concat(raw, ';')
	end

	local pdata = self._params:encode()

	if type(pdata) == table then
		local count = #pdata
		local t = {}
		for i, v in ipairs(pdata) do
			t[#t + 1] = encode(v, count, i)
		end
		return t
	else
		return encode(pdata)
	end
end

function data:decode(raw, index)
	local head, params, index = string.match(raw, '^(.-)CP=&&(.-)&&()', index)
	if not head or not params then
		return nil, "Invalid packet data"
	end

	local pn = string.match(raw, 'QN=([^;]+)')
	pn = string.sub(pn, 1, -4)..'.'..string.sub(pn, -3)
	self.session = math.floor(date.diff(date(pn), date(0)):spanseconds() * 1000)

	self._sys = string.match(raw, 'ST=([^;]+)')
	self._cmd = string.match(raw, 'CN=([^;]+)')
	self._passwd = string.match(raw, 'PW=([^;]+)')
	self._devid = string.match(raw, 'MN=([^;]+)')
	local flag = tonumber(string.match(raw, 'Flag=(%d+)'))
	self._need_ack = ((flag & 1) == 1)

	--- Packet spilit not supported

	if ((flag & 0x3) >> 1) == 1 then
		assert(nil, "Packet spilit not support")
		local total = string.match(raw, 'PNUM=(%d+)')
		local cur = string.match(raw, 'PNO=(%d+)')
	end

	self._params:deocde(params)
	return index
end

function data:session()
	return self.session
end

function data:system()
	return self._sys
end

function data:command()
	return self._cmd
end

function data:password()
	return self._passwd
end

function data:device_id()
	return self._devid
end

function data:need_ack()
	return self._need_ack
end


return data
