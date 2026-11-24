local function Mask(x,y,w,h) 
	return Def.Quad{
		InitCommand=function(s) 
			s:clearzbuffer(false):zwrite(true):blend("BlendMode_NoEffect")
			s:xy(x,y):setsize(w,h)
		end,
	}
end

local function CircleMask(v,c,t)
	return Def.Sprite {
		Texture=THEME:GetPathG("","_shared/circle"),
		InitCommand = function(s) s:xy(_screen.cx,_screen.cy-26)
			if v == "Reveal" then
				s:clearzbuffer(false):zwrite(true):blend('BlendMode_NoEffect')
				s:zoom(0):sleep(2.4):linear(0.1):zoom(0.35):linear(1):zoom(0.51)
			else
				s:MaskDest()
				s:diffuse(color(c))
				s:zoom(0):sleep(t):smooth(0.2):zoom(0.51)
			end
		end,
	};
end

local t = Def.ActorFrame{};

t[#t+1] = Def.ActorFrame{
	OnCommand=function(s) s:queuecommand("Play") end,
	PlayCommand=function(s) 
		local sound = THEME:GetPathS("WORLD/Information","in")
		SOUND:PlayOnce(StreamingSound(sound)) 
	end,
};
	
t[#t+1] = LoadActor("_doors");

t[#t+1] = Def.ActorFrame{
	InitCommand=function(s) s:diffusealpha(0) end,
	OnCommand=function(s) s:sleep(2.6):linear(1):diffusealpha(1) end,
	
	LoadActor("ScoreDisplay");
	Def.Quad{
		InitCommand=function(s) s:diffuse(Color.Black):xy(_screen.cx,_screen.cy-16):setsize(301,287):diffusealpha(0.35) end,
	};
};


t[#t+1] = Def.ActorFrame{
	InitCommand=function(s) s:diffusealpha(0) end,
	OnCommand=function(s) s:sleep(2.3):diffusealpha(1) end,
	
	Def.Sprite{
		InitCommand=function(s) s:xy(_screen.cx,_screen.cy-27) end,
		OnCommand=function(s) s:queuecommand("Set") end,
		SetCommand=function(s)
			if GAMESTATE:IsCourseMode() then
				local ent = GAMESTATE:GetCurrentTrail(GAMESTATE:GetMasterPlayerNumber()):GetTrailEntries()
				s:LoadSongImage(ent[1]:GetSong(), 287, 287)
			else
				local song = GAMESTATE:GetCurrentSong()
				s:LoadSongImage(song, 287, 287)
			end
		end,
	};
	
};

t[#t+1] = Def.ActorFrame{
	Mask(_screen.cx,_screen.t+34.5,428,70);
	Mask(_screen.cx,_screen.b-88,428,70);
	Mask(_screen.cx-179,_screen.cy-27,70,287);
	Mask(_screen.cx+179,_screen.cy-27,70,287);
	CircleMask("Reveal");
	CircleMask("Color","#ffffff",2);
	CircleMask("Color","#0cb77e",2.1);
	CircleMask("Color","#0dc474",2.2);
};

t[#t+1] = Def.Sprite{ 
	Texture=THEME:GetPathG("","_shared/circle"), 
	InitCommand=function(s) s:diffuse(color("#00ce9c")):Center():zoom(0.667):diffusealpha(0) end,
	OnCommand=function(s) s:sleep(4.9):decelerate(0.2):diffusealpha(1) end,
};

t[#t+1] = Def.Sprite{ 
	Texture=THEME:GetPathG("","_shared/fade"), 
	InitCommand=function(s) s:Center():FullScreen():zoom(160):diffusealpha(0) end,
	OnCommand=function(s) s:sleep(4.6):diffusealpha(1):decelerate(0.4):zoom(0.667) end,
};
 


return t