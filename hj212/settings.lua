return {
	MAX_PACKET_LEN = 9800,
	ITEMS = {
		-- All settings
		Flow_Negative_Calc = { desc = "是否计算负数流量", default = 1 },

		-- CEMS items
		F =		{ desc = "烟道截面积",		default = 1,		unit = "平方米" },
		Kv =	{ desc = "速度场系数",		default = 1 },
		Ba =	{ desc = "本地大气压",		default = 101.23,	unit = "千帕" },
		Co2s =	{ desc = "基准氧含量",		default = 1,		unit = "%" },
		Kp =	{ desc = "皮托管系数",		default = 1 },
		As =	{ desc = "标准过量空气系数",	default = 1.7 },

		-- 量程设定
		Humidity_Max	= { desc = "烟气湿度量程上限", default = 40,		unit = '%' },
		Humidity_Min	= { desc = "烟气湿度量程下限", default = 0,		unit = '%' },
		Temp_Max		= { desc = "烟气温度量程上限", default = 300,		unit = '摄氏度' },
		Temp_Min		= { desc = "烟气温度量程下限", default = 0,		unit = '摄氏度' },
		Pressure_Max	= { desc = "烟气压力量程上限", default = 5000,		unit = '帕' },
		Pressure_Min	= { desc = "烟气压力量程下限", default = -5000,	unit = '帕' },
		Flow_Max		= { desc = "烟气流速量程",		default = 40,		unit = '米/秒' },
		Flow_Min		= { desc = "烟气流速量程",		default = 0,		unit = '米/秒' },
		Dust_Max		= { desc = "烟尘量程上限",		default = 100,		unit = '毫克/立方米' },
		Dust_Min		= { desc = "烟尘量程下限",		default = 0,		unit = '毫克/立方米' },
		Dust_Kk			= { desc = "烟尘斜率",			default = 1 },
		Dust_Kk			= { desc = "烟尘截距",			default = 0 },
	}
}
