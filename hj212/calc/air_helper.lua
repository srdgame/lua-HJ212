local logger = require 'hj212.logger'

local _M = {}

-- 18
function _M.Csn(Cs, Ba, Ps, Ts)
	logger.log('trace', 'Csn:', 'Cs', Cs, 'Ba', Ba, 'Ps', Ps, 'Ts', Ts)
	--return Cs * (101325 / (Ba + Ps)) * ((273 + Ts) / 273)
	local val = Cs * (101325 / (Ba + Ps)) * ((273 + Ts) / 273)
	logger.log('trace', 'Csn Result: ', val)
	return val
end

-- 19
function _M.DryC(Cd, Xsw)
	assert(Xsw ~= 1)
	logger.log('trace', 'DryC:', 'Cd', Cd, 'Xsw', Xsw)
	-- return Cd / (1 - Xsw)
	local val = Cd / (1 - Xsw)
	logger.log('trace', 'DryC Result: ', val)
	return val
end

-- 20
function _M.Cq(Cv, g_mol)
	logger.log('trace', 'Cq:', 'Cv', Cv, 'g_mol', g_mol)
	--return (g_mol / 22.4) * Cv
	local val = (g_mol / 22.4) * Cv
	logger.log('trace', 'Cq Result: ', val)
	return val
end

-- 21
function _M.Cnox(Cno, Mno, Cno2, Mno2)
	logger.log('trace', 'Cnox:', 'Cno', Cno, 'Mno', Mno, 'Cno2', Cno2, 'Mno2', Mno2)
	--return Cno * (Mno2/Mno) + Cno2
	local val = Cno * (Mno2/Mno) + Cno2
	logger.log('trace', 'Cnox Result: ', val)
	return val
end

-- 22
function _M.CnoxV(Cnov, Cno2v, Mno2)
	logger.log('trace', 'CnoxV:', 'Cnov', Cnov, 'Cno2v', Cno2v, 'Mno2', Mno2)
	-- return (Cnov + Cno2v) * (Mno2 / 22.4)
	local val = (Cnov + Cno2v) * (Mno2 / 22.4)
	logger.log('trace', 'CnoxV Result: ', val)
	return val
end


-- 26
function _M._Cz(Csn_dry, A, As)
	assert(As ~= 0)
	return Csn_dry * ( A / As)
end

-- 27
function _M._Cz_A(Cvo2_dry)
	--assert(Cvo2_dry ~= 0.21)
	if math.abs(Cvo2_dry - 0.21) < 0.01 then
		Cvo2_dry = 0.209
	end
	return 0.21 / (0.21 - Cvo2_dry)
end

function _M.Cz(Csn_dry, Cvo2_dry, As)
	logger.log('trace', 'Cz:', 'Csn_dry', Csn_dry, 'Cvo2_dry', Cvo2_dry, 'As', As)
	-- return _M._Cz(Csn_dry, _M._Cz_A(Cvo2_dry), As)
	local val = _M._Cz(Csn_dry, _M._Cz_A(Cvo2_dry), As)
	logger.log('trace', 'Cz Result: ', val)
	return val
end

-- 28
function _M.Cz2(Csn_dry, Cvo2_dry, Co2s)
	--assert(Cvo2_dry ~= 0.21)
	if math.abs(Cvo2_dry - 0.21) < 0.01 then
		Cvo2_dry = 0.209
	end
	logger.log('trace', 'Cz2:', 'Csn_dry', Csn_dry, 'Cvo2_dry', Cvo2_dry, 'Co2s', Co2s)
	-- return Csn_dry * (0.21 - Co2s) / (0.21 - Cvo2_dry)
	local val = Csn_dry * (0.21 - Co2s) / (0.21 - Cvo2_dry)
	logger.log('trace', 'Cz2 Result: ', val)
	return val
end

-- 29
function _M.Vs(Kv, Vp)
	logger.log('trace', 'Vs:', 'Kv', Kv, 'Vp', Vp)
	-- return Kv * Vp
	local val = Kv * Vp
	logger.log('trace', 'Vs Result: ', val)
	return val
end

-- 30
function _M.Qs(F, Vs)
	logger.log('trace', 'Qs:', 'F', F, 'Vs', Vs)
	-- return F * Vs
	local val = F * Vs
	logger.log('trace', 'Qs Result: ', val)
	return val
end

function _M.Qsh(F, Vsh)
	logger.log('trace', 'Qsh:', 'F', F, 'Vs', Vsh)
	-- return F * Vsh * 3600
	local val = F * Vsh * 3600
	logger.log('trace', 'Qsh Result: ', val)
	return val
end

-- 31
function _M.Qsn(Qs, t_s, Ba, Ps, Xsw)
	logger.log('trace', 'Qsn:', 'Qs', Qs, 't_s', t_s, 'Ba', Ba, 'Ps', Ps, 'Xsw', Xsw)
	-- return Qs * (273 / (273 + t_s)) * ((Ba + Ps) / 101325) * (1 - Xsw)
	local val = Qs * (273 / (273 + t_s)) * ((Ba + Ps) / 101325) * (1 - Xsw)
	logger.log('trace', 'Qsn Result: ', val)
	return val
end

function _M.Qsnh(Qsh, t_s, Ba, Ps, Xsw)
	logger.log('trace', 'Qsnh:', 'Qsh', Qsh, 't_s', t_s, 'Ba', Ba, 'Ps', Ps, 'Xsw', Xsw)
	-- return Qsh * (273 / (273 + t_s)) * ((Ba + Ps) / 101325) * (1 - Xsw)
	local val = Qsh * (273 / (273 + t_s)) * ((Ba + Ps) / 101325) * (1 - Xsw)
	logger.log('trace', 'Qsnh Result: ', val)
	return val
end

-- 33
function _M.Gh(Cqh, Qsnh)
	logger.log('Gh', 'Gh:', 'Cqh', Cqh, 'Qsnh', Qsnh)
	-- return Cqh * Qsnh * (10 ^ -6)
	local val = Cqh * Qsnh * (10 ^ -6)
	logger.log('trace', 'Gh result: ', val)
	return val
end

return _M
