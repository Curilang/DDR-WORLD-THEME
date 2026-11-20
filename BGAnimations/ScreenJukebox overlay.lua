return Def.ActorFrame{
	Def.Quad{
		InitCommand=function(s) s:diffuse(Color.White):FullScreen():diffusealpha(0) end,
		BeginCommand=function(s) s:diffusealpha(1):linear(0.2):diffusealpha(0) end,
		OffCommand=function(s) s:diffusealpha(0):linear(0.2):diffusealpha(1) end,
	},
};