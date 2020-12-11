local class = require 'middleclass'
local packet = require 'hj212.packet'
local types = require 'hj212.types'
local pfinder = require 'hj212.utils.pfinder'

local req = class('hj212.request.base')

local finder = pfinder(types.COMMAND, 'hj212.command')

function req:initialize(client, command, need_ack)
	self._client = client
	self._command = command
	self._need_ack = need_ack
end

function req:encode()
	local sys = client:system()
	local passwd = client:passwd()
	local devid = client:device_id()

	local cmd = self._command:command()
	local params = self._command:encode()

	return packet:new(sys, cmd, passwd, devid, self._need_ack, params)
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
end

return req
