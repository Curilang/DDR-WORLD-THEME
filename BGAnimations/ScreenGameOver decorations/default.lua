return Def.ActorFrame{
	Def.ActorFrame{
		OnCommand=function(s)
			SOUND:PlayOnce(THEME:GetPathS("", "WORLD/Game Over"))
		end,
	};
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/cir_gray"),
		InitCommand=function(s) s:zoom(0.664):xy(_screen.l+53,_screen.cy):diffusealpha(0) end,
		OnCommand=function(s) s:diffusealpha(1):addx(-100):addy(-10):linear(0.25):addx(100):addy(10) end,

	},
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/cir_white"),
		InitCommand=function(s) s:zoom(0.664):xy(_screen.l+53,_screen.cy):diffusealpha(0) end,
		OnCommand=function(s) s:diffusealpha(1):addx(-100):addy(-10):sleep(0.1):linear(0.25):addx(100):addy(10) end,

	},
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/cir_gray"),
		InitCommand=function(s) s:zoom(-0.664):xy(_screen.r-53,_screen.cy):diffusealpha(0) end,
		OnCommand=function(s) s:diffusealpha(1):addx(100):addy(10):linear(0.25):addx(-100):addy(-10) end,

	},
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/cir_white"),
		InitCommand=function(s) s:zoom(-0.664):xy(_screen.r-53,_screen.cy):diffusealpha(0) end,
		OnCommand=function(s) s:diffusealpha(1):addx(100):addy(10):sleep(0.1):linear(0.25):addx(-100):addy(-10) end,
	},
	Def.ActorFrame{
		InitCommand=function(s) s:zoom(0.667):xy(_screen.cx-9,_screen.cy):diffusealpha(0) end,
		OnCommand=function(s) s:linear(0.25):diffusealpha(1) end,
		Def.Sprite{
			Texture="thank you",
			InitCommand=function(s) s:y(-1) end,
		},
		Def.Sprite{
			Texture="copyright",
			InitCommand=function(s) s:xy(2,139) end,
		},
	};
	Def.Quad{
		InitCommand=function(s) s:diffuse(Color("White")):FullScreen():diffusealpha(0) end,
		OnCommand=function(s)  s:sleep(3.5):linear(0.5):diffusealpha(1) end,
	};
};