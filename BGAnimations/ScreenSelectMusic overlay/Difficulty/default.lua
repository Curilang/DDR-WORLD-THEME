local pn = ...
local DiffList = Def.ActorFrame{};

-- This list is refreshed at every song or difficulty change, for every chart of the song. The answers that do not
-- change (the best score of a chart, the path of a texture) come from Scripts/08 WheelCache.lua, and a texture is
-- only loaded when it is not the one already shown. What is drawn is the same.
local PathB, PathG = WheelCache.PathB, WheelCache.PathG
local LoadOnce, LoadBackgroundOnce = WheelCache.LoadOnce, WheelCache.LoadBackgroundOnce

-- file prefix of the difficulty name textures (diff/beg_lab.png, diff/beg_w.png, diff/beg_c.png...)
local NAME_FILE = {
	Difficulty_Beginner = "beg", Difficulty_Easy = "bas", Difficulty_Medium = "dif",
	Difficulty_Hard = "exp", Difficulty_Challenge = "cha",
}

-- x of the level number
local METER_X = {
	Difficulty_Beginner = -28, Difficulty_Easy = -44, Difficulty_Medium = -28,
	Difficulty_Hard = -44, Difficulty_Challenge = -28, Difficulty_Edit = -28,
}

local function CurrentDifficulty()
	local current = GAMESTATE:GetCurrentSteps(pn)
	return current and current:GetDifficulty()
end

