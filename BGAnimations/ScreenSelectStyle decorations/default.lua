local t = Def.ActorFrame {
	StandardDecorationFromFileOptional("Footer","Footer");
};

t[#t+1] = Def.Sound{
	File=THEME:GetPathS("WORLD/SelectMode","in"),
	OnCommand=function(s) s:play() end,
};

t[#t+1] = Def.ActorFrame{
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/tex"),
		InitCommand=function(s) s:zoom(0.667):xy(_screen.l+96,_screen.t+39):pause():setstate(GetProjectName()) end,
		OffCommand=function(s) s:linear(0.2):zoomy(0) end,
	},
	Def.Sprite{
		Texture="header",
		InitCommand=function(s) s:zoom(0.667):xy(_screen.cx,_screen.t+68) end,
		OffCommand=function(s) s:linear(0.2):zoomy(0) end,
	},
	Def.Sprite{
		Texture="text",
		InitCommand=function(s) s:zoom(0.667):xy(_screen.cx-34,_screen.t+78) 
			s:pause():setstate(GetCurrentLanguage())
		end,
		OffCommand=function(s) s:linear(0.2):zoomy(0) end,
	},
	Def.Sprite{
		Texture="base",
		InitCommand=function(s) s:zoom(0.667):xy(_screen.r+200,_screen.b-70) end,
		OnCommand=function(s) s:linear(0.2):x(_screen.r-173) end,
		OffCommand=function(s) s:linear(0.2):x(_screen.r+200) end,
	},
	Def.Sprite{
		Texture="base",
		InitCommand=function(s) s:zoom(0.667):xy(_screen.l-200,_screen.b-70) end,
		OnCommand=function(s) s:linear(0.2):x(_screen.l+173) end,
		OffCommand=function(s) s:linear(0.2):x(_screen.l-200) end,
	},
};

t[#t+1] = Def.Actor{
	PlayerJoinedMessageCommand=function(self)
		self:queuecommand("Delay1")
	end;
	Delay1Command=function(self)
		self:sleep(2)
		self:queuecommand("SetScreen")
	end;
	SetScreenCommand=function(self)
		if PROFILEMAN:GetNumLocalProfiles() >= 2 then
			SCREENMAN:GetTopScreen():SetNextScreenName("ScreenProfileLoad"):StartTransitioningScreen("SM_GoToNextScreen")
		else
			SCREENMAN:GetTopScreen():SetNextScreenName("ScreenSelectMusic"):StartTransitioningScreen("SM_GoToNextScreen")
		end
	end;
};

-- the menu timer (Scripts/08 MenuTimer.lua)
t[#t+1] = DDRWORLD_MenuTimer("ScreenSelectStyle", MenuTimerPositions.Mode.x, MenuTimerPositions.Mode.y);

return  t;