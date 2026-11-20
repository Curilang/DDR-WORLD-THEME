return Def.ActorFrame{
	Def.ActorFrame{
		CloseCommand=function(s) SOUND:PlayOnce(THEME:GetPathS("WORLD/Cleared","Close")) end,
		OpenCommand=function(s) SOUND:PlayOnce(THEME:GetPathS("WORLD/Cleared","Open")) end,
		FailedCloseCommand=function(s) SOUND:PlayOnce(THEME:GetPathS("WORLD/Door","Failed")) end,
		FailedOpenCommand=function(s) SOUND:PlayOnce(THEME:GetPathS("WORLD/Cleared","Open")) end,
	};
	-- Failed
	Def.Sprite{
		Texture="bg_failed",
		InitCommand=function(s) s:FullScreen():diffusealpha(0) end,
		FailedCloseCommand=function(s) s:linear(0.2):diffusealpha(1) end,
		FailedOpenCommand=function(s) s:diffusealpha(1):sleep(0.1):linear(0.2):diffusealpha(0) end,
	};
	Def.Sprite{
		Texture="stage_failed",
		InitCommand=function(s) s:xy(_screen.cx,_screen.cy-10):zoomx(0.667):zoomy(0):diffusealpha(0) end,
		FailedCloseCommand=function(s) s:linear(0.2):diffusealpha(1):zoomy(0.667):decelerate(1):y(_screen.cy) end,
		FailedOpenCommand=function(s) s:y(_screen.cy):diffusealpha(1):zoomy(0.667):linear(0.1):zoom(0.677):linear(0.2):zoomy(0):diffusealpha(0) end,
	};
	-- Cleared
	Def.Sprite{
		Texture="center_star",
		InitCommand=function(s) s:zoomx(0.667):zoomy(0):Center() end,
		CloseCommand=function(s) s:sleep(0.05):linear(0.1):zoomy(0.667):sleep(0.1):linear(0.01):diffusealpha(0)  end,
	}, 
	Def.Sprite{
		Texture="rocket",
		InitCommand=function(s) s:zoom(5):xy(_screen.l+100,_screen.b+100):diffusealpha(0) end,
		CloseCommand=function(s) s:diffusealpha(1):linear(0.2):xy(_screen.r,_screen.t-300):linear(0.01):diffusealpha(0) end,
	},
	--Background
	Def.Sprite{
		Texture="line",
		InitCommand=function(s) s:zoomx(0):zoomy(2):Center():rotationz(50):diffuse(color("#00fdc1")) end,
		CloseCommand=function(s) s:sleep(0.18):linear(0.2):zoomx(7.2) end,
		OpenCommand=function(s) s:zoomx(7.2):sleep(0.3):linear(0.2):zoomx(0) end,
	},
	
	--Black ones
	Def.Sprite{
		Texture="line",
		InitCommand=function(s) 
			s:zoomx(0):zoomy(2):xy(_screen.cx-260,_screen.cy):rotationz(48):diffuse(color("#000000")):diffusealpha(0.04)
		end,
		CloseCommand=function(s) s:sleep(0.18):linear(0.1):zoomx(1):decelerate(1):zoomx(0.9) end,
		OpenCommand=function(s) s:zoomx(0.9):linear(0.2):zoomx(1):linear(0.2):zoomx(0) end,
	},
	Def.Sprite{
		Texture="line",
		InitCommand=function(s) 
			s:zoomx(0):zoomy(2):xy(_screen.cx+190,_screen.cy):rotationz(48):diffuse(color("#000000")):diffusealpha(0.04)
		end,
		CloseCommand=function(s) s:sleep(0.18):linear(0.1):zoomx(1):decelerate(1):zoomx(0.9) end,
		OpenCommand=function(s) s:zoomx(0.9):linear(0.2):zoomx(1):linear(0.2):zoomx(0) end,
	},
	Def.Sprite{
		Texture="line",
		InitCommand=function(s) 
			s:zoomx(0):zoomy(2):xy(_screen.cx+390,_screen.cy):rotationz(48):diffuse(color("#000000")):diffusealpha(0.04)
		end,
		CloseCommand=function(s) s:sleep(0.18):linear(0.1):zoomx(0.7):decelerate(1):zoomx(0.6) end,
		OpenCommand=function(s) s:zoomx(0.6):linear(0.2):zoomx(0.8):linear(0.2):zoomx(0) end,
	},	
	-- Yellow ones
	Def.Sprite{
		Texture="line",
		InitCommand=function(s) s:zoomx(0):zoomy(2):xy(_screen.cx-120,_screen.cy):rotationz(48):diffuse(color("#fef501")) end,
		CloseCommand=function(s) s:sleep(0.18):linear(0.1):zoomx(0.8):decelerate(1.5):zoomx(0.6) end,
		OpenCommand=function(s) s:zoomx(0.6):linear(0.2):zoomx(0.7):linear(0.2):zoomx(0) end,
	},
	Def.Sprite{
		Texture="line",
		InitCommand=function(s) s:zoomx(0):zoomy(2):xy(_screen.cx+18,_screen.cy):rotationz(48):diffuse(color("#fde200")) end,
		CloseCommand=function(s) s:sleep(0.18):linear(0.1):zoomx(0.75):decelerate(1.5):zoomx(0.6) end,
		OpenCommand=function(s) s:zoomx(0.6):linear(0.2):zoomx(0.7):linear(0.2):zoomx(0) end,
	},
	Def.Sprite{
		Texture="line",
		InitCommand=function(s) s:zoomx(0):zoomy(2):xy(_screen.cx+170,_screen.cy):rotationz(48):diffuse(color("#fbf766")) end,
		CloseCommand=function(s) s:sleep(0.18):linear(0.1):zoomx(0.8):decelerate(1.5):zoomx(0.6) end,
		OpenCommand=function(s) s:zoomx(0.6):linear(0.2):zoomx(0.7):linear(0.2):zoomx(0) end,
	},
	-- mhe
	Def.Sprite{
		Texture="center_splash",
		InitCommand=function(s) s:zoom(0):Center() end,
		CloseCommand=function(s) s:sleep(0.18):decelerate(0.5):zoom(3.4):sleep(0.1):linear(0.01):diffusealpha(0) end,
	},
	Def.Sprite{
		Texture="stage_cleared",
		InitCommand=function(s) s:zoomx(0):zoomy(0.667):Center() end,
		CloseCommand=function(s) s:sleep(0.18):linear(0.15):zoomx(0.63):linear(0.8):zoomx(0.667) end,
		OpenCommand=function(s) s:zoomx(0.667):smooth(0.3):zoom(0.7):decelerate(0.2):zoom(0) end,
	},
	Def.Sprite{
		Texture="planet_right",
		InitCommand=function(s) s:zoom(0.667):xy(_screen.r+51,_screen.t-87):diffusealpha(0) end,
		CloseCommand=function(s) s:diffusealpha(1):sleep(0.2):decelerate(0.5):addx(-180):addy(180) end,
		OpenCommand=function(s) s:diffusealpha(1):addx(-180):addy(180):sleep(0.2):linear(0.2):zoom(0.777):addx(185):addy(-185):linear(0.1):diffusealpha(0) end,
	},
	Def.Sprite{
		Texture="planet_left",
		InitCommand=function(s) s:zoom(0.667):xy(_screen.l-58,_screen.b+84):diffusealpha(0) end,
		CloseCommand=function(s) s:diffusealpha(1):sleep(0.2):decelerate(0.5):addx(183):addy(-183) end,
		OpenCommand=function(s) s:diffusealpha(1):addx(183):addy(-183):sleep(0.2):linear(0.2):zoom(0.777):addx(-195):addy(195):linear(0.1):diffusealpha(0) end,
	},
	Def.Sprite{
		Texture="side_star",
		InitCommand=function(s) s:zoom(0):xy(_screen.l+124,_screen.t+99):queuecommand("Anim") end,
		AnimCommand=function(s) s:diffuseshift():effectcolor1(1,1,1,1):effectcolor2(1,1,1,0.9):effectperiod(0.2) end,
		CloseCommand=function(s) s:zoom(0):sleep(0.3):decelerate(0.5):zoom(0.667) end,
		OpenCommand=function(s) s:stoptweening():zoom(0.667):linear(0.2):zoom(0.7):linear(0.16):zoom(0) end,
	},
	Def.Sprite{
		Texture="side_star",
		InitCommand=function(s) s:zoom(0):xy(_screen.r-130,_screen.b-89):queuecommand("Anim") end,
		AnimCommand=function(s) s:diffuseshift():effectcolor1(1,1,1,1):effectcolor2(1,1,1,0.9):effectperiod(0.2) end,
		CloseCommand=function(s) s:zoom(0):sleep(0.3):decelerate(0.5):zoom(0.667) end,
		OpenCommand=function(s) s:stoptweening():zoom(0.667):linear(0.2):zoom(0.7):linear(0.16):zoom(0) end,
	},
};