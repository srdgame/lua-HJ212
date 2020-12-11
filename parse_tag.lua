#! /usr/bin/env lua

local cjson = require 'cjson'
local ftcsv = require 'ftcsv'
local pp = require 'PrettyPrint'

local t = ftcsv.parse('hj212.csv', ",", {headers=false})
print(t)

local tags = {}
for i, v in ipairs(t) do
	if i ~= 1 then
		tags[#tags + 1] = {
			name = v[1],
			desc = v[2],
			org_name = string.len(v[3]) > 0 and v[3] or nil,
			unit = string.len(v[4]) > 0 and v[4] or nil,
			calc_unit = string.len(v[5]) > 0 and v[5] or nil,
			format = string.len(v[6]) > 0 and v[6] or nil,
			-- comment = v[7], -- COMMENT is skipped
		}
	end
end

local str = pp(tags)

print(str)

local f, err = io.open('./hj212/tags/info.lua', 'w')

if not f then
	print(err)
end

f:write('return = ')
f:write(str)
f:close()

print('Done!')
