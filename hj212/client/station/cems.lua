local class = require 'middleclass'
local logger = require 'hj212.logger'
local cems = class('hj212.client.station.cems')

local CEMS_ITEMS = {
	-- CEMS 安装地点的环境大气压值，Pa
	Ba = {
		name = 'a01006',
		--name = 'i23001',
		default = 101.325,
		rate = 1000
	},
	-- CEMS 测量的烟气静压值，Pa
	Ps = {
		name = 'a01013',
		default = 101.325,
		rate = 1000
	},
	-- CEMS 测量的烟气温度，℃
	ts = {
		name = 'a01012',
	},
	-- CEMS 最大间隔 5s 采集测量的烟气流速值，m/s
	Vp = {
		name = 'a01011',
	},
	-- CEMS 安装点位烟囱或烟道断面的面积，m2
	F = {
		name = 'a01016',
		default = 1
	},
	-- 烟气绝对湿度（又称水分含量），%
	Xsw = {
		name = 'a01014',
		rate = 0.01,
	},
	-- 排放烟气中含氧量干基体积浓度，%
	Cvo2 = {
		name = 'a19001',
		rate = 0.01,
		default = 21,
	},
	-- CEMS 设置速度场系数
	Kv = {
		name = 'Kv',
		default = 1.414
	},
	-- CEMS 皮托管系数
	Kp = {
		name = 'Kv',
		default = 0.639
	},
	-- CEMS 排放标准中规定的该行业标准过量空气系数
	As = {
		name = 'As',
		default = 1.7 --
	},
	Co2s = {
		name = 'Co2s',
		default = 0.1 -- ????
	},
	-- Mno 一氧化氮摩尔质量
	Mno = {
		name = 'Mno',
		default = 30,
	},
	-- Mno2 一氧化氮摩尔质量
	Mno2 = {
		name = 'Mno2',
		default = 46,
	},
}

function cems:initialize(station)
	self._station = station

	self._items = {}
	for k, v in pairs(CEMS_ITEMS) do
		local id = v.name or k
		local item = {
			id = id,
			name = k,
			rate = v.rate,
			default = v.default or 0
		}
		self._items[k] = item

		self[item.name] = function(self)
			local value, err = self._station:get_setting(item.name)
			if not value then
				local poll = self._station:find_poll(item.id)
				if poll then
					value = poll:get_value()
				end
			end

			if not value then
				local default = item.rate and item.default * item.rate or item.default
				local err = string.format("Failed to get CEMS.%s[%s], using default:%s", item.name, item.id, default)
				logger.warning(err)
				return item.default
			end

			return item.rate and value * item.rate or value
		end
	end
end

function cems:set_default(name, default)
	local item = assert(self._items[name])
	if default == nil then
		item.default = CEMS_TM[name].default or 0
	else
		item.default = default
	end
end

function cems:set_rate(name, rate)
	local item = assert(self._items[name])
	if rate == nil then
		item.rate = CEMS_TM[name].rate or nil
	else
		item.rate = rate
	end

end

function cems:get(name)
	local item = assert(self._items[name])
	return self[name]()
end

function cems:rate(name)
	local item = assert(self._items[name])
	return item.rate or 1
end

return cems
