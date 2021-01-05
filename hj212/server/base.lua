local class = require 'middleclass'
local packet = require 'hj212.packet'
local types = require 'hj212.types'
local pfinder = require 'hj212.utils.pfinder'

local server = class('hj212.server.base')

function server:initialize()
	self._stations = {}
	self._clients = {}
end

function server:set_logger(log)
	self._log = log
end

function server:log(level, ...)
	if self._log then
		self._log[level](self._log, ...)
	end
end

function server:add_station(id, station)
	assert(self._stations[id] == nil)
	self._stations[id] = station
end

function server:find_station(id)
	return self._stations[id]
end

function server:start()
	assert(nil, 'Not implemented')
end

function server:stop()
	assert(nil, 'Not implemented')
end

return server
