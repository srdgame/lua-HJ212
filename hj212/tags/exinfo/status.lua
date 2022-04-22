
-- 烟气设备状态
local A_TYPES = {
	IDLE		= 0,	-- 运行（山东待机:1）
	MAINTAIN 	= 1, 	-- 维护（山东:4）
	ALARM 		= 2, 	-- 故障
	CALIB 		= 3,	-- 校准（校标,校零)
	BACK_FLUSH 	= 5,	-- 反吹
	CALIB_SENDOR	= 6,	-- 标定
	SAMPLE 		= 50, 	-- 测量（山东:0)
	CALIB_STD 	= 51,	-- 校标（山东:3)
	CALIB_ZERO 	= 52,	-- 校零（山东:2)
	CHECK		= 54,	-- 校验（山东:5)
	OTHER		= 99,	-- 其它
}

-- 污水设备状态
local W_TYPES = {
	IDLE 		= 0,  	-- 空闲(山东待机:1）
	SAMPLE 		= 1,	-- 做样
	CLEAN 		= 2,	-- 清洗（山东：7）
	MAINTAIN 	= 3,	-- 维护
	ALARM 		= 4,	-- 故障
	CALIB 		= 5,	-- 校准
	STD_CHECK 	= 6,	-- 标样核查
	MEASURE		= 50,	-- 测量（山东:0)
	ALARM_LIMIT	= 51,	-- 测量超限（山东：4）
	CALIB_ZERO	= 52,	-- 零点校准（山东：2）
	CALIB_STD	= 53,	-- 量程校准（山东：3）
	CHECK		= 54,	-- 校验（山东：6）
	OTHER		= 99,	-- 其它
}
	
-- 数采仪状态
local TYPES = {
	RUN		= 0,	-- 运行
	STOP		= 1, 	-- 停机
	ALARM		= 2,	-- 故障
	MAINTAIN	= 3,	-- 维护
}
