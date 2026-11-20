-- ============================================================================
-- WHEEL CACHE: results that the music wheel and the select music panels ask for over and over
-- ============================================================================
-- Every move of the wheel (and every song or difficulty change) makes about 18 wheel items and a dozen panel
-- actors ask the engine the same things again: the best score of a chart, whether a texture file exists, the
-- path of a graphic... Each answer only changes when a score is saved or a file is added, so it is computed
-- once and reused. Nothing is drawn differently; the engine is just asked less.
--
-- The cache is emptied when the select music screen starts (BGAnimations/ScreenSelectMusic overlay/default.lua),
-- which is where scores can have changed (after playing a song), and when scripts are reloaded (Shift+F2).
-- ============================================================================

WheelCache = {}

-- ---------- frame counter ----------
-- Things that cannot change inside one frame (which section is open...) are computed once per frame: whoever asks
-- compares WheelCache.Frame with the frame of its last answer. Tick is called once per frame by
-- BGAnimations/ScreenSelectMusic overlay/LevelSort.lua.
WheelCache.Frame = 0
function WheelCache.Tick() WheelCache.Frame = WheelCache.Frame + 1 end

-- ---------- files and paths ----------
local exists = {}
function WheelCache.FileExists(path)
	local v = exists[path]
	if v == nil then
		v = FILEMAN:DoesFileExist(path) and true or false
		exists[path] = v
	end
	return v
end

local pathsG, pathsB = {}, {}

-- THEME:GetPathG(dir, name), remembered.
function WheelCache.PathG(dir, name)
	local key = dir .. "\n" .. name
	local p = pathsG[key]
	if p == nil then
		p = THEME:GetPathG(dir, name)
		pathsG[key] = p
	end
	return p
end

-- THEME:GetPathB(dir, name), remembered.
function WheelCache.PathB(dir, name)
	local key = dir .. "\n" .. name
	local p = pathsB[key]
	if p == nil then
		p = THEME:GetPathB(dir, name)
		pathsB[key] = p
	end
	return p
end

-- Image shown for a song in the wheel, worked out once per song:
--   path   the image file
--   kind   "jacket" (square: drawn stretched to the card), "banner" (wide: drawn whole, centered, at its own
--          proportions) or "other" (background or the fallback jacket, drawn like a jacket)
--   cache  the engine's image cache category to load it from
-- A song without a jacket uses its banner (small) before its background (large, other proportions).
local jackets = {}
function WheelCache.JacketInfo(song)
	local dir = song:GetSongDir()
	local info = jackets[dir]
	if not info then
		if song:HasJacket() then
			info = { path = song:GetJacketPath(), kind = "jacket", cache = "Jacket" }
		elseif song:HasBanner() then
			info = { path = song:GetBannerPath(), kind = "banner", cache = "Banner" }
		else
			info = { path = GetJacketPath(song), kind = "other", cache = "Jacket" }
		end
		jackets[dir] = info
	end
	return info
end

function WheelCache.JacketPath(song)
	return WheelCache.JacketInfo(song).path
end

-- ---------- the open section of the wheel ----------
-- The wheel is a grid of three songs per row. When the last row of the open section has one or two songs, the empty
-- cells are filled with a blank tile (Song NormalPart/default.lua) and everything that comes after the section moves
-- down by the rows that those cells take (RowShift), so the next section header does not land on top of them.
local USES_SECTIONS = ToEnumShortString(PREFSMAN:GetPreference("MusicWheelUsesSections")) == "Always"
-- With OnlyShowActiveSection the open pack is shown alone: its title (index 0) followed by its songs.
local ONLY_ACTIVE   -- read from the metrics the first time it is needed (scripts load before the theme is ready)
local SLOTS
local block, blockFrame, blockOpen

