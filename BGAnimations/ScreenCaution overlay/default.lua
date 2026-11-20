return Def.ActorFrame{
	loadfile(THEME:GetPathB("","_doors"))()..{
		OnCommand=function(s) s:playcommand("Close") end,
	};
	Def.ActorFrame{
		OnCommand=function(s) s:sleep(0.45):queuecommand("Play") end,
		PlayCommand=function(s) 
			SOUND:PlayOnce(THEME:GetPathS("WORLD/Caution","in")) 
		end,
	};
	Def.Sprite{
		Texture="base",
		InitCommand=function(s) s:zoom(0):Center() end,
		OnCommand=function(s) s:sleep(0.3):linear(0.1):zoomx(-0.567):zoomy(0.567):linear(0.1):zoom(0.667) end,
		OffCommand=function(s) s:sleep(0.25):linear(0.1):zoomx(-0.667):zoomy(0) end,
	},
	Def.Sprite{
		Texture="caution",
		InitCommand=function(s) s:zoom(0.667):xy(_screen.cx,_screen.cy-60):diffusealpha(0) end,
		OnCommand=function(s) s:sleep(0.5):linear(0.2):diffusealpha(1) end,
		OffCommand=function(s) s:linear(0.2):diffusealpha(0) end,
	},
	Def.Sprite{
		Texture="text",
		InitCommand=function(s) s:zoom(0.667):xy(_screen.cx,_screen.cy+7):diffusealpha(0) 
			s:pause():setstate(GetCurrentLanguage())
		end,
		OnCommand=function(s) s:sleep(0.5):linear(0.2):diffusealpha(1) end,
		OffCommand=function(s) s:linear(0.2):diffusealpha(0) end,
	},
	-- a new game starts: the folder screen may be offered again to a new profile (ScreenSelectMusic overlay)
	Def.Actor{ OnCommand=function() setenv("DDRWORLD_FolderOffered", nil) end },
	-- A new profile (first session: no songs played yet) or a guest starts on ALL MUSIC with no filter, so the wheel opens
	-- on the first song of the whole list (whatever the previous game left chosen). Done here, before the wheel is built.
	Def.Actor{ OnCommand=function()
		if not (Filter and Filter.Active and Filter.Active()) then return end
		local newPlayer = false
		for _, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
			if not PROFILEMAN:IsPersistentProfile(pn) then
				newPlayer = true
			else
				local profile = PROFILEMAN:GetProfile(pn)
				if profile and profile:GetNumTotalSongsPlayed() == 0 then newPlayer = true end
			end
		end
		if newPlayer then
			Filter.SetFolder("ALL")
			Filter.ClearAll()
		end
	end },
	-- The filter's index of songs is built here, a little each frame, while the caution is on screen
	-- (Scripts/08 Filter.lua): the filter menu opens without a pause later. Whatever is left is built when it is needed.
	Def.ActorFrame{
		InitCommand=function(s)
			local ready = false
			local startAt = GetTimeSinceStart() + 0.6   -- the caution animation starts first
			s:SetUpdateFunction(function()
				if ready or not Filter or GetTimeSinceStart() < startAt then return end
				ready = Filter.Warm(0.012)
			end)
		end,
	},
}