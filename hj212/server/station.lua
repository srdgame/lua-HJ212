local class = require 'middleclass'
local utils_sort = require 'hj212.utils.sort'
local cems = require 'hj212.client.station.cems'
local waitable = require 'hj212.client.station.waitable'

local station = class('hj212.client.station')

function station:initialize(conf, sleep_func)
	assert(conf, 'Conf missing')
	assert(conf.system and conf.dev_id and conf.name)
	assert(sleep_func, 'Sleep function missing')

	self._conf = conf
	self._sleep_func = sleep_func

	self._client = nil
	self._poll_list = {}
	self._meters = {}
end

function station:client()
	return self._client
end

function station:set_client(client)
	self._client = client
end

function station:station_name()
	return self._conf.name
end

function station:system()
	return self._conf.system
end

function station:id()
	return self._conf.dev_id
end

function station:passwd()
	return self._conf.passwd
end

function station:timeout()
	return self._conf.timeout
end

function station:retry()
	return self._conf.retry
end

function station:version()
	return self._conf.version
end

function station:rdata_interval()
	return self._conf.rdata_interval
end

function station:min_interval()
	return self._conf.min_interval
end

function station:sleep(ms)
	return self._sleep_func(ms)
end

function station:meters()
	return self._meters
end

function station:find_poll(id)
	return self._poll_list[id]
end

function station:find_poll_meter(id)
	local poll = self._poll_list[id]
	if poll then
		return poll:meter()
	end
	return nil, "Not found"
end

function station:polls()
	return self._poll_list
end

function station:add_meter(meter)
	assert(meter)
	table.insert(self._meters, meter)
	for id, poll in pairs(meter:poll_list()) do
		assert(self._poll_list[id] == nil)
		self._poll_list[id] = poll
	end
end

return station