-- Open section of the wheel, worked out once per frame:
--   first, last   wheel indexes of its first and last song
--   pad           empty cells in its last row (0, 1 or 2)
--   total, sel    number of items of the wheel and index of the one under the cursor
-- nil when no section is open or the wheel has no sections.
function WheelCache.Block()
	-- the open section can change in the middle of a frame, so the name is checked every time
	local name = GAMESTATE:GetExpandedSectionName()
	if blockFrame == WheelCache.Frame and blockOpen == name then return block end
	blockFrame = WheelCache.Frame
	if blockOpen ~= name and WheelCache.ResetIndexDelta then WheelCache.ResetIndexDelta() end   -- the numbering can differ per mode
	blockOpen = name
	block = nil
	if not USES_SECTIONS then return nil end
	if ONLY_ACTIVE == nil then
		ONLY_ACTIVE = THEME:GetMetric("MusicWheel", "OnlyShowActiveSection") and true or false
		SLOTS = THEME:GetMetric("MusicWheel", "NumWheelItems")
	end

	if not name or name == "" then return nil end
	local screen = SCREENMAN:GetTopScreen()
	local wheel = screen and screen.GetChild and screen:GetChild("MusicWheel")
	if not wheel then return nil end

	local total = wheel:GetNumItems()
	-- A wheel with no items yet (the extra stage builds it in several steps and the items already ask for their
	-- position) must not be asked anything else: the engine stops with "Assertion data.size() != 0" in WheelBase.
	if not total or total < 1 then return nil end
	local first, headers
	if ONLY_ACTIVE then
		first, headers = 1, 1
	else
		local sections = wheel:GetCurrentSections()
		for i, section in ipairs(sections) do
			if section == name then first = i break end
		end
		headers = #sections
	end
	if not first then return nil end
	local songs = total - headers
	if songs < 1 then return nil end

	block = {
		first = first, last = first + songs - 1, pad = (3 - songs % 3) % 3,
		total = total, sel = wheel:GetCurrentIndex(), wheel = wheel,
	}
	-- for the log (Logs/log.txt): how the wheel is numbered, written when it changes
	local key = block.first .. "/" .. block.last .. "/" .. block.total .. "/" .. block.sel
	if key ~= WheelCache.LastBlockKey then
		WheelCache.LastBlockKey = key
		Trace("WheelBlock: first=" .. block.first .. " last=" .. block.last .. " total=" .. block.total
			.. " cursor=" .. block.sel .. " pad=" .. block.pad .. " onlyActive=" .. tostring(ONLY_ACTIVE))
	end
	return block
end

-- Wheel index of the first song of the open section, as the song items need it to place themselves in the grid
-- (0 when there is no open section).
function WheelCache.FirstSong()
	local b = WheelCache.Block()
	return b and b.first or 0
end

-- Which slot of the wheel (0 .. NumWheelItems-1) an item is drawn in, worked out once per frame. The slot gives the
-- distance from the cursor even when the wheel is short and shows the same item more than once.
local slots, slotsFrame
local function SlotOf(actor, wheel)
	if slotsFrame ~= WheelCache.Frame then
		slotsFrame = WheelCache.Frame
		slots = {}
		for slot = 0, SLOTS - 1 do
			local ok, item = pcall(wheel.GetWheelItem, wheel, slot)
			if ok and item then slots[item] = slot end
		end
	end
	-- the item is the actor itself or one of its parents (the part of an item is a child of the wheel item)
	for _ = 1, 4 do
		if not actor then return nil end
		if slots[actor] then return slots[actor] end
		actor = actor:GetParent()
	end
	return nil
end

