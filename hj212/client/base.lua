local class = require 'middleclass'
local packet = require 'hj212.packet'
local types = require 'hj212.types'
local pfinder = require 'hj212.utils.pfinder'

local client = class('hj212.client.base')

function client:initialize(station, passwd, timeout, retry)
	assert(station and passwd)
	self._station = station
	self._system = tonumber(station:system())
	self._dev_id = station:id()
	self._passwd = passwd
	self._timeout = (tonumber(timeout) or 10) * 1000
	self._retry = tonumber(retry) or 3

	self._treatment = {}

	self._process_buf = nil
	self._handlers = {}
	self._finders = {
		pfinder(types.COMMAND, 'hj212.client.handler')
	}
end

function client:set_logger(log)
	self._log = log
end

function client:log(level, ...)
	if self._log then
		self._log[level](self._log, ...)
	end
end

function client:station()
	return self._station
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

function client:find_tag_sn(tag_name)
	local meter = self._station:find_tag_meter(tag_name)
	if meter then
		return meter:sn()
	end
end

function client:add_treatment(treatment)
	self._treatments[treatment:id()] = treatment
end

function client:get_treatement(id)
	assert(id ~= nil)
	return self._treatments[id]
end

function client:request(request, response)
	local response = response or function(reply, err)
		return reply, err
	end

	local resp, err = self:send_request(request)
	if resp then
		return response(resp)
	else
		return response(nil, err)
	end
end

function client:add_handler(packet_path_base)
	table.insert(self._finders, 1, pfinder(types.COMMAND, packet_path_base))
end

function client:__find_handler(cmd)
	for _, finder in pairs(self._finders) do
		local handler, err = finder(cmd)
		if handler then
			return handler
		end
	end
	return nil, "Command handler not found for CMD:"..cmd
end

function client:find_handler(cmd)
	if self._handlers[cmd] then
		return self._handlers[cmd]
	end

	local handler, err = self:__find_handler(cmd)
	if not handler then
		self:log('error', err)
		return nil, err
	end
	local h = handler:new(self)

	self._handlers[cmd] = h

	return h
end

function client:on_request(request)
	local cmd = request:command()
	local session = request:session()
	self:log('info', 'Process request', session, cmd)

	local handler, err = self:find_handler(cmd)

	if not handler then
		if request:need_ack() then
			self:send_reply(session, types.REPLY.REJECT)
		end
		return
	end

	if request:need_ack() then
		self:send_reply(session, types.REPLY.RUN)
	end

	local result, err = handler(request)
	if not result then
		self:log('error', 'Process request failed', session, cmd, err)
	else
		self:log('info', 'Process request successfully', session, cmd)
	end
	if request:need_ack() then
		self:send_result(session, result and types.RESULT.SUCCESS or types.RESULT.ERR_UNKNOWN)
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

function client:send_reply(session, reply_status)
	local reply = require 'hj212.reply.reply'
	local resp = reply:new(session, reply_status)
	self:log('debug', "Sending reply", reply_status)
	return self:send_request(resp)
end

function client:send_result(session, result_status)
	local result = require 'hj212.reply.result'
	local resp = result:new(session, result_status)
	self:log('debug', "Sending result", result_status)
	return self:send_request(resp)
end

function client:send_notice(session)
	local notice = require 'hj212.reply.notice'
	local resp = notice:new(session)
	self:log('debug', "Sending notice")
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
