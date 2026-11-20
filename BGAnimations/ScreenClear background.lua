return Def.ActorFrame { 
	Def.Actor{
		OnCommand=function(self)
		if not FILEMAN:DoesFileExist("Save/ThemePrefs.ini") then
			Trace("ThemePrefs doesn't exist; creating file")
			ThemePrefs.ForceSave()
		end
		PreferenceTheme()
		PreferenceGame()
		ThemePrefs.Save()
		SelectMusicBGM()
		local coins = GAMESTATE:GetCoins()
			if coins >= 1 then
				GAMESTATE:InsertCoin(-coins)
			end
		end;
	};
	Def.Quad{
		InitCommand=function(s) s:diffuse(Color("White")):setsize(SCREEN_WIDTH,SCREEN_HEIGHT):Center() end,
	};
};