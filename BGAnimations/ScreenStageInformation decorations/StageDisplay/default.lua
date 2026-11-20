local sStage = GAMESTATE:GetCurrentStage();
local tRemap = {
	Stage_1st		= 0,
	Stage_2nd		= 1,
	Stage_3rd		= 2,
	Stage_4th		= 3,
	Stage_Final		= 4,
	Stage_Extra1	= 5,
	Stage_Extra2	= 6,
	Stage_Event		= 7,
};

if tRemap[sStage] == PREFSMAN:GetPreference("SongsPerPlay") then
	sStage = "Stage_Final";
else
	sStage = sStage;
end;

local Stage = Def.ActorFrame{
	Def.Sprite{
		Texture="STAGE",
		InitCommand=function(s) s:pause():queuecommand("Set") end,
		SetCommand=function(s) s:setstate(tRemap[sStage]) end,
	};
};

----------------------------------------------------------------------------
return Def.ActorFrame {
	Stage..{
		InitCommand=function(s) s:xy(_screen.cx-8,_screen.cy):zoom(1):diffusealpha(0) end,
		OnCommand=function(s) s:sleep(0.1):linear(0.1):diffusealpha(1):linear(0.8):zoom(0.63) end,
	};
};