-- Rows (of the grid) that the item with this wheel index has to move down: the items after the last song of the
-- open section make room for its blank cells, relative to the cursor so the selected item stays where it is.
-- `actor` is any actor of the item. Every copy of the section that the wheel shows adds its own blank cells.
function WheelCache.RowShift(index, actor)
	if WheelLayout and WheelLayout.Active() then return 0 end   -- the layout places every item itself
	local b = WheelCache.Block()
	if not b or b.pad == 0 or not index then return 0 end

	-- `offset` is how many items the item is from the cursor and `sel` the index of the item under the cursor.
	-- With the slot of the item, the cursor index comes from the item's own index (the engine's own cursor index
	-- is not numbered the same way in every mode), so everything is in the same numbering.
	local offset, sel
	local slot = actor and SlotOf(actor, b.wheel)
	if slot then
		offset = slot - math.floor(SLOTS / 2)
		sel = (index - offset) % b.total
	else
		sel = b.sel
		offset = (index - sel) % b.total
		if offset > b.total / 2 then offset = offset - b.total end
	end

	-- number of "last song" positions before x: last, last + total, last - total ...
	local function passed(x) return math.floor((x - b.last - 1) / b.total) end
	return b.pad * (passed(sel + offset) - passed(sel))
end

-- ---------- scores of a chart ----------
-- All the caches are declared here, before Reset, so that Reset empties these tables and not globals.
local charts = {}   -- [pn][song dir .. "|" .. difficulty] = info
local tops = {}     -- [pn][song dir|steps type|difficulty] = { score of place 1..5 }
local facts = {}    -- [song dir|steps type|difficulty] = { bpm = info or false, stops = bool, mines = bool }

-- Empties the cache (call when the screen starts).
function WheelCache.Reset()
	charts = {}
	facts = {}
	tops = {}
	WheelCache.Frame = WheelCache.Frame + 1
end

-- What the wheel and the difficulty list draw for the best score of a chart:
--   missing   true when the song has no chart with that steps type and difficulty
--   meter     the level of the chart
--   score     best score (0 when there is none)
--   mark      "MarvelousFullCombo", "PerfectFullCombo", "GreatFullCombo", "GoodFullCombo", "Gauge", "LifeBar"
--             or nil: the file name in Graphics/_shared/cleared/
--   gradeFile "Grade_AA", "Grade_Failed"...: the file name in Graphics/Grade/, or nil when there is no grade to show
local function Compute(pn, song, stepsType, difficulty)
	local info = { score = 0 }
	if not song:HasStepsTypeAndDifficulty(stepsType, difficulty) then
		info.missing = true
		return info
	end
	local steps = song:GetOneSteps(stepsType, difficulty)
	if not steps then
		info.missing = true
		return info
	end

	info.meter = steps:GetMeter()

	local scores = MachineOrProfile(pn):GetHighScoreList(song, steps):GetHighScores()
	local top = scores[1]
	if not top then return info end

	info.score = top:GetScore()
	local grade = top:GetGrade()
	if info.score > 1 then
		info.gradeFile = (grade == "Grade_Failed") and "Grade_Failed" or ("Grade_" .. ToEnumShortString(grade))
	end

	local misses = top:GetTapNoteScore("TapNoteScore_Miss")
		+ top:GetTapNoteScore("TapNoteScore_CheckpointMiss")
		+ top:GetTapNoteScore("TapNoteScore_HitMine")
		+ top:GetTapNoteScore("TapNoteScore_W5")
	local goods = top:GetTapNoteScore("TapNoteScore_W4")
	local greats = top:GetTapNoteScore("TapNoteScore_W3")
	local perfects = top:GetTapNoteScore("TapNoteScore_W2")
	local marvelous = top:GetTapNoteScore("TapNoteScore_W1")

	if misses == 0 and info.score > 0 and (marvelous + perfects) > 0 then
		if greats + perfects == 0 then
			info.mark = "MarvelousFullCombo"
		elseif greats == 0 then
			info.mark = "PerfectFullCombo"
		elseif misses + goods == 0 then
			info.mark = "GreatFullCombo"
		else
			info.mark = "GoodFullCombo"
		end
	elseif grade ~= "Grade_Failed" then
		info.mark = string.find(top:GetModifiers(), "Lives") and "Gauge" or "LifeBar"
	end
	return info
end

-- Best score information of a chart for a player.
function WheelCache.Chart(pn, song, stepsType, difficulty)
	local perPlayer = charts[pn]
	if not perPlayer then
		perPlayer = {}
		charts[pn] = perPlayer
	end
	local key = song:GetSongDir() .. "|" .. tostring(difficulty)
	local info = perPlayer[key]
	if not info then
		info = Compute(pn, song, stepsType, difficulty)
		perPlayer[key] = info
	end
	return info
