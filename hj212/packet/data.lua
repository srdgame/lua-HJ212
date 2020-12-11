local class = require 'middleclass'
local date = require 'date' -- date module for encoding/decoding
local time = require 'hj212.time'

local date = class('hj212.data')

local date_fmt = '%Y%m%d%H%M%S'

function data:initialize(sys, cmd, passwd, devid, flag, total, cur, params)
	self.session = math.floor(time.now())
	self._sys = sys
	self._cmd = cmd
	self._passwd = passwd
	self._devid = devid
	self._flag = flag
	self._total = total
	self._cur = cur
	self._params = params
end

function data:encode()
	local raw = {}
	local d = date(self.session)
	local pn = d:fmt(date_fmt) + string.format('%04d', d:getticks()//1000)
	raw[#raw + 1] = string.format('QN=%s', pn)
	raw[#raw + 1] = string.format('ST=%s', self._sys)
	raw[#raw + 1] = string.format('CN=%s', self._cmd)
	raw[#raw + 1] = string.format('PW=%s', self._passwd)
	raw[#raw + 1] = string.format('MN=%s', self._devid)
	raw[#raw + 1] = string.format('Flag=%s', string.format('%d', self._flag))
	raw[#raw + 1] = string.format('PNUM=%d', self._total)
	raw[#raw + 1] = string.format('PNO=%d', self._cur)
	raw[#raw + 1] = string.format('CP=&&%s&&', self._params:encode())
	return table.concat(raw, ';')
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
	self._Flag = tonumber(string.match(raw, 'Flag=(%d+)'))
	self._total = string.match(raw, 'PNUM=(%d+)')
	self._cur = string.match(raw, 'PNO=(%d+)')

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

function data:flag()
	return self._flag
end

function data:total()
	return self._total
end

function data:current()
	return self._cur
end

return data
