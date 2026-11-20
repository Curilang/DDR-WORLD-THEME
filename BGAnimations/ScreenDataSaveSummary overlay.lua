local x = Def.ActorFrame{};

x[#x+1] = Def.ActorFrame{
	CodeMessageCommand = function(self, params)
		if params.Name == 'Start' or params.Name == 'Center' then
			MESSAGEMAN:Broadcast("StartButton");
			SCREENMAN:GetTopScreen():Finish();
		end;
	end;
};

local function UpdateInternal(self,pn)
	local ProfileText = self:GetChild('ProfileText');
	local joinframe = self:GetChild('JoinFrame');
	local bigframe = self:GetChild('BigFrame');
	local RegionText = self:GetChild('RegionText');
	
	
	bigframe:visible(true);
	ProfileText:settext(PROFILEMAN:GetProfile(pn):GetDisplayName());
	local pn = (pn == PLAYER_1) and 1 or 2;
	RegionText:settext(ThemePrefs.Get("RegionP"..pn));
end

for pn in ivalues(GAMESTATE:GetEnabledPlayers()) do
	x[#x+1] = Def.ActorFrame{
		InitCommand=function(s) 
			s:xy(pn==PLAYER_1 and _screen.cx-146 or _screen.cx+146,_screen.cy+9):zoom(0.667) 
		end,
		OnCommand=function(s) UpdateInternal(s,pn) end,
		children = LoadPlayerStuff(pn);
	};
end

x[#x+1] = Def.ActorFrame {
	Def.Sprite {
		Texture=THEME:GetPathG("","_shared/ddr"),
		InitCommand=function(s) s:zoom(0.667):xy(_screen.l+96,_screen.t+39) end,
		OffCommand=function(s) s:linear(0.2):diffusealpha(0) end,
	};
	LoadActor(THEME:GetPathS("WORLD/Profile", "in"))..{
		OnCommand=cmd(play);
	};
	LoadActor( THEME:GetPathS("Common","start") )..{
		OffCommand=cmd(play);
	};
	-- the menu timer (Scripts/08 MenuTimer.lua), under the doors; the same place as on the profile selection
	DDRWORLD_MenuTimerPerPlayer("ScreenDataSaveSummary", MenuTimerPositions.Profile, MenuTimerPositions.ProfileP2);
	loadfile(THEME:GetPathB("","_doors"))()..{
		OnCommand=function(s) s:finishtweening():playcommand("Open") end,
	};
};
  
return x;