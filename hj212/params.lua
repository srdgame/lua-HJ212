local class = require 'middleclass'
local dtime  require 'hj212.params.dtime'
local datetime = require 'hj212.params.datetime'
local simple = require 'hj212.params.simple'
local tag_value = require 'hj212.params.tag_value'

local params = class('hj212.params')

local fmts = {}
local function ES(fmt)
	local pn = 'hj212.params.ES_'..fmt

	if not fmts[fmt] then
		fmts[fmt] = simple.EASY(pn, fmt)
	end

	return fmts[fmt]
end

local PARAMS = {
	SystemTime = datetime,
	QnRtn = ES('N3'),
	ExeRtn = ES('N3'),
	RtdInterval = ES('N4'),
	MinInterval = ES('N2'),
	RestartTime = datetime,
	PolId = ES('C6'),
	BeginTime = datetime,
	EndTime = datetime,
	DataTime = datetime,
	NewPW = ES('C6'),
	OverTime = ES('N2'),
	ReCount = ES('N2'),
	VaseNo = ES('N2'),
	CstartTime = dtime,
	Ctime = ES('N2'),
	Stime = ES('N4'),
	InfoId = ES('C6'),
}

local TAG_PARAMS = {
	SampleTime = datetime,
	Rtd = tag_value,
	Min = tag_value,
	Avg = tag_value,
	Max = tag_value,
	ZsRtd = tag_value,
	ZsMin = tag_value,
	ZsAvg = tag_value,
	Flag = ES('C1'),
	EFlag = ES('C4'),
	Cou	= tag_value, -- TODO:
	Data = ES('N3.1'),
	DayDate = ES('N3.1'),
	NightData = ES('N3.1'),
	Info = info,
	SN = ES('C24')
}

params.static.SB_RS = {
	ClOSED = 0,
	RUNNING = 1,
	CALIBRATION = 2,
	MAINTAIN = 3,
	WARNING = 4,
	ACTION = 5,
}

local SB_PARAMS = {
	RS = ES('N1'),
	RT = ES('N2.2'),
}

