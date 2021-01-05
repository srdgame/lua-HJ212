local class = require 'middleclass'
local packet = require 'hj212.packet'
local types = require 'hj212.types'
local pfinder = require 'hj212.utils.pfinder'

local client = class('hj212.server.client')

function client:initialize()
	self._station = nil
	self._system = nil
	self._dev_id = nil
	self._passwd = nil

	self._process_buf = nil
	self._packet_buf = {}
	self._handlers = {}
	self._finders = {
		pfinder(types.COMMAND, 'hj212.server.handler')
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

function client:set_station(station)
	self._station = station
	if station then
		self._system = station:system()
		self._passwd = station:passwd()
		self._dev_id = station:id()
	else
		self._system = nil
		self._passwd = nil
		self._dev_id = nil
	end
end

function client:station()
	return self._station
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
			self:send_reply(p:session(), types.REPLY.ERR_UNKNOWN)
		end
		return
	end

	local result, err = handler(request)
	if not result then
		self:log('error', 'Process request failed', session, cmd, err)
	else
		self:log('info', 'Process request successfully', session, cmd)
		if request:need_ack() then
			self:send_ack(session)
		end
	end
end

function client:process(raw_data)
	local buf = self._process_buf and self._process_buf..raw_data or raw_data

	local p, buf, err = packet.static.parse(buf, 1, function(bad_raw)
		self:log('error', 'CRC Error Data Found')
	end)

	if buf and string.len(buf) > 0 then
		self._process_buf = buf
	else
		self._process_buf = nil
	end

	if not p then
		return nil, err or 'Not enough data'
	end

	if not self._station then
		self._system = p:system()
		self._passwd = p:password()
		self._dev_id = p:device_id()
		local station, reply_code = self:on_station_create(p:system(), p:device_id(), p:password())
		if not station then
			print('REPLY_CODE', reply_code)
			self:send_reply(p:session(), reply_code)
			return nil, 'Station create failed, code: '..reply_code
		end
		self._station = station
	end

	for k, buf in pairs(self._packet_buf) do
		local now = os.time()
		local timeout = true
		for i, p in pairs(buf) do
			if now - p:sub_time() < 360 then
				timeout = false
				break
			end
		end
		if timeout then
			-- Remove buffer
			print('Multiple packet timeout', k)
			self._packet_buf[k] = nil
		end
	end

	-- Sub packets 
	if p:total() > 1 then
		-- disable sub compact for now
		--[[
		local session = p:session()
		local cur, cur_data = p:cur_data()
		local buf = self._packet_buf[session] and self._packet_buf[session] or {}
		buf[cur] = p --- may overwrite the old received one
		if #buf < p:total() then
			print('Multiple packet found', p._total, cur)
			--- TODO: self:data_ack(session)
			return nil, "Mutiple packets found!!"
		end
		print('Multiple packet completed', p._total, cur)
		p = buf[1]
		for i = 2, p:total() do
			p:sub_append(buf[i]:cur_data())
		end
		]]--
		p:sub_done()
	end

	if p:system() == types.SYSTEM.REPLY then
		self:log('debug', 'On reply', p:session(), p:command())
		return p, true
	else
		local ss = p:session()
		ss = ss // 1000
		self:log('debug', 'On request', p:session(), p:command())
		return p, false
	end
end

function client:reply(reply)
	local r, pack = pcall(reply.encode, reply, {
		sys = self._system,
		passwd = self._passwd,
		devid = self._dev_id
	})

	if r then
		assert(pack:system() == types.SYSTEM.REPLY)
		assert(not pack:need_ack())

		local raw = pack:encode()
		if type(raw) == 'table' then
			raw = table.concat(raw)
		end

		local r, err = self:send_nowait(raw)
		if not r then
			self:log('error', err or 'EEEEEEEEEEEEEE2222')
			return nil, err
		end
		return true
	else
		self:log('error', pack or 'EEEEEEEEEEEEEE')
		return nil, pack
	end
end

function client:request(request, response)
	local r, pack = pcall(request.encode, request, {
		sys = self._system,
		passwd = self._passwd,
		devid = self._dev_id
	})

	if not r then
		self:log('error', pack or 'EEEEEEEEEEEEEE')
		return nil, pack
	end

	assert(pack:system() ~= types.SYSTEM.REPLY)
	local raw = pack:encode()
	if not pack:need_ack() then
		assert(not response)
		if type(raw) == 'table' then
			raw = table.concat(raw)
		end
		return self:send_nowait(raw)
	else
		local session = pack:session()
		--- Single packet
		if type(raw) == 'string' then
			local r, err = self:send(session, raw)
			if response and r then
				r, err = response(r, err)
			end
			return r, err
		end

		--- Mutiple packets which need ack for each
		for i, v in ipairs(raw) do
			local r, err = self:send(session + i, v)
			if response and r then
				r, err = response(r, err)
			end
			if not r then
				return nil, err
			end
		end
		return true
	end
end
function client:send_reply(session, reply_status)
	assert(session, "session missing")
	assert(reply_status, "Status missing")
	print(reply_status)
	local reply = require 'hj212.reply.reply'
	local resp = reply:new(session, reply_status)
	self:log('debug', "Sending reply", reply_status)
	return self:reply(resp)
end

function client:send_ack(session)
	local reply = require 'hj212.reply.data_ack'
	local resp = reply:new(session)
	self:log('debug', "Sending data ack")
	return self:reply(resp)
end

function client:send_notice(session)
	local notice = require 'hj212.reply.notice'
	local resp = notice:new(session)
	self:log('debug', "Sending notice")
	return self:reply(resp)
end

function client:send(session, raw_data)
	assert(nil, 'Not implemented')
end

function client:send_nowait(raw_data)
	assert(nil, 'Not implemented')
end

function client:close()
	assert(nil, 'Not implemented')
end

function client:on_station_create()
	assert(nil, 'Not implemented')
end

return client