local function DrawDiffListItem(diff)
	-- path of one of the textures of the difficulty name; the Edit difficulty only has the "lab" one
	local function NameTexture(suffix)
		local prefix = NAME_FILE[diff]
		if not prefix and suffix == "lab" and diff == "Difficulty_Edit" then prefix = "edit" end
		if prefix then return PathB("ScreenSelectMusic", "overlay/Difficulty/diff/" .. prefix .. "_" .. suffix) end
		return nil
	end

	local DifficultyListItem = Def.ActorFrame{
		InitCommand=function(s) s:x(-3) end,
		SetCommand=function(self)
			local st = GAMESTATE:GetCurrentStyle():GetStepsType()
			local song = GAMESTATE:GetCurrentSong()
			if not song then
				self:visible(false)
				return
			end
			--local yspacing = hasEdit and 31 or 39
			local yspacing = 13
			if song:HasStepsTypeAndDifficulty(st, diff) then
				self:y((Difficulty:Reverse()[diff] * yspacing)-21.5)
				self:visible(true)
			else
				self:visible(false)
			end
		end,
		Def.ActorFrame{
			Name="DiffLabel",
			InitCommand=function(s) s:zoom(0.667):x(4) end,
			Def.Sprite{
				InitCommand=function(s) s:queuecommand("Set") end,
				SetCommand=function(s)
					if diff == CurrentDifficulty() then
						local texture = NameTexture("lab")
						if texture then LoadOnce(s, texture) end
						s:visible(true)
					else
						s:visible(false)
					end
				end,
				CurrentStepsP1ChangedMessageCommand=function(s) s:playcommand("Set") end,
				CurrentStepsP2ChangedMessageCommand=function(s) s:playcommand("Set") end,
			},
		};
		Def.ActorFrame{
			Name="DiffNameWhite",
			InitCommand=function(s) s:zoom(0.667):x(-74) end,
			Def.Sprite{
				InitCommand=function(s) s:queuecommand("Set") end,
				SetCommand=function(s)
					if diff ~= CurrentDifficulty() then
						local texture = NameTexture("w")
						if texture then LoadOnce(s, texture) end
						s:visible(true)
					else
						s:visible(false)
					end
				end,
				CurrentStepsP1ChangedMessageCommand=function(s) s:playcommand("Set") end,
				CurrentStepsP2ChangedMessageCommand=function(s) s:playcommand("Set") end,
			};
		};
		Def.ActorFrame{
			Name="DiffNameColor",
			InitCommand=function(s) s:zoom(0.667):x(-74) end,
			Def.Sprite{
				InitCommand=function(s) s:queuecommand("Set") end,
				SetCommand=function(s)
					if diff == CurrentDifficulty() then
						local texture = NameTexture("c")
						if texture then LoadOnce(s, texture) end
						s:visible(true)
					else
						s:visible(false)
					end
				end,
				CurrentStepsP1ChangedMessageCommand=function(s) s:playcommand("Set") end,
				CurrentStepsP2ChangedMessageCommand=function(s) s:playcommand("Set") end,
			};
		};
		Def.BitmapText{
			Font="OFF_Difficulty Numbers",
			Name="Meter";
			InitCommand=function(s) s:y(2.5):zoom(0.23) end,
			SetCommand=function(s)
				local song = GAMESTATE:GetCurrentSong()
				if song then
					local info = WheelCache.Chart(pn, song, GAMESTATE:GetCurrentStyle():GetStepsType(), diff)
					if not info.missing then s:settext(info.meter) end
				end
				s:x(METER_X[diff])
			end;
		};
		Def.BitmapText{
			Font="on_Difficulty Numbers",
			Name="Meter";
			InitCommand=function(s) s:y(2.5):shadowlength(1):zoom(0.23):visible(false) end,
			SetCommand=function(s)
				local song = GAMESTATE:GetCurrentSong()
				if song then
					local info = WheelCache.Chart(pn, song, GAMESTATE:GetCurrentStyle():GetStepsType(), diff)
					if not info.missing then s:settext(info.meter) end
				end
				s:visible(diff == CurrentDifficulty())
				s:x(METER_X[diff])
			end;
		};
		-- best score
		Def.BitmapText{
			Font="Score Numbers",
			InitCommand=function(s) s:xy(40,15):zoom(0.667):halign(1):queuecommand("Set") end,
			SetCommand=function(self)
				self:settext("")
				self:diffuse((diff == CurrentDifficulty()) and Color.Black or Color.White)
				local song = GAMESTATE:GetCurrentSong()
				if song then
					local info = WheelCache.Chart(pn, song, GAMESTATE:GetCurrentStyle():GetStepsType(), diff)
					if not info.missing and info.score ~= 0 then
						self:settext(commify(info.score))
					end
				end
			end;
		};
		-- grade of the best score
		Def.Sprite{
			InitCommand=function(s) s:queuecommand("Set"):x(62):zoom(0.09) end,
			SetCommand=function(s)
				local song = GAMESTATE:GetCurrentSong()
				if not song then
					s:visible(false)
					return
				end

				local info = WheelCache.Chart(pn, song, GAMESTATE:GetCurrentStyle():GetStepsType(), diff)
				if info.missing or not info.gradeFile then
					s:visible(false)
					return
				end

				LoadBackgroundOnce(s, PathG("", "Grade/" .. info.gradeFile))
				s:visible(true)
			end,
		};

		-- clear mark: full combo, cleared with the life bar or with the battery
		Def.Sprite{
			InitCommand=function(s) s:queuecommand("Set"):xy(91,0):zoom(0.667) end,
			SetCommand=function(s)
				local song = GAMESTATE:GetCurrentSong()
				if not song then
					s:visible(false)
					return
				end

				local info = WheelCache.Chart(pn, song, GAMESTATE:GetCurrentStyle():GetStepsType(), diff)
				if info.missing or not info.mark then
					s:visible(false)
					return
				end

				LoadOnce(s, PathG("", "_shared/cleared/" .. info.mark))
				s:visible(true)
			end,
		};

		-- FLARE earned on this chart, next to the grade and the FC/GFC/PFC/MFC mark. Textures: the same ones as the music wheel's
		-- (Graphics/MusicWheelItem Song NormalPart/flare/flare_N.png): there is only one copy of them
		Def.Sprite{
			InitCommand=function(s) s:queuecommand("Set"):xy(111,0):zoom(0.52) end,
			SetCommand=function(s)
				s:visible(false)
				local song = GAMESTATE:GetCurrentSong()
				local st = GAMESTATE:GetCurrentStyle():GetStepsType()
				if not song or not song:HasStepsTypeAndDifficulty(st,diff) then return end
				local steps = song:GetOneSteps(st,diff)
				local level = steps and FlareGauge.GetClear(pn, song, steps)
				local f = level and FlareGauge.WheelFile("flare/flare_"..level)
				if f then
					LoadOnce(s, f)
					s:visible(true)
				end
			end,
		};
	};
	return DifficultyListItem
