return Def.ActorFrame{
		Def.Sprite{
			Texture="deco",
			InitCommand=function(s) s:FullScreen() end,
		};
		Def.Sprite{
			Texture="cloud",
			InitCommand=function(s) s:Center():zoom(0.667):texcoordvelocity(-0.02,0) end,
		};
		Def.Sprite{
			Texture="line",
			InitCommand=function(s) s:zoom(0.667):xy(_screen.cx-55,_screen.cy+70):rotationz(117)
				s:texcoordvelocity(-0.5,0)
			end,
		};
		Def.Sprite{
			Texture="rocket",
			InitCommand=function(s)
				s:zoom(0.667):xy(_screen.cx+42,SCREEN_TOP+118):vibrate():effectmagnitude(1.5,1.5,1.5) end,
		};
		Def.Sprite{
			Texture="smoke1",
			InitCommand=function(s)
				s:zoom(0.667):xy(_screen.cx,_screen.cy-36)
				s:queuecommand("Animate")
			end,
			AnimateCommand=function(s)
				s:accelerate(1):zoom(0.7):decelerate(1):zoom(0.667)
				s:queuecommand("Animate")
			end,
		};
		Def.Sprite{
			Texture="smoke2",
			InitCommand=function(s)
				s:zoom(0.667):xy(_screen.cx-62,_screen.cy+78):sleep(0.7)
				s:queuecommand("Animate")
			end,
			AnimateCommand=function(s)
				s:accelerate(1):zoom(0.7):decelerate(1):zoom(0.667)
				s:queuecommand("Animate")
			end,
		};
	}