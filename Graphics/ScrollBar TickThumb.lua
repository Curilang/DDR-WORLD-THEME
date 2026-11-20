return Def.ActorFrame{
	Def.Quad{
		InitCommand=function(s) 
			s:diffuse(color("#ffffff"))
			s:setsize(18,120)
			s:xy(_screen.cx-81,_screen.cy-93) 
		end,
	};
	Def.Quad{
		InitCommand=function(s) 
			s:diffuse(color("#ffffff"))
			s:setsize(18,120)
			s:xy(_screen.cx-773,_screen.cy-93) end,
	};
};

