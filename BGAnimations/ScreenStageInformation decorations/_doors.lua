return Def.ActorFrame{
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/circle"),
		InitCommand=function(s) s:diffuse(color("#00c690")):Center():zoom(0) end,
		OnCommand=function(s) s:linear(0.4):zoom(1.225) end,
	};
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/circle"),
		InitCommand=function(s) s:diffuse(color("#05b070")):Center():zoom(0) end,
		OnCommand=function(s) s:linear(0.2):zoom(0.64) end,
	};
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/circle"),
		InitCommand=function(s) s:diffuse(color("#00bf76")):Center():zoom(0) end,
		OnCommand=function(s) s:linear(0.15):zoom(0.52) end,
	};
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/circle"),
		InitCommand=function(s) s:diffuse(color("#00c979")):Center():zoom(0) end,
		OnCommand=function(s) s:linear(0.1):zoom(0.4) end,
	};
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/circle"),
		InitCommand=function(s) s:diffuse(color("#00ce7d")):Center():zoom(0) end,
		OnCommand=function(s) s:linear(0.05):zoom(0.28) end,
	};
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/pepsi"),
		InitCommand=function(s) s:Center():zoom(0):zoom(0) end,
		OnCommand=function(s) s:linear(0.05):zoom(0.667) end,
	};
	Def.Quad{
		InitCommand=function(s) s:diffuse(Color.Black):setsize(_screen.w,50):xy(_screen.cx,_screen.t-25) end,
		OnCommand=function(s) s:linear(0.5):y(_screen.t+25) end,
	};
	Def.Quad{
		InitCommand=function(s) s:diffuse(Color.Black):setsize(_screen.w,50):xy(_screen.cx,_screen.b+25) end,
		OnCommand=function(s) s:linear(0.5):y(_screen.b-25) end,
	};
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/bar"),
		InitCommand=function(s) s:xy(_screen.cx,_screen.cy-165)
			s:zoomx(0.667):zoomy(0):diffuse(color("#0de581"))
			s:queuecommand("Anim") 
		end,
		AnimCommand=function(s) 
			s:sleep(0.05):zoomy(0.667):decelerate(0.2):zoomy(0)
			s:queuecommand("Anim") 
		end,
	};
	--Medium Up 3
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/bar"),
		InitCommand=function(s) s:xy(_screen.cx,_screen.cy-85)
			s:zoomx(0.667):zoomy(0):diffuse(color("#13fe9a"))
			s:queuecommand("Anim") 
		end,
		AnimCommand=function(s) 
			s:sleep(0.15):zoomy(0.667):decelerate(0.2):zoomy(0)
			s:queuecommand("Anim") 
		end,
	};
	--Medium Down 4
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/bar"),
		InitCommand=function(s) s:xy(_screen.cx,_screen.cy+140)
			s:zoomx(0.667):zoomy(0):diffuse(color("#13fe9a"))
			s:queuecommand("Anim") 
		end,
		AnimCommand=function(s) 
			s:sleep(0.2):zoomy(0.667):decelerate(0.2):zoomy(0)
			s:queuecommand("Anim") 
		end,
	};
	--Down 2
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/bar"),
		InitCommand=function(s) s:xy(_screen.cx,_screen.cy+185)
			s:zoomx(0.667):zoomy(0):diffuse(color("#0de581"))
			s:queuecommand("Anim") 
		end,
		AnimCommand=function(s) 
			s:sleep(0.1):zoomy(0.667):decelerate(0.2):zoomy(0)
			s:queuecommand("Anim") 
		end,
	};
	LoadActor("StageDisplay");
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/shadow"),
		InitCommand=function(s) s:Center():zoom(0):diffusealpha(0.5) end,
		OnCommand=function(s) s:sleep(1):linear(0.2):zoom(0.667) end,
	};
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/circle"),
		InitCommand=function(s) s:diffuse(color("#00c690")):Center():zoom(0) end,
		OnCommand=function(s) s:sleep(1.1):linear(0.5):zoom(1.225) end,
	};
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/circle"),
		InitCommand=function(s) s:diffuse(color("#1df4ae")):Center():zoom(0) end,
		OnCommand=function(s) s:sleep(1.2):linear(0.5):zoom(1.225):diffusealpha(0) end,
	};
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/circle"),
		InitCommand=function(s) s:diffuse(color("#00c692")):Center():zoom(0) end,
		OnCommand=function(s) s:sleep(1.3):linear(0.5):zoom(1.225):diffusealpha(0) end,
	};
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/logo_white"),
		InitCommand=function(s) s:zoom(0.667):Center():diffusealpha(0) end,
		OnCommand=function(s) s:sleep(1.5):linear(0.2):diffusealpha(1) end,
	},
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/cir_gray"),
		InitCommand=function(s) s:zoom(-0.664):xy(_screen.r-53,_screen.cy):diffusealpha(0) end,
		OnCommand=function(s) s:sleep(1.4):diffusealpha(1):addx(100):addy(10):linear(0.25):addx(-100):addy(-10) end,
	},
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/cir_white"),
		InitCommand=function(s) s:zoom(-0.664):xy(_screen.r-53,_screen.cy):diffusealpha(0) end,
		OnCommand=function(s) s:sleep(1.45):diffusealpha(1):addx(100):addy(10):linear(0.25):addx(-100):addy(-10) end,
	},
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/cir_gray"),
		InitCommand=function(s) s:zoom(0.664):xy(_screen.l+53,_screen.cy):diffusealpha(0) end,
		OnCommand=function(s) s:sleep(1.4):diffusealpha(1):addx(-100):addy(-10):linear(0.25):addx(100):addy(10) end,
	},
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/cir_white"),
		InitCommand=function(s) s:zoom(0.664):xy(_screen.l+53,_screen.cy):diffusealpha(0) end,
		OnCommand=function(s) s:sleep(1.45):diffusealpha(1):addx(-100):addy(-10):linear(0.25):addx(100):addy(10) end,
	},
	
};