end

-- Scores of the first five places of a chart (numbers; missing places are nil), for the target score panel.
function WheelCache.TopScores(pn, song, steps)
	local perPlayer = tops[pn]
	if not perPlayer then
		perPlayer = {}
		tops[pn] = perPlayer
	end
	local key = song:GetSongDir() .. "|" .. tostring(steps:GetStepsType()) .. "|" .. tostring(steps:GetDifficulty())
	local list = perPlayer[key]
	if not list then
		list = {}
		local scores = MachineOrProfile(pn):GetHighScoreList(song, steps):GetHighScores()
		for place = 1, 5 do
			if scores[place] then list[place] = scores[place]:GetScore() end
		end
		perPlayer[key] = list
	end
	return list
end

-- ---------- facts about a chart (info panel) ----------

-- BPM information, whether it has stops and whether it has mines. These only depend on the chart.
function WheelCache.ChartFacts(song, steps)
	-- The steps the game reports can still be the ones of the PREVIOUS song for a moment after the song changed (the
	-- song and the steps change in separate messages). They must not be stored under the new song, so the chart is
	-- always taken from the song itself: the one with the same type and difficulty. If the song has no such chart the
	-- answer is empty and nothing is stored.
	local stepsType, difficulty = steps:GetStepsType(), steps:GetDifficulty()
	local own
	if difficulty ~= "Difficulty_Edit" then
		own = song:GetOneSteps(stepsType, difficulty)
		if not own then
			return { bpm = false, stops = false, mines = false }
		end
		steps = own
	end
	local key = song:GetSongDir() .. "|" .. tostring(stepsType) .. "|" .. tostring(difficulty)
	local f = facts[key]
	if f then return f end

	f = { bpm = GetChartBPMInfo(song, steps) or false, stops = false, mines = false }
	local timing = steps:GetTimingData()
	if timing then
		local stops = timing:GetStops()
		f.stops = stops and #stops > 0 or false
	end
	for _, pn in ipairs({ PLAYER_1, PLAYER_2 }) do
		if GAMESTATE:IsHumanPlayer(pn) then
			local radar = steps:GetRadarValues(pn)
			local mines = radar and radar:GetValue("RadarCategory_Mines")
			if mines and mines > 0 then f.mines = true end
		end
	end
	-- Edit charts are not stored: several of them share the same key
	if own then facts[key] = f end
	return f
end

-- ---------- numbering of the wheel's cursor ----------
-- The index that wheel:GetCurrentIndex() gives and the Index that the Set messages carry are the same list but, in
-- some modes (OnlyShowActiveSection), differ by a constant. Every Set with the focus says what the cursor is in
-- Set numbering; the difference that is seen most often is the one used.
local deltaVotes = {}
local deltaBest   -- nil until a focused row has told
function WheelCache.NoteIndexDelta(index, cursor, total)
	local d = (index - cursor) % total
	if d > total / 2 then d = d - total end
	if math.abs(d) > 2 then return end   -- the cursor moved again before the message arrived
	deltaVotes[d] = (deltaVotes[d] or 0) + 1
	if deltaVotes[d] > (deltaBest and deltaVotes[deltaBest] or 0) then deltaBest = d end
end

function WheelCache.IndexDelta()
	return deltaBest
end

function WheelCache.ResetIndexDelta()
	deltaVotes = {}
	deltaBest = nil
end

-- ---------- sprites ----------
-- Sprite:Load / LoadBackground only when the path is not the one already loaded.
function WheelCache.LoadOnce(sprite, path)
	if sprite._loadedPath ~= path then
		sprite:Load(path)
		sprite._loadedPath = path
	end
end

function WheelCache.LoadBackgroundOnce(sprite, path)
	if sprite._loadedPath ~= path then
		sprite:LoadBackground(path)
		sprite._loadedPath = path
	end
end
