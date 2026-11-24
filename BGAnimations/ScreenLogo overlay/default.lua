-- For other themes
PREFSMAN:SetPreference('SongBackgrounds', true)

return Def.ActorFrame { 
	Def.ActorFrame{
		OnCommand=function(s)
			SOUND:PlayOnce(THEME:GetPathS("WORLD/ScreenLogo", "in"))
		end,
	};
	
	Def.Sprite{
		Texture="logo",
		InitCommand=function(s) s:xy(_screen.cx,_screen.cy-40):zoom(0.667):pause():setstate(EasterEgg() and 2 or GetProjectName()) end,
	};
	Def.Sprite{
		Texture="copyright",
		InitCommand=function(s) s:xy(_screen.cx,SCREEN_BOTTOM-86):zoom(0.667) end,
	};
	Def.Quad{
		InitCommand=function(s) s:diffuse(Color("White")):FullScreen() end,
		OnCommand=function(s) 
			if IsLogo() then
				s:linear(0.5):diffusealpha(0):sleep(7):linear(0.25):diffusealpha(1) 
			elseif IsTitleMenu() or IsTitleJoin() then 
				s:linear(0.5):diffusealpha(0)
			end
		end
	};
	GetSoftwareVersion();
	LoadActor(THEME:GetPathG("","ArcadeDecorations"));
};