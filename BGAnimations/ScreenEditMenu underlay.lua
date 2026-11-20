return Def.ActorFrame {
	Def.Sprite{
		Texture=THEME:GetPathB("ScreenOptionsServiceChild","underlay/base"),
		InitCommand=function(s) s:xy(_screen.cx+10,_screen.cy-10):setsize(750,330):diffusealpha(0) end,
		OnCommand=function(s) s:linear(0.25):diffusealpha(1) end,
	};
	Def.Sprite{
		Texture=THEME:GetPathB("ScreenOptionsServiceChild","underlay/botm"),
		InitCommand=function(s) s:xy(_screen.cx,_screen.b-60):setsize(450,52):diffusealpha(0) end,
		OnCommand=function(s) s:linear(0.25):diffusealpha(1) end,
	};
	Def.Sprite{
		Texture=THEME:GetPathB("ScreenOptionsServiceChild","underlay/edit"),
		InitCommand=function(s) s:zoom(0.6):xy(_screen.cx-305,_screen.t+77):diffusealpha(0) end,
		OnCommand=function(s) s:linear(0.25):diffusealpha(1) end,
		
	},
	Def.Sprite{
		Texture=THEME:GetPathB("ScreenOptionsServiceChild","underlay/expl"),
		InitCommand=function(s) s:zoom(0.6):xy(_screen.cx+215,_screen.b-77):diffusealpha(0) end,
		OnCommand=function(s) s:linear(0.25):diffusealpha(1) end,
	},
};
