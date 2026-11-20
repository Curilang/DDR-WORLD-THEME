local args = {...}
local player = args[1]
local short_plr = ToEnumShortString(player)

local rn_type = "RollingNumbers"
local data_source = "AScoring"

if IsEXScore() then
	rn_type = "RollingNumbersEXScore"
	data_source = "EXScore"
end

return Def.ActorFrame{
	Def.RollingNumbers{
		Name="ScoreCounterBack"..short_plr,
		Font=THEME:GetPathF("ScreenGameplay","score_off"),
		InitCommand=function(s)
			s:Load("RollingNumbersWorld")
			s:xy(7.5,0)
			s:zoom(IsEXScore() and 0 or 1)
		end,
		AfterStatsEngineMessageCommand=function(s,p)
			if p.Player == player then
				s:targetnumber(p.Data[data_source].Score)
			end
		end
	},
	
	Def.RollingNumbers{
		Name="ScoreCounterFront"..short_plr,
		Font=THEME:GetPathF("ScreenGameplay","score_on"),
		InitCommand=function(s)
			s:Load(rn_type)
			s:xy(IsEXScore() and 69 or 7.5,0)
			s:zoom(1)
		end,
		AfterStatsEngineMessageCommand=function(s,p)
			if p.Player == player then
				s:targetnumber(p.Data[data_source].Score)
			end
		end
	},
};