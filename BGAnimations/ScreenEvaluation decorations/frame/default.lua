local pn, controller = ...;
local tabCount = 7;

local playerKey = ToEnumShortString(controller);
local prefName = "EvaluationPaneState"..playerKey;

local paneState = ThemePrefs.Get(prefName) or 0;

paneState = math.max(0, math.min(tabCount - 1, tonumber(paneState) or 0));

ThemePrefs.Set(prefName, paneState);

return Def.ActorFrame{
	OffCommand=function(s) s:linear(0.15):zoomy(0) end,
	CodeMessageCommand=function(s,p)
	if p.PlayerNumber ~= controller then return; end;
		if p.Name == "Left" then
			if paneState > 0 then
				SOUND:PlayOnce(THEME:GetPathS("","WORLD/Next"));
				paneState = paneState - 1;
			end;
		elseif p.Name == "Right" then
			if paneState < tabCount - 1 then
				SOUND:PlayOnce(THEME:GetPathS("","WORLD/Next"));
				paneState = paneState + 1;
			end;
		else
			SCREENMAN:SystemMessage("Unknown button: "..p.Name);
			return;
		end;

		ThemePrefs.Set(prefName, paneState);
		s:playcommand("Update");
	end,

	Def.Sprite{
		Texture="frame",
	},
	Def.Sprite{
		Texture=GetLanguage().."tabs",
		InitCommand=function(s) s:y(-81):pause():setstate(paneState) end,
		UpdateCommand=function(s) s:setstate(paneState) end,
	},
	-- Used Calories
	LoadActor("0",pn)..{
		InitCommand=function(s)		s:diffusealpha(paneState == 0 and 1 or 0) end,
		UpdateCommand=function(s)	s:diffusealpha(paneState == 0 and 1 or 0) end,
	},
	-- Simple Results
	LoadActor("1",pn)..{
		InitCommand=function(s)		s:diffusealpha(paneState == 1 and 1 or 0) end,
		UpdateCommand=function(s)	s:diffusealpha(paneState == 1 and 1 or 0) end,
	},
	-- Details
	LoadActor("2",pn)..{
		InitCommand=function(s)		s:diffusealpha(paneState == 2 and 1 or 0) end,
		UpdateCommand=function(s)	s:diffusealpha(paneState == 2 and 1 or 0) end,
	},
	-- Play Graph
	LoadActor("3",pn)..{
		InitCommand=function(s)		s:diffusealpha(paneState == 3 and 1 or 0) end,
		UpdateCommand=function(s)	s:diffusealpha(paneState == 3 and 1 or 0) end,
	},
	-- FLARE SKILL
	LoadActor("4",pn)..{
		InitCommand=function(s)		s:diffusealpha(paneState == 4 and 1 or 0) end,
		UpdateCommand=function(s)	s:diffusealpha(paneState == 4 and 1 or 0) end,
	},
	-- Compare with rivals
	LoadActor("5",pn)..{
		InitCommand=function(s)		s:diffusealpha(paneState == 5 and 1 or 0) end,
		UpdateCommand=function(s)	s:diffusealpha(paneState == 5 and 1 or 0) end,
	},
	-- WORLD LEAGUE
	LoadActor("6",pn)..{
		InitCommand=function(s)		s:diffusealpha(paneState == 6 and 1 or 0) end,
		UpdateCommand=function(s)	s:diffusealpha(paneState == 6 and 1 or 0) end,
	},

};