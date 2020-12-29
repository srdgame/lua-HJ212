local logger = require 'hj212.logger'

local _M = {}

-- 18
function _M.Csn(Cs, Ba, Ps, Ts)
	return Cs * (101325 / (Ba + Ps)) * ((273 + Ts) / 273)
end

-- 19
function _M.DryC(Cd, Xsw)
	assert(Xsw ~= 1)
	return Cd / (1 - Xsw)
end

-- 20
function _M.Cq(Cv, g_mol)
	return (g_mol / 22.4) * Cv
end

-- 21
function _M.Cnox(Cno, Mno, Cno2, Mno2)
	return Cno * (Mno2/Mno) + Cno2
end

-- 22
function _M.CnoxV(Cnov, Cno2v, Mno2)
	return (Cnov + Cno2v) * (Mno2 / 22.4)
end


-- 26
function _M.Cz(Csn_dry, a, a_s)
	return Csn_dry * ( a / a_s)
end

-- 27
function _M.a(Cvo2_dry)
	return 0.21 / (0.21 - Cvo2_dry)
end

-- 28
function _M.Cz2(Csn_dry, Co2s, Cvo2_dry)
	return Csn_dry * (0.21 - Co2s) / (0.21 - Cvo2_dry)
end

-- 29
function _M.Vs(Kv, Vp)
	logger.log('trace', 'Vs:', 'Kv', Kv, 'Vp', Vp)
	return Kv * Vp
end

-- 30
function _M.Qs(F, Vs)
	logger.log('trace', 'Qs:', 'F', F, 'Vs', Vs)
	return F * Vs
end

function _M.Qsh(F, Vsh)
	logger.log('trace', 'Qsh:', 'F', F, 'Vs', Vs)
	return F * Vsh * 3600
end

-- 31
function _M.Qsn(Qs, t_s, Ba, Ps, Xsw)
	logger.log('trace', 'Qsn:', 'Qs', Qs, 't_s', t_s, 'Ba', Ba, 'Ps', Ps, 'Xsw', Xsw)
	return Qs * (273 / (273 + t_s)) * ((Ba + Ps) / 101325) * (1 - Xsw)
end

function _M.Qsnh(Qsh, t_s, Ba, Ps, Xsw)
	logger.log('trace', 'Qsnh:', 'Qsh', Qsh, 't_s', t_s, 'Ba', Ba, 'Ps', Ps, 'Xsw', Xsw)
	return Qsh * (273 / (273 + t_s)) * ((Ba + Ps) / 101325) * (1 - Xsw)
end

-- 33
function _M.Gh(Cqh, Qsnh)
	return Cqh * Qsnh * (10 ^ -6)
end

return _M
