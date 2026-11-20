-- ============================================================================
-- FLARE CLEARS: the best FLARE earned on each chart
-- The engine does not store which FLARE a song was cleared with, so it is saved separately in the
-- player's profile folder (or the machine profile when nobody is signed in) as "FlareClears.txt".
-- One line per chart:  level <TAB> song dir | steps type | difficulty
-- Only the best level is kept (1..10), and only when the FLARE was not lost.
-- This file loads after "08 FlareGauge.lua" (alphabetical order) and extends its FlareGauge table.
-- ============================================================================

local SEP = string.char(9)   -- tab

local function ProfileDir(pn)
	local slot = "ProfileSlot_Machine"
	if PROFILEMAN:IsPersistentProfile(pn) then
		slot = (pn == PLAYER_1) and "ProfileSlot_Player1" or "ProfileSlot_Player2"
	end
	local d = PROFILEMAN:GetProfileDir(slot)
	if not d or d == "" then return nil end
	return d
end

local function ChartKey(song, steps)
	return song:GetSongDir() .. "|" .. tostring(steps:GetStepsType()) .. "|" .. tostring(steps:GetDifficulty())
end

local Cache = {}   -- [profile dir] = { [chart key] = level }

local function LoadClears(dir)
	if Cache[dir] then return Cache[dir] end
	local t = {}
	local path = dir .. "FlareClears.txt"
	if FILEMAN:DoesFileExist(path) then
		local f = RageFileUtil.CreateRageFile()
		if f:Open(path, 1) then
			local s = tostring(f:Read() or "")
			for line in s:gmatch("[^\r\n]+") do
				local sep = line:find(SEP, 1, true)
				local lv = sep and tonumber(line:sub(1, sep - 1))
				if lv then t[line:sub(sep + 1)] = lv end
			end
			f:Close()
		end
		f:destroy()
	end
	Cache[dir] = t
	return t
end

-- Best FLARE (1..10) the player has earned on that chart, or nil.
function FlareGauge.GetClear(pn, song, steps)
	local dir = ProfileDir(pn)
	if not (dir and song and steps) then return nil end
	return LoadClears(dir)[ChartKey(song, steps)]
end

-- FLARE earned in each stage played, for the final results (ScreenEvaluationSummary), which only has the stage stats and
-- the engine does not keep the FLARE in them. One entry per song played, in the order they were played; level is false
-- when the stage had no FLARE (or it was lost).
local stagesPlayed = {}   -- [pn] = { { key = chart key, level = 1..10 or false }, ... }

local function RecordStage(pn, song, steps, lv)
	if not (song and steps) then return end
	local list = stagesPlayed[pn]
	if not list then list = {}; stagesPlayed[pn] = list end
	list[#list + 1] = { key = ChartKey(song, steps), level = lv or false }
	if #list > 40 then table.remove(list, 1) end
end

-- FLARE earned in one of the stages of the set that is being summarised, or nil. "occurrence" is the position of this stage
-- among the stages of the summary that had the same chart (1 for the first time, 2 for the second...), and "total" how
-- many there were in the summary: the entries of an earlier set with the same chart are skipped by counting from the end.
function FlareGauge.StageClear(pn, song, steps, occurrence, total)
	if not (song and steps) then return nil end
	local key = ChartKey(song, steps)
	local found = {}
	for _, e in ipairs(stagesPlayed[pn] or {}) do
		if e.key == key then found[#found + 1] = e.level end
	end
	local lv = found[#found - (total or 1) + (occurrence or 1)]
	return lv or nil
end

-- Saves the FLARE earned in the current song. Called when the results screen loads.
function FlareGauge.SaveClear(pn)
	local lv = FlareGauge.AchievedLevel(pn)
	local song = GAMESTATE:GetCurrentSong()
	local steps = GAMESTATE:GetCurrentSteps(pn)
	RecordStage(pn, song, steps, lv)
	local dir = ProfileDir(pn)
	if not (lv and song and steps and dir) then return end
	local t = LoadClears(dir)
	local key = ChartKey(song, steps)
	if (t[key] or 0) >= lv then return end
	t[key] = lv
	local f = RageFileUtil.CreateRageFile()
	if f:Open(dir .. "FlareClears.txt", 2) then
		local out = {}
		for k, v in pairs(t) do out[#out + 1] = v .. SEP .. k end
		f:Write(table.concat(out, "\n") .. "\n")
		f:Close()
	end
	f:destroy()
end

-- Music wheel textures, relative to Graphics/MusicWheelItem Song NormalPart/ (for example "flare/flare_3").
function FlareGauge.WheelFile(name)
	return FlareGauge.ThemeFile("Graphics/MusicWheelItem Song NormalPart/" .. name .. ".png")
end

-- Difficulty list textures, relative to BGAnimations/ScreenSelectMusic overlay/Difficulty/.
function FlareGauge.DifficultyFile(name)
	return FlareGauge.ThemeFile("BGAnimations/ScreenSelectMusic overlay/Difficulty/" .. name .. ".png")
end