end

local difficulties = {"Difficulty_Beginner", "Difficulty_Easy", "Difficulty_Medium", "Difficulty_Hard", "Difficulty_Challenge", "Difficulty_Edit"}

for diff in ivalues(difficulties) do
  DiffList[#DiffList+1] = DrawDiffListItem(diff)
end

-- Estado para detectar un cambio real de dificultad (misma canción, distinta dificultad)
local lastDiff, lastSong = nil, nil
local lastInput = -1   -- momento de la última pulsación Arriba/Abajo de este jugador
local lastSongChange = -1   -- momento del último cambio de canción

-- Al construir la pantalla de la rueda, TwoPartDiff no puede estar abierto:
-- limpia la bandera por si se quedó activa tras salir con Back/ESC
setenv("DDRWORLD_TwoPartOpen", nil)

local function PlayDiffSound()
	-- TwoPartDiff ya tiene su propio sonido: no duplicarlo
	if getenv("DDRWORLD_TwoPartOpen") then return end
	SOUND:PlayOnce(THEME:GetPathS("","WORLD/Difficulty Change"))
end

-- Solo registra si el jugador presionó Arriba/Abajo (los controles de dificultad)
local function InputWatcher(event)
	if event.PlayerNumber == pn and event.type ~= "InputEventType_Release" then
		local b = event.button
		if b == "MenuUp" or b == "MenuDown" or b == "Up" or b == "Down" then
			lastInput = GetTimeSinceStart()
		end
	end
	return false
end

return Def.ActorFrame{
	OnCommand=function(s)
		lastDiff = CurrentDifficulty()
		lastSong = GAMESTATE:GetCurrentSong()
		local screen = SCREENMAN:GetTopScreen()
		if screen then screen:AddInputCallback(InputWatcher) end
		s:playcommand("Set")
	end,
	OffCommand=function(s)
		local screen = SCREENMAN:GetTopScreen()
		if screen then screen:RemoveInputCallback(InputWatcher) end
	end,
	CurrentSongChangedMessageCommand=function(s)
		-- al cambiar de canción solo actualizamos el estado, sin sonido
		lastSongChange = GetTimeSinceStart()
		lastSong = GAMESTATE:GetCurrentSong()
		lastDiff = CurrentDifficulty()
		s:finishtweening():queuecommand("Set")
	end,
	["CurrentSteps"..ToEnumShortString(pn).."ChangedMessageCommand"]=function(s)
		local diff = CurrentDifficulty()
		local song = GAMESTATE:GetCurrentSong()
		local now = GetTimeSinceStart()
		local byPlayer = (now - lastInput) < 0.3
		local songJustChanged = (now - lastSongChange) < 0.3
		if byPlayer and not songJustChanged and lastDiff and diff and diff ~= lastDiff and song == lastSong then
			PlayDiffSound()
		end
		lastDiff, lastSong = diff, song
		s:finishtweening():queuecommand("Set")
	end,
	Def.ActorFrame{
		InitCommand=function(s) s:xy(pn==PLAYER_1 and 127 or _screen.r-127,276) end,
		Def.Sprite{
			Texture="base",
			InitCommand=function(s) s:zoom(0.667) end,
		};
		DiffList;
	};
}
