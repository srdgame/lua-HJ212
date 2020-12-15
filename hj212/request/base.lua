local class = require 'middleclass'
local packet = require 'hj212.packet'
local types = require 'hj212.types'
local pfinder = require 'hj212.utils.pfinder'

local req = class('hj212.request.base')

local finder = pfinder(types.COMMAND, 'hj212.command')

function req:initialize(command, need_ack)
	self._command = command
	self._need_ack = need_ack ~= nil and need_ack or true -- default is true
end

function req:command()
	return self._command
end

function req:need_ack()
	return self._need_ack
end

function req:encode(client)
	assert(client.sys, "System code missing")
	assert(client.passwd "Password missing")
	assert(client.devid, 'Device ID missing')

	local cmd = self._command:command()
	local params = self._command:encode()

	return packet:new(client.sys, cmd, client.passwd, client.devid, self._need_ack, params)
end

function req:decode(packet)
	local params = packet:params()
	local cmd = packet:command()

	local m, err = pfinder(cmd)
	assert(m, err)

	local obj = m:new()
	obj:decode(params)

	self._command = obj

	self._need_ack = packet:need_ack()

	return {
		sys = packet:system(),
		passwd = packet:passwd(),
		devid = packet:device_id()
	}
end

return req
