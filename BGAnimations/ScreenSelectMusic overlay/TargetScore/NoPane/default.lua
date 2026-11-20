return Def.ActorFrame{
    Def.Quad{
		InitCommand=function(s) s:diffuse(Color.White):setsize(221,14) end,
    };
    Def.ActorFrame{
		InitCommand=function(s) s:zoom(0.667) end,
        Def.Sprite{
            Texture="TARGET",
            InitCommand=function(s) s:queuecommand("Show") end,
            ShowCommand=function(s) s:linear(0.2):diffusealpha(1):queuecommand("Anim") end,
            AnimCommand=function(s) s:sleep(2.45):queuecommand("Stop") end,
            StopCommand=function(s) s:linear(0.2):diffusealpha(0):sleep(6):queuecommand("Show") end,
        };
        Def.Sprite{
            Texture="GROOVE",
            InitCommand=function(s) s:diffusealpha(0):sleep(3):queuecommand("Show") end,
            ShowCommand=function(s) s:linear(0.2):diffusealpha(1):queuecommand("Anim") end,
            AnimCommand=function(s) s:sleep(2.45):queuecommand("Stop") end,
            StopCommand=function(s) s:linear(0.2):diffusealpha(0):sleep(6):queuecommand("Show") end,
        };
        Def.Sprite{
            Texture="CLOSE",
            InitCommand=function(s) s:diffusealpha(0):sleep(6):queuecommand("Show") end,
            ShowCommand=function(s) s:linear(0.2):diffusealpha(1):queuecommand("Anim") end,
            AnimCommand=function(s) s:sleep(2.45):queuecommand("Stop") end,
            StopCommand=function(s) s:linear(0.2):diffusealpha(0):sleep(6):queuecommand("Show") end,
        };
    };
};