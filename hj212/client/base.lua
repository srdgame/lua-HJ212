local class = require 'middleclass'
local packet = require 'hj212.packet'
local types = require 'hj212.types'

local client = class('hj212.client.base')

function client:initialize(system, dev_id, passwd, timeout)
	self._system = system
	self._dev_id = dev_id
	self._passwd = passwd
	self._timeout = (timeout or 10) * 1000
	self._requests = {}

	self._meters = {}
	self._treatment = {}
end

function client:system()
	return self._system
end

function client:device_id()
	return self._dev_id
end

function client:passwd()
	return self._passwd
end

function client:set_passwd(passwd)
	self._passwd = passwd
end

function client:timeout()
	return self._timeout
end

function client:set_timeout(timeout)
	self._timeout = timeout
end

function client:add_meter(meter)
	self._meters[meter:sn()] = meter
end

function client:get_meter(sn)
	assert(sn ~= nil)
	return self._meters[sn]
end

function client:find_meter_sn(tag_name)
	for k, v in pairs(self._meters) do
		if v:has_tag(tag_name) then
			return k
		end
	end
	return nil, "Not found"
end

function client:add_treatment(treatment)
	self._treatments[treatment:id()] = treatment
end

function client:get_treatement(id)
	assert(id ~= nil)
	return self._treatments[id]
end

function client:connect(host, port)
	assert(nil, 'Not implemented')
end

function client:request(request, response)
	local session = request:session()
	if self._requests[session] then
		return nil, "Duplicated session found. "..session
	end

	self._requests[session] = {
		req = request,
		resp = response,
		timeout = nil --- TIMEOUT 
	}

	return self:send(request:encode())
end

function client:on_request(request)
	-- TODO:
end

function client:process(raw_data)
	local buf = self._buf and self._buf..raw_data or raw_data

	local p, buf = packet.static.parse(buf, 1, function(bad_raw)
		-- TODO:
		print('CRC Error Data Found')
	end)

	if string.len(buf) > 0 then
		self._buf = buf
	end

	if not p then
		return
	end

	local session = p:session()

	--- Session unique????
	local req = self._request[session]
	if req and req:system() == types.SYSTEM.REPLY then
		print('On reply', p:session())
		local r, err = req.resp(p)
	else
		print('On request', p:session())
		local r, err = self:on_request(p)
	end
end

function client:send(raw_data)
	assert(nil, 'Not implemented')
end

function client:start()
	assert(nil, 'Not implemented')
end

function client:stop()
	assert(nil, 'Not implemented')
end

return client
