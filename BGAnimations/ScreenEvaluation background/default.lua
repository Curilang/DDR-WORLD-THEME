local Sound
local SoundTime

if (GAMESTATE:HasEarnedExtraStage() and GAMESTATE:IsExtraStage()) or (GAMESTATE:HasEarnedExtraStage() and GAMESTATE:IsExtraStage2()) or (StreamingMode())then
	Sound = THEME:GetPathS("","_silent")
	SoundTime = 1
else	
	Sound = THEME:GetPathS("WORLD/Evaluation","(loop)")
	SoundTime = 2.4
end

return Def.ActorFrame{
	Def.Sound{
		File=Sound,
		OnCommand=function(s) s:sleep(SoundTime):queuecommand("Play") end,
		PlayCommand=function(s) s:play() end,
	},
	
	Def.Quad{ 
		InitCommand=function(s) s:FullScreen():diffuse(color("#ebebeb")) end 
	},
	Def.Sprite{
		Texture="P1",
		InitCommand=function(s) s:zoom(0.667):xy(_screen.cx-214,_screen.cy) end,
		OnCommand=function(s) s:addx(-300):decelerate(0.7):addx(300) end,
	};
	Def.Sprite{
		Texture="P2",
		InitCommand=function(s) s:zoom(0.667):xy(_screen.cx+213.5,_screen.cy) end,
		OnCommand=function(s) s:addx(300):decelerate(0.7):addx(-300) end,
	};	
	LoadActor("trng_t")..{ 
		InitCommand=function(s) s:xy(_screen.cx,_screen.cy-87):zoom(0.667) end 
	},
	
	LoadActor("deco")..{ 
		InitCommand=function(s) s:setstate(GetProjectName()):zoom(0.667):xy(_screen.cx-133,_screen.cy-255):rotationz(-45)
		s:texcoordvelocity(0.03,0):cropleft(0.44) end, 
	},
	
	LoadActor("trng_b")..{ 
		InitCommand=function(s) s:xy(_screen.cx,_screen.cy+87):zoom(0.667) end 
	},
};
