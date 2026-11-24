return Def.ActorFrame{
	Def.ActorFrame{
		InitCommand=function(s) s:zoom(0.667):y(171) end,
		GainFocusCommand=function(s) s:visible(true) end,
		LoseFocusCommand=function(s) s:visible(false) end,
		Def.Sprite{
			Texture="button_P1",
			InitCommand=function(s) s:x(-810):pause():setstate(GetCurrentLanguage()) end,
			OnCommand=function(s) s:linear(0.2):x(-259) end,
			OffCommand=function(s) s:linear(0.2):x(-810) end,
		},
		Def.Sprite{
			Texture="button_P2",
			InitCommand=function(s) s:x(810):pause():setstate(GetCurrentLanguage()) end,
			OnCommand=function(s) s:linear(0.2):x(266) end,
			OffCommand=function(s) s:linear(0.2):x(810) end,
		},
	},
	Def.ActorFrame{
		InitCommand=function(s) s:xy(77,-12):zoom(0.667) end,
		OnCommand=function(s) s:zoomy(0):linear(0.2):zoomy(0.667) end,
		OffCommand=function(s) s:zoomy(0.667):linear(0.15):zoomy(0) end,
		Def.Sprite{
			Texture=THEME:GetPathG("ScreenSelectStyle","Scroll/base_scroll"),
			InitCommand=function(s) s:y(-33) end,
		},
		Def.Sprite{
			Texture="main",
			InitCommand=function(s) s:pause():y(-72) end,
			GainFocusCommand=function(s) s:setstate(1) end, 
			LoseFocusCommand=function(s) s:setstate(0) end, 
		},
		Def.Sprite{
			Texture="text",
			InitCommand=function(s) s:xy(2,76):pause():setstate(GetCurrentLanguage()) end,
		},
		Def.Quad{
			InitCommand=function(s) s:y(147):setsize(224,63) end,
			GainFocusCommand=function(s) s:diffuse(color("#00ffba")) end,
			LoseFocusCommand=function(s) s:diffuse(color("#8e8d8e")) end,
		},
		Def.Sprite{
			Texture=THEME:GetPathG("ScreenSelectStyle","Scroll/next"),
			InitCommand=function(s) s:y(147):pause():setstate(GetCurrentLanguage()) end,
		},
		StripeLine{
			Name = "Line", 
			w = 224, h = 8, y = 175, visible = false,
			GainFocusCommand = function(s) s:visible(true) end,
			LoseFocusCommand = function(s) s:visible(false) end,
		},
	}
};