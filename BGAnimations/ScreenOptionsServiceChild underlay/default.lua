local serv = IsOptionService() or IsOptionManageProfiles() or IsPremiumCustomizer()

return Def.ActorFrame {
	Def.Sprite{
		Texture="base",
		InitCommand=function(s) s:diffusealpha(0):xy(_screen.cx,serv and _screen.cy-25 or _screen.cy-9)
			s:setsize(serv and 500 or 720,serv and 300 or 330)
		end,
		OnCommand=function(s) s:linear(0.25):diffusealpha(1) end,
	};
	Def.Sprite{
		Texture="botm",
		InitCommand=function(s) s:diffusealpha(0):xy(_screen.cx,serv and _screen.b-86 or _screen.b-62)
			s:setsize(serv and 450 or 500,50)
		end,
		OnCommand=function(s) s:linear(0.25):diffusealpha(1) end,
	};
	Def.Sprite{
		Texture="opti",
		InitCommand=function(s) s:diffusealpha(0):zoom(0.6)
			s:xy(serv and _screen.cx-198 or _screen.cx-300,_screen.t+79) 
		end,
		OnCommand=function(s) s:linear(0.25):diffusealpha(1) end,
	},
	Def.Sprite{
		Texture="expl",
		InitCommand=function(s) s:diffusealpha(0):zoom(0.6) 
			s:xy(serv and _screen.cx+220 or _screen.cx+250,serv and _screen.b-105 or _screen.b-80) end,
		OnCommand=function(s) s:linear(0.25):diffusealpha(1) end,
		
	},
};
