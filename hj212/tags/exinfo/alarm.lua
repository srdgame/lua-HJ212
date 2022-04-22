
-- 烟气设备报警
local A_TYPES = {
	NONE			= 0,	-- 正常
	PIPE 			= 1, 	-- 气路堵塞
	LIMIT_HIGH 		= 2, 	-- 上限报警
	LIMIT_LOW 		= 3, 	-- 下限报警
	NO_INSTRUMEND_WIND	= 4,	-- 缺仪表风
	TEMP 			= 5,	-- 温控报警
	RAY	 		= 6,	-- 光强弱报警
	PIPE_TEMP		= 7,	-- 伴热管温度报警
	O2_SENSOR_AGING		= 8,	-- 氧传感器老化报警
	SENSOR_TEMP		= 9,	-- 探头温度故障
}

-- 污水设备报警
local W_TYPES = {
	NONE 			= 0,  	-- 正常（山东:0）
	NO_REAGENT		= 1,	-- 缺试剂（山东:5）
	NO_DISTILLED_WATER	= 2,	-- 缺蒸馏水（山东:6）
	NO_STD_LIQUID	 	= 3,	-- 缺标液
	NO_SAMPLE_WATER		= 4,	-- 缺水样（山东:2）
	HEAT			= 5,	-- 加热故障（山东:3）
	RAY 			= 6,	-- 光源故障
	LIMIT_HIGH		= 7,	-- 测量值超上限
	LIMIT_LOW		= 8,	-- 测量值超下限
	EMISSION		= 9,	-- 排残液故障（山东:4）
	SAMPLE 			= 10,	-- 采样故障
	SYSTEM			= 11, 	-- 系统故障（山东:1）
	OTHER			= 99
}

-- 数采仪报警
local TYPES = {
	NONE	= 0,	-- 正常
	POWER	= 1,	-- 市电中断
	NTP	= 2,	-- 自动对时未成功
}
