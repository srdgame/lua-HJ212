local class = require 'middleclass'
local packet = require 'hj212.packet'
local types = require 'hj212.types'
local pfinder = require 'hj212.utils.pfinder'

local client = class('hj212.client.base')

local command_finder = pfinder(types.COMMAND, 'hj212.client.handler')

function client:initialize(system, dev_id, passwd, timeout, retry)
	assert(system and dev_id and passwd)
	self._system = system
	self._dev_id = dev_id
	self._passwd = passwd
	self._timeout = (timeout or 10) * 1000
	self._retry = retry or 3

	self._meters = {}
	self._treatment = {}

	self._process_buf = nil
	self._handlers = {}
end

function client:set_logger(log)
	self._log = log
end

function client:log(level, ...)
	if self._log then
		self._log[level](self._log, ...)
	end
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

function client:retry()
	return self._retry
end

function client:set_retry(retry)
	self._retry = retry
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

function client:request(request, response)
	local response = response or function() end

	local resp, err = self:send_request(request)
	if resp then
		return response(resp)
	else
		return response(nil, err)
	end
end

function client:find_handler(cmd)
	if self._handlers[cmd] then
		return self._handlers[cmd]
	end

	local handler, err = command_finder(cmd)
	if not handler then
		self:log('error', err)
		return nil, err
	end
	local h = handler:new(self)

	self._handlers[cmd] = h

	return h
end

function client:on_request(request)
	self:log('debug', 'Process request', request:session(), request:command())
	local cmd = request:command()
	local handler = self:find_handler(cmd)

	if request:need_ack() then
		self:send_reply(handler and types.REPLY.RUN or types.REPLY.REJECT)
	end

	if handler then
		local result, err = handler(request)
		if request:need_ack() then
			self:send_result(result and types.RESULT.SUCCESS or types.RESULT.ERR_UNKNOWN)
		end
	end
end

function client:process(raw_data)
	local buf = self._process_buf and self._process_buf..raw_data or raw_data

	local p, buf, err = packet.static.parse(buf, 1, function(bad_raw)
		print('CRC Error Data Found')
	end)

	if buf and string.len(buf) > 0 then
		self._process_buf = buf
	else
		self._process_buf = nil
	end

	if not p then
		return nil, err or 'Not enough data'
	end

	if p:system() == types.SYSTEM.REPLY then
		self:log('debug', 'On reply', p:session(), p:command())
		return p, true
	else
		self:log('debug', 'On request', p:session(), p:command())
		return p, false
	end
end

function client:send(session, raw_data, timeout)
	assert(nil, 'Not implemented')
end

function client:send_request(request)
	local r, pack = pcall(request.encode, request, {
		sys = self._system,
		passwd = self._passwd,
		devid = self._dev_id
	})

	if r then
		if pack:need_ack() then
			return self:send(pack:session(), pack:encode())
		else
			return self:send_nowait(pack:encode())
		end
	else
		self:log('error', pack or 'EEEEEEEEEEEEEE')
	end
end

function client:send_reply(reply_status)
	local reply = require 'hj212.reply.reply'
	local resp = reply:new(reply_status)
	self:log('debug', "Sending reply", reply_status)
	return self:send_request(resp)
end

function client:send_result(result_status)
	local result = require 'hj212.reply.result'
	local resp = result:new(result_status)
	self:log('debug', "Sending result", result_status)
	return self:send_request(resp)
end

function client:send_nowait(raw_data)
	assert(nil, 'Not implemented')
end

function client:connect()
	assert(nil, 'Not implemented')
end

function client:close()
	assert(nil, 'Not implemented')
end

return client
