local t = Def.ActorFrame{
	-- The music wheel and the side panels of the select music screen disappear at once when the menu opens
	-- (like the original: they are hidden in the first frame) and come back when it closes.
	OnCommand=function(self)
		MESSAGEMAN:Broadcast("POMenuOpened")
	end,
	-- When the menu closes (Back or ESC), "ScreenPlayerOptions cancel.lua" sends this message so the panels
	-- and the dark background fade out together, instead of the doors animation.
	POMenuClosingMessageCommand=function(self)
		self:playcommand("Off")
	end,
	Def.Quad{
		InitCommand=function(s) s:diffuse(color("0,0,0,0.5")):FullScreen() end,
		-- Measured from the original: it darkens 50% in about 0.12 s, starting together with the panel bar.
		OnCommand=function(s) s:diffusealpha(0):sleep(0.05):linear(0.12):diffusealpha(0.5) end,
		OffCommand=function(s) s:diffusealpha(0) end,   -- the original closes in one frame
	};
};

-- The song panel (Info) of the select music screen stays above the dark background, not darkened, like the original.
-- The one of the select music screen is below this screen, so another one is drawn here, in the same place (it is
-- the same file). It is written and shown at once: the delay and fade of the select music screen are for song changes.
t[#t+1] = loadfile(THEME:GetPathB("ScreenSelectMusic","overlay/Info"))()..{
	OnCommand=function(s)
		s:stoptweening():playcommand("Set"):diffusealpha(1)
	end,
	OffCommand=function(s) s:stoptweening():diffusealpha(0) end,
};
t[#t+1] = Def.ActorFrame{
	OnCommand=function(s) SOUND:PlayOnce(THEME:GetPathS("WORLD/PlayerOptions","Open")) end,
};

-- Clear the menu's cached values (see Scripts/08 PlayerOptionsRows.lua)
POMenu.ResetCache()

-- options.lua draws and positions each player's panel by itself.
for _,pn in pairs(GAMESTATE:GetEnabledPlayers()) do
	t[#t+1] = LoadActor("options.lua",pn);
end;

return t;
