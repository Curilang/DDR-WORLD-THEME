return Def.ActorFrame {
	Def.Sprite{
		Texture="icon",
		InitCommand=function(s) s:zoom(0.667):x(SCREEN_RIGHT-29.3):y(_screen.cy-88) end,
	};
	Def.Sprite{
		Texture="paseli",
		InitCommand=function(s) s:zoom(0.667):xy(ThemePrefs.Get("Language") == "English" and _screen.cx+367 or _screen.cx+360,IsTitleMenu() and _screen.cy+115 or _screen.cy+186) 
			s:pause():setstate(GetCurrentLanguage())
		end,
	};
	Def.ActorFrame{
		Condition=not IsTitleMenu(),
		InitCommand=function(s) s:zoom(0.56):xy(_screen.cx,_screen.cy+189):pause():queuecommand("Set") end,
		CoinInsertedMessageCommand=function(s) s:queuecommand("Set") end,
		SetCommand=function(s)
			local canStart = GAMESTATE:GetCoinMode() == 'CoinMode_Free' or GAMESTATE:GetCoinMode() == "CoinMode_Home" or GAMESTATE:EnoughCreditsToJoin()
			local coin = s:GetChild("Coin")
			local button = s:GetChild("Button")
			if canStart then
				coin:Load(THEME:GetPathG("", "ArcadeDecorations/start"))
				button:Load(THEME:GetPathG("", "ArcadeDecorations/button"))
				coin:setstate(GetCurrentLanguage())
				button:setstate(GetCurrentLanguage())
				coin:diffuseshift():effectcolor1(color("#18ff00")):effectcolor2(color("#ffffff")):effectperiod(2.5)
				button:visible(true)
			else
				coin:Load(THEME:GetPathG("", "ArcadeDecorations/coin"))
				coin:setstate(GetCurrentLanguage())
				coin:diffuseshift():effectcolor1(color("#18ff00")):effectcolor2(color("#ffffff")):effectperiod(2.5)
				button:visible(false)
			end
		end,
		Def.Sprite{
			Name="Coin",
			InitCommand=function(s) s:pause() end,
		},
		Def.Sprite{
			Name="Button",
			InitCommand=function(s) s:pause():visible(false) end,
		},
	};
};