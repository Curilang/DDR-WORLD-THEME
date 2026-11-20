return Def.ActorFrame{
	Def.ActorFrame{
		OpenCommand=function(s) SOUND:PlayOnce(THEME:GetPathS("WORLD/Door","Open")) end,
	};
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/circle"),
		InitCommand=function(s) s:diffuse(color("#00ce9c")):zoom(0.1):Center():diffusealpha(0) end,
		CloseCommand=function(s) s:linear(0.6):zoom(1.225):diffusealpha(1) end,
		OpenCommand=function(s) s:zoom(1.225):diffusealpha(1):sleep(0.2):linear(0.6):zoom(0.1):diffusealpha(0) end,
		StandCommand=function(s) s:zoom(1.225):diffusealpha(1) end,
	},
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/circle"),
		InitCommand=function(s) s:zoom(0.1):Center():diffusealpha(0) end,
		CloseCommand=function(s) s:sleep(0.1):diffusealpha(0.4):linear(0.5):zoom(1.225):diffusealpha(0) end,
		OpenCommand=function(s) s:zoom(1.225):diffusealpha(1):sleep(0.1):linear(0.6):zoom(0.1):diffusealpha(0) end,
	},
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/circle"),
		InitCommand=function(s) s:diffuse(color("#00ce9c")):zoom(0.1):Center():diffusealpha(0) end,
		CloseCommand=function(s) s:sleep(0.2):diffusealpha(0.5):linear(0.4):zoom(1.225):diffusealpha(0) end,
		OpenCommand=function(s) s:zoom(1.225):diffusealpha(1):linear(0.6):zoom(0.1):diffusealpha(0) end,
	},
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/cir_gray"),
		InitCommand=function(s) s:zoom(0.664):xy(_screen.l+53,_screen.cy):diffusealpha(0) end,
		CloseCommand=function(s) s:diffusealpha(1):addx(-100):addy(-10):linear(0.25):addx(100):addy(10) end,
		OpenCommand=function(s) s:diffusealpha(1):sleep(0.05):linear(0.4):addx(-100):addy(-10):diffusealpha(0) end,
		StandCommand=function(s) s:diffusealpha(1) end,
	},
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/cir_white"),
		InitCommand=function(s) s:zoom(0.664):xy(_screen.l+53,_screen.cy):diffusealpha(0) end,
		CloseCommand=function(s) s:diffusealpha(1):addx(-100):addy(-10):sleep(0.2):linear(0.25):addx(100):addy(10) end,
		OpenCommand=function(s) s:diffusealpha(1):linear(0.3):addx(-100):addy(-10):diffusealpha(0) end,
		StandCommand=function(s) s:diffusealpha(1) end,
	},
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/cir_gray"),
		InitCommand=function(s) s:zoom(-0.664):xy(_screen.r-53,_screen.cy):diffusealpha(0) end,
		CloseCommand=function(s) s:diffusealpha(1):addx(100):addy(10):linear(0.25):addx(-100):addy(-10) end,
		OpenCommand=function(s) s:diffusealpha(1):sleep(0.05):linear(0.4):addx(100):addy(10):diffusealpha(0) end,
		StandCommand=function(s) s:diffusealpha(1) end,
	},
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/cir_white"),
		InitCommand=function(s) s:zoom(-0.664):xy(_screen.r-53,_screen.cy):diffusealpha(0) end,
		CloseCommand=function(s) s:diffusealpha(1):addx(100):addy(10):sleep(0.2):linear(0.25):addx(-100):addy(-10) end,
		OpenCommand=function(s) s:diffusealpha(1):linear(0.3):addx(100):addy(10):diffusealpha(0) end,
		StandCommand=function(s) s:diffusealpha(1) end,
	},
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/logo_white"),
		InitCommand=function(s) s:zoom(0.867):Center():diffusealpha(0) end,
		CloseCommand=function(s) s:sleep(0.2):linear(0.2):zoom(0.667):diffusealpha(1) end,
		OpenCommand=function(s) s:diffusealpha(1):zoom(0.667):sleep(0.2):linear(0.2):diffusealpha(0) end,
		StandCommand=function(s) s:zoom(0.667):diffusealpha(1) end,
	},

};