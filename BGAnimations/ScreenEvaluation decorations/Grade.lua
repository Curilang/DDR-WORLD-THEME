local pn = ({...})[1]
local Award = STATSMAN:GetCurStageStats():GetPlayerStageStats(pn):GetStageAward()
local Grade = STATSMAN:GetCurStageStats():GetPlayerStageStats(pn):GetGrade()

-- FLARE: remember which FLARE this song was cleared with (shown later on the music wheel).
FlareGauge.SaveClear(pn)

return Def.ActorFrame{

	Def.Sprite{
		InitCommand=function(s) 
			s:player(pn):x(pn== PLAYER_1 and _screen.cx-175 or _screen.cx+205)
			s:y(_screen.cy-70):zoom(0.667):queuecommand("Set") 
		end,
		SetCommand=function(s) s:Load(THEME:GetPathG("","Grade/"..Grade)) end,
	};
	-- FLARE earned: texture at the top right of the Grade (position and size in Scripts/08 FlareGauge.lua).
	-- Without the PNG the roman numeral is shown as text, so it can be tested.
	Def.ActorFrame{
		InitCommand=function(s)
			local lv = FlareGauge.AchievedLevel(pn)
			s:visible(lv ~= nil)
			if not lv then return end
			local o = FlareGauge.ResultOffset
			s:player(pn):xy((pn == PLAYER_1 and _screen.cx-175 or _screen.cx+205) + o.x, _screen.cy-70 + o.y)
			local f = FlareGauge.ResultFile(lv)
			local sp, tx = s:GetChild("S"), s:GetChild("T")
			sp:visible(f ~= nil)
			tx:visible(f == nil)
			if f then sp:Load(f):zoom(FlareGauge.ResultZoom) else tx:settext(FlareGauge.Roman[lv]):diffuse(color(FlareGauge.Colors[lv])) end
		end,
		Def.Sprite{ Name = "S" },
		Def.BitmapText{ Name = "T", Font = "_swis721 blk bt 28px", InitCommand = function(s) s:zoom(1.2) end },
	};
	Def.Sprite{
		InitCommand=function(s)
			s:player(pn):x(pn== PLAYER_1 and _screen.cx-176 or _screen.cx+198)
			s:y(_screen.cy-12):zoom(0.667):queuecommand("Set") 
		end,
		SetCommand=function(s)
			if (Award == "StageAward_FullComboW1") then
													s:Load(THEME:GetPathG("","Grade/FullCombo_W1"))
			elseif ((Award == "StageAward_SingleDigitW2") 
			or (Award == "StageAward_OneW2") 
			or (Award == "StageAward_FullComboW2")) then
													s:Load(THEME:GetPathG("","Grade/FullCombo_W2"))
			elseif ((Award == "StageAward_SingleDigitW3") 
			or (Award == "StageAward_OneW3") 
			or (Award == "StageAward_FullComboW3")) then 
													s:Load(THEME:GetPathG("","Grade/FullCombo_W3"))
			elseif (STATSMAN:GetCurStageStats():GetPlayerStageStats(pn):FullComboOfScore('TapNoteScore_W4')) then
													s:Load(THEME:GetPathG("","Grade/FullCombo_W4"))
			end
		end,
		
	};
};