local class = require 'middleclass'
local packet = require 'hj212.packet'
local types = require 'hj212.types'
local pfinder = require 'hj212.utils.pfinder'

local resp = class('hj212.reply.base')

local finder = pfinder(types.COMMAND, 'hj212.command')

function resp:initialize(command, need_ack)
	self._command = command
	self._need_ack = need_ack ~= nil and need_ack or false -- default is false
end

function resp:command()
	return self._command
end

function resp:need_ack()
	return self._need_ack
end

function resp:encode(client)
	assert(client.sys and client.passwd and client.devid, 'Attribute missing')

	local cmd = self._command:command()
	local params = self._command:encode()

	return packet:new(types.SYSTEM.REPLY, cmd, client.passwd, client.devid, self._need_ack, params)
end

function resp:decode(packet)
	local params = packet:params()
	local cmd = packet:command()

	local m, err = pfinder(cmd)
	assert(m, err)

	local obj = m:new()
	obj:decode(params)

	self._command = obj

	self._need_ack = packet:need_ack()

	assert(packet:system() == types.SYSTEM.REPLY)

	return {
		sys = packet:system(),
		passwd = packet:passwd(),
		devid = packet:device_id()
	}
end

return resp
