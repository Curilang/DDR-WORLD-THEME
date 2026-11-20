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

local STYLE_FRAME = {
	StyleType_OnePlayerOneSide   = 2,
	StyleType_TwoPlayersTwoSides = 1,
	StyleType_OnePlayerTwoSides  = 4,
}

local FOLDER_FRAME = {
	FIRST   = 0,   -- FIRST STEP
	POP     = 1,   -- POP MUSIC
	VIRTUAL = 2,   -- VIRTUAL POP
	ANIME   = 3,   -- ANIME & GAME
	TOUHOU  = 4,   -- TOUHOU PROJECT
	GAMERS  = 5,   -- FOR MUSIC GAMERS
	ALL     = 6,   -- ALL MUSIC
}

local function FolderFrame()
	local ok, id = pcall(function() return Filter.GetFolder() end)
	return (ok and FOLDER_FRAME[id]) or FOLDER_FRAME.ALL
end

local DDR_Y        = SCREEN_TOP+63.5
local DDR_Y_FOLDER = SCREEN_TOP+42.5

return Def.ActorFrame {
	Def.Sprite{
		Texture="DDR",
		InitCommand=function(s) s:zoom(0.667):xy(SCREEN_LEFT+65,_screen.t+25) end,
	};
	Def.Sprite{
		Texture="FOLDER",
		InitCommand=function(s) s:zoom(0.667):xy(SCREEN_LEFT+134,SCREEN_TOP+42.5):pause():setstate(FolderFrame()) end,
		FolderOpenedMessageCommand=function(s) s:visible(false) end,
		FolderClosedMessageCommand=function(s) s:setstate(FolderFrame()):visible(true) end,
	};
	Def.Sprite{
		Texture="STYLE",
		InitCommand=function(s)
			s:zoom(0.667):xy(SCREEN_LEFT+61,SCREEN_TOP+63.5):pause()
			s:setstate(STYLE_FRAME[GAMESTATE:GetCurrentStyle():GetStyleType()] or 0)
		end,
		FolderOpenedMessageCommand=function(s) s:stoptweening():y(DDR_Y_FOLDER) end,
		FolderClosedMessageCommand=function(s) s:stoptweening():y(DDR_Y) end,
	};
	Def.Sprite{
		Texture="SELECT MUSIC",
		InitCommand=function(s) s:xy(_screen.r-91,_screen.t+27):zoom(0.667) end,
	};
	Def.Sprite{
		Texture="STAGE",
		InitCommand=function(s)
			s:xy(_screen.r-91,_screen.t+53):zoom(0.667):pause():setstate(tRemap[sStage] or 0)
		end,
	};
};
