return Def.ActorFrame{
	Def.ActorFrame{
		InitCommand=function(s) s:zoom(0.667):xy(_screen.cx,_screen.cy+190) end,
		Def.Sprite{
			Texture="base",
			InitCommand=function(s) s:pause() end,
			GainFocusCommand=function(s) s:setstate(1) end,
			LoseFocusCommand=function(s) s:setstate(0) end,
		},
		Def.Sprite{
			Texture=THEME:GetPathG("","_shared/line"),
			InitCommand=function(s) s:y(30):setsize(238,8):texcoordvelocity(-0.15,0) end,
			GainFocusCommand=function(s) s:visible(true) end,
			LoseFocusCommand=function(s) s:visible(false) end,
		},
		Def.BitmapText{
			Font="_swis721 blk bt 28px",
			InitCommand=function(s) s:settext(Var("GameCommand"):GetText()):maxwidth(180) end,
			GainFocusCommand=function(s) s:stoptweening():diffuse(color("#000000")):linear(0.09):zoom(0.85):diffusealpha(1) end,
			LoseFocusCommand=function(s) s:stoptweening():diffuse(color("#ffffff")):linear(0.09):zoom(0.8):diffusealpha(1) end,
		};
	};
};
