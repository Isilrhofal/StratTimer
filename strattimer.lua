--Copyright (c) 2016, Vanyar
--All rights reserved.

--Redistribution and use in source and binary forms, with or without
--modification, are permitted provided that the following conditions are met:

--    * Redistributions of source code must retain the above copyright
--      notice, this list of conditions and the following disclaimer.
--    * Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
--    * Neither the name of <addon name> nor the
--      names of its contributors may be used to endorse or promote products
--      derived from this software without specific prior written permission.

--THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
--DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
--DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
--(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
--ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
--SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

_addon.author = 'Vanyar'
_addon.name = 'StratTimer'
_addon.version = '0.2'

config = require('config')
texts = require('texts')
packets = require('packets')
res = require('resources')

defaults = {}
defaults.pos = {}
defaults.pos.x = 400
defaults.pos.y = 0
defaults.text = {}
defaults.text.font = 'Consolas'
defaults.text.size = 12

settings = config.load(defaults)
time_box = texts.new(settings)
local enabled = false
local schbuff = 'None'

windower.register_event('prerender', function()
	player = windower.ffxi.get_player()
	if player then
		if S{player.main_job, player.sub_job}:contains('SCH') then
			local strats = get_current_strategem_count()
			local allRecasts = windower.ffxi.get_ability_recasts()
			local stratsRecast = allRecasts[231]
			local col = '\\cs(0,255,0)'
			if (strats == 0) then
				col = '\\cs(255,0,0)'
			elseif (strats <= 2) and player.main_job == 'SCH' then
				col = '\\cs(255,100,0)'
			end
			time_box:text('SCH: '..schbuff..'\n*Remaining:  '..col..strats..' charges\\cr\n*Recast:     '..recast_timer()..' seconds\n*FullCharge: '..stratsRecast..' seconds')
			time_box:visible(true)
		else
			time_box:text('')
			time_box:hide()
		end
	else
		time_box:hide()
	end
end)

windower.register_event('incoming chunk',function(id,org,modi,is_injected,is_blocked)
    if enabled then
	end
	if is_injected then return end
	if (id == 0x63 or id == 0x08D) and org:byte(5) == 5 then
		local offset = windower.ffxi.get_player().main_job_id*6+13 -- So WAR (ID==1) starts at byte 19
		totaljp = org:unpack('H',offset+4)
	end
end)



function usersetup()
	local sub_job = windower.ffxi.get_player().sub_job
	local main_job = windower.ffxi.get_player().main_job
	if main_job == 'SCH' then
		local main_job_level = windower.ffxi.get_player().main_job_level
		if main_job_level >= 10 and main_job_level <= 29 then
			strattimer = '240'
		elseif main_job_level >= 30 and main_job_level <= 49 then
			strattimer = '120'
		elseif main_job_level >= 50 and main_job_level <= 69 then
			strattimer = '80'
		elseif main_job_level >= 70 and main_job_level <= 89 then
			strattimer = '60'
		elseif main_job_level >= 90 and main_job_level < 99 then
			strattimer = '48'
		elseif main_job_level == 99 then
			if totaljp ~= nil and totaljp < 550 then
				strattimer = '48'
			else
				strattimer = '33'
			end
		end
		return strattimer
	elseif sub_job == 'SCH' then
		local sub_job_level = windower.ffxi.get_player().sub_job_level
		if sub_job_level >= 10 and sub_job_level <= 29 then
			strattimer = '240'
		elseif sub_job_level >= 30 and sub_job_level <= 49 then
			strattimer = '120'
		end
		return strattimer
	end
end

function get_current_strategem_count()
	local allRecasts = windower.ffxi.get_ability_recasts()
	local stratsRecast = allRecasts[231]
	if windower.ffxi.get_player().main_job == 'SCH' then
		maxStrategems = math.floor((windower.ffxi.get_player().main_job_level + 10) / 20)
	elseif windower.ffxi.get_player().sub_job == 'SCH' then
		maxStrategems = math.floor((windower.ffxi.get_player().sub_job_level + 10) / 20)
	else
		print('Something went wrong with the current job selection.')
	end
	if usersetup(strattimer) ~= nil then
		local strattimer = usersetup(strattimer)
	else
		local strattimer = '33'
	end
	local fullRechargeTime = math.floor(maxStrategems * strattimer)
	local currentCharges = math.floor(maxStrategems - maxStrategems * stratsRecast / fullRechargeTime)
	return currentCharges
end

function recast_timer()
	if windower.ffxi.get_player().main_job == 'SCH' then
		maxStrategems = math.floor((windower.ffxi.get_player().main_job_level + 10) / 20)
	elseif windower.ffxi.get_player().sub_job == 'SCH' then
		maxStrategems = math.floor((windower.ffxi.get_player().sub_job_level + 10) / 20)
	else
		print('Something went wrong with the current job selection.')
	end
	local allRecasts = windower.ffxi.get_ability_recasts()
	local stratsRecast = allRecasts[231]
	local usedstrat = math.floor(maxStrategems - get_current_strategem_count())
	local totalrecast = math.floor(usedstrat * usersetup(strattimer))
	if usedstrat > 1 then
		timer = math.floor(stratsRecast - ((maxStrategems - get_current_strategem_count()) - 1) * usersetup(strattimer))
	else
		timer = math.floor(stratsRecast)
	end
	return timer
end



windower.register_event('gain buff', function(identify)
	local arts = S{'Dark Arts','Light Arts','Abbendum: Black','Abbendum: White'}
	local name = res.buffs[identify].english
	if arts:contains(name) then
		schbuff = name
	end
end)