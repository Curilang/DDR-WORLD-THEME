-- ============================================================================
-- LEVEL SORT (as in the arcade)
-- ============================================================================
-- The engine's level sorts (SortOrder_<Difficulty>Meter) only look at ONE difficulty: the one the player had
-- selected. The arcade sorts by level whatever the difficulty is: a song is listed in LEVEL 5, LEVEL 9 and
-- LEVEL 12 if it has charts of those levels. If a song has the same level in two difficulties (Expert 18 and
-- Challenge 18) it is listed twice in that level, once per chart.
--
-- Packs that use another rating system (ITG) are kept apart: a pack with an "itg.ini" file in its folder is
-- listed in "LEVEL ITG N" sections, which come after all the normal LEVEL sections, and its songs are not in
-- the normal ones.
--
-- The engine cannot do that by itself, so the sections are built here and handed to it as the "Preferred" song
-- list (ITGmania lets a song be in several sections). The engine rebuilds that list every time it needs it, so
-- a list with every song of every level (thousands of entries) makes the wheel lag. To keep it small, only the
-- sections the player is on are filled: the OPEN section and the one the cursor is on. Every other section has
-- a single song, just so its header shows up. Poll (called every frame by
-- BGAnimations/ScreenSelectMusic overlay/LevelSort.lua) refills the list when the cursor moves.
--
-- Which chart a wheel row stands for: the engine gives every row its position in the wheel's data list (the
-- "Index" of the Set message; the row with the focus has the selected index). The rows tell this script their
-- index (NoteRow / NoteHeader) and then ask ItemChart / WheelDifficulty. Poll selects the chart of the row
-- under the cursor.
-- The real "Preferred" entry of the sort menu calls RestorePreferred to bring the theme's own list back.
-- ============================================================================

LevelSort = {
	Loaded = false,   -- true while the engine's Preferred list is the level list
}

-- The list is written inside the theme (Other/SongManager <name>.txt, like the theme's own "PreferredSongs") and given to
-- the engine by NAME. Older engine versions only accept preferred lists that way: they ignore the "absolute path"
-- argument and fail with "Theme element Other/SongManager /Save/... could not be found".
local LIST_NAME = "DDRWORLD_LevelSort"
local function ListPath()
	local dir = THEME:GetCurrentThemeDirectory()
	if string.sub(dir, 1, 1) ~= "/" then dir = "/" .. dir end
	if string.sub(dir, -1) ~= "/" then dir = dir .. "/" end
	return dir .. "Other/SongManager " .. LIST_NAME .. ".txt"
end
local ITG_FILE = "itg.ini"   -- a pack with this file in its folder is rated with the ITG system

-- { sections = { {name, level, itg, number, entries = { {song, dir, key, difficulty}... }}... in wheel order },
--   byName = {[name] = section} }
local data
local filledKey = ""     -- which sections are filled in the file right now
local focusKey           -- the row under the cursor the last time its chart was selected
local pickTries = 0      -- frames spent trying to select the chart of the current row
local openHeader         -- { name, index }: wheel index of the header of the open section, seen on the wheel
local selectedIndex      -- wheel index of the row with the focus, seen on the wheel
local calibration        -- { name, first }: wheel index of the first song row of the open section, worked out
                         -- from the rows of songs that have a single entry (their position is known)

-- Section names are zero padded to 3 digits ("LEVEL 005") so that sorting by name is also sorting by number,
-- even for the odd charts with levels like 100 or 182. "LEVEL ITG ..." sorts after every "LEVEL <digits>".
local function SectionName(level, itg)
	return string.format(itg and "LEVEL ITG %03d" or "LEVEL %03d", level)
end

-- level (number) and true if it is an ITG section; nil if the name is not a level section.
function LevelSort.ParseSection(name)
	local level = string.match(name or "", "^LEVEL (%d+)$")
	if level then return tonumber(level), false end
	level = string.match(name or "", "^LEVEL ITG (%d+)$")
	if level then return tonumber(level), true end
	return nil
end

-- "LEVEL 005" -> "LEVEL 5", "LEVEL ITG 005" -> "LEVEL ITG 5" for the wheel; any other name is returned as it is.
function LevelSort.DisplayName(name)
	local level, itg = LevelSort.ParseSection(name)
	if level then return (itg and "LEVEL ITG " or "LEVEL ") .. level end
	return name
end

-- "Group/Song folder", the way a preferred list names a song.
local function SongKey(song)
	local dir = string.gsub(song:GetSongDir(), "/$", "")
	local folder = string.match(dir, "([^/]+)$")
	if not folder then return nil end
	return song:GetGroupName() .. "/" .. folder
end

local function TitleKey(song)
	return string.lower(song:GetTranslitMainTitle() .. " " .. song:GetTranslitSubTitle())
end

local function CurrentStepsType()
	local style = GAMESTATE:GetCurrentStyle()
	return style and style:GetStepsType() or "StepsType_Dance_Single"
end

local DIFFICULTY_ORDER = {
	Difficulty_Beginner = 1, Difficulty_Easy = 2, Difficulty_Medium = 3, Difficulty_Hard = 4, Difficulty_Challenge = 5,
}

-- Every chart of the current steps type except Edit, grouped by level; ITG packs on their own. Each chart is
-- one entry, so a song with the same level in two difficulties has two.
local function Collect()
	local stepsType = CurrentStepsType()
	local packIsItg = {}
	local function IsItgPack(song)
		local packDir = string.match(song:GetSongDir(), "^(.*/)[^/]+/$")
		if not packDir then return false end
		if packIsItg[packDir] == nil then
			packIsItg[packDir] = FILEMAN:DoesFileExist(packDir .. ITG_FILE) and true or false
		end
		return packIsItg[packDir]
	end

	local entries = { [false] = {}, [true] = {} }   -- [itg][level] = {entries}
	for _, song in ipairs(SONGMAN:GetAllSongs()) do
		local itg = IsItgPack(song)
		local key = SongKey(song)
		if key then
			for _, steps in ipairs(song:GetStepsByStepsType(stepsType)) do
				local level = steps:GetMeter()
				local difficulty = steps:GetDifficulty()
				if difficulty ~= "Difficulty_Edit" and level >= 1 and (not Filter or Filter.PassChart(song, steps)) then
					entries[itg][level] = entries[itg][level] or {}
					table.insert(entries[itg][level], {
						song = song, dir = song:GetSongDir(), key = key, difficulty = difficulty,
						title = TitleKey(song),
					})
				end
			end
		end
	end

	local result = { sections = {}, byName = {} }
	for _, itg in ipairs({ false, true }) do   -- the normal levels first, then the ITG ones
		local levels = {}
		for level in pairs(entries[itg]) do levels[#levels + 1] = level end
		table.sort(levels)
		for _, level in ipairs(levels) do
			local list = entries[itg][level]
			table.sort(list, function(a, b)
				if a.title ~= b.title then return a.title < b.title end
				return (DIFFICULTY_ORDER[a.difficulty] or 0) < (DIFFICULTY_ORDER[b.difficulty] or 0)
			end)
			local section = { name = SectionName(level, itg), level = level, itg = itg, entries = list, single = {} }
			local count = {}
			for _, entry in ipairs(list) do count[entry.dir] = (count[entry.dir] or 0) + 1 end
			for position, entry in ipairs(list) do
				if count[entry.dir] == 1 then section.single[entry.dir] = position end
			end
			result.sections[#result.sections + 1] = section
			section.number = #result.sections   -- position among the headers
			result.byName[section.name] = section
		end
	end
	return result
end

-- Writes the list (the sections in `filled` with all their entries, the rest with one) and gives it to the engine.
-- `key` says which sections are filled, to know later when the file has to change.
local function WriteList(filled, key)
	local lines = {}
	for _, section in ipairs(data.sections) do
		lines[#lines + 1] = "---" .. section.name
		if filled == true or filled[section.name] then
			for _, entry in ipairs(section.entries) do lines[#lines + 1] = entry.key end
		else
			lines[#lines + 1] = section.entries[1].key
		end
		lines[#lines + 1] = ""
	end

	local file = RageFileUtil.CreateRageFile()
	if not file:Open(ListPath(), 2) then
		file:destroy()
		return false
	end
	file:Write(table.concat(lines, "\n"))
	file:Close()
	file:destroy()
	Trace("LevelSort: list written, filled sections = '" .. key .. "', open = '" .. tostring(GAMESTATE:GetExpandedSectionName()) .. "'")
	if FILEMAN.FlushDirCache then FILEMAN:FlushDirCache() end   -- StepMania 5.1 builds do not have it: the theme ships the file already (Other/)
	SONGMAN:SetPreferredSongs(LIST_NAME)
	filledKey = key
	return true
end

-- Builds the level sections and switches the music wheel to them. Returns false if it could not (the caller
-- then falls back to the engine's sort).
function LevelSort.Apply(wheel)
	data = Collect()
	if #data.sections == 0 then return false end
	focusKey, openHeader, selectedIndex, calibration = nil, nil, nil, nil

	-- start with the section of the chart the player has, so the wheel comes up on it
	-- The list is written ONCE with every section complete. Filling only the section under the cursor meant writing
	-- the file (and the engine rebuilding the whole wheel) each time the cursor passed over another level.
	if not WriteList(true, "all") then return false end
	LevelSort.Loaded = true
	wheel:ChangeSort("SortOrder_Preferred")
	return true
end

-- The filter (Scripts/08 Filter.lua): ONE section with the entries it gives, already in order. Each entry is
-- { song, difficulty } and difficulty can be nil (the filter has no chart category: the row is just the song). The
-- rows work like the ones of a LEVEL section (a song with two matching charts has two rows). Returns false if there
-- is nothing to show.
function LevelSort.ApplyFlat(wheel, entries, name)
	local list = {}
	for _, e in ipairs(entries or {}) do
		local key = SongKey(e.song)
		if key then
			list[#list + 1] = { song = e.song, dir = e.song:GetSongDir(), key = key, difficulty = e.difficulty,
				title = TitleKey(e.song) }
		end
	end
	if #list == 0 then return false end

	local section = { name = name, level = nil, itg = false, entries = list, single = {}, number = 1 }
	local count = {}
	for _, entry in ipairs(list) do count[entry.dir] = (count[entry.dir] or 0) + 1 end
	for position, entry in ipairs(list) do
		if count[entry.dir] == 1 then section.single[entry.dir] = position end
	end
	data = { sections = { section }, byName = { [name] = section } }
	focusKey, openHeader, selectedIndex, calibration = nil, nil, nil, nil

	if not WriteList(true, "all") then return false end
	LevelSort.Loaded = true
	wheel:ChangeSort("SortOrder_Preferred")
	return true
end

-- Brings back the theme's own Preferred list ("Other/SongManager PreferredSongs.txt").
function LevelSort.RestorePreferred()
	if not LevelSort.Loaded then return end
	LevelSort.Loaded = false
	-- the theme's own order (Scripts/08 SongOrder.lua), or the plain list if that is not available
	if SongOrder and SongOrder.Restore then SongOrder.Restore() else SONGMAN:SetPreferredSongs("PreferredSongs") end
	data, openHeader, selectedIndex, calibration = nil, nil, nil, nil
end

-- The open level section, shared by everything that asks during the same frame (the wheel rows ask many times).
local ctx, ctxTime, ctxOpen
local function Context()
	local now = WheelCache and WheelCache.Frame or GetTimeSinceStart()
	-- The open section can change in the middle of a frame (the player opens a level and the wheel redraws its rows
	-- right away): an answer from before that must not be reused, so the name is checked every time.
	local name = GAMESTATE:GetExpandedSectionName()
	if ctxTime ~= now or ctxOpen ~= name then
		ctxTime = now
		ctxOpen = name
		ctx = nil
		if LevelSort.Loaded and data and GAMESTATE:GetSortOrder() == "SortOrder_Preferred" then
			local section = data.byName[name]
			if section then ctx = { name = name, section = section } end
		end
	end
	return ctx
end

-- The song of a row of the open section, by the index the wheel items carry (0 is the title, the songs are 1..n). nil when
-- the list is not in use or the index is outside of it.
function LevelSort.EntrySong(index)
	local c = Context()
	local entry = c and c.section.entries[index]
	return entry and entry.song or nil
end

-- The level of the open section, normal or ITG (nil when the level sort is not active or no section is open).
function LevelSort.CurrentLevel()
	local c = Context()
	return c and c.section.level or nil
end

-- A wheel row tells its index and focus (call it from the Set command of the row).
function LevelSort.NoteRow(param)
	if param.HasFocus and param.Index then selectedIndex = param.Index end

	-- A song with a single entry in the open section sits at a known position, so its row tells where the songs of
	-- the section start in the wheel's list. Songs with two entries (same level in two difficulties) rely on that.
	local c = Context()
	local position = c and param.Song and param.Index and c.section.single[param.Song:GetSongDir()]
	if position then
		local first = param.Index - position + 1
		if not calibration or calibration.name ~= c.name or calibration.first ~= first then
			calibration = { name = c.name, first = first }
			-- rows drawn before this one used a worse guess: draw them again (they do not call NoteRow, so no loop)
			MESSAGEMAN:Broadcast("LevelSortCalibrated")
		end
	end
end

-- A section header tells its index (call it from the Set command of the header). The songs of the open section
-- come right after its header.
function LevelSort.NoteHeader(param)
	if param.Index and param.Text and param.Text == GAMESTATE:GetExpandedSectionName() then
		openHeader = { name = param.Text, index = param.Index }
	end
end

-- The entry of the open section that sits at this wheel index, if it is for this song.
local function EntryAtIndex(c, index, song)
	local first = c.section.number   -- last resort: one header per section before the songs
	if openHeader and openHeader.name == c.name then first = openHeader.index + 1 end
	if calibration and calibration.name == c.name then first = calibration.first end
	local entry = c.section.entries[index - first + 1]
	if entry and entry.dir == song:GetSongDir() then return entry end
	return nil
end

-- The chart of a song with this level (the one with the preferred difficulty if it has several), or nil.
function LevelSort.ChartForLevel(song, stepsType, level, preferred)
	local found
	for _, steps in ipairs(song:GetStepsByStepsType(stepsType)) do
		if steps:GetDifficulty() ~= "Difficulty_Edit" and steps:GetMeter() == level then
			if not found or steps:GetDifficulty() == preferred then found = steps end
		end
	end
	return found
end

-- The chart that a wheel row stands for in the open level section: the one of its entry (a song with the same
-- level in two difficulties has two rows). `index` is the Index of the row's Set message.
-- Returns nil when the level sort is not active.
function LevelSort.ItemChart(song, index)
	local c = Context()
	if not c or not song then return nil end
	local stepsType = CurrentStepsType()
	local entry = index and EntryAtIndex(c, index, song)
	if entry then
		if not entry.difficulty then return nil end   -- a plain song row: the chart is the player's one
		return song:GetOneSteps(stepsType, entry.difficulty)
	end
	return LevelSort.ChartForLevel(song, stepsType, c.section.level, nil)
end

-- The difficulty a wheel item must read its score, grade and clear/FLARE marks from: in the LEVEL sort it is the
-- chart its row stands for (the one shown on the item), otherwise the player's current chart.
function LevelSort.WheelDifficulty(song, pn, index)
	local chart = LevelSort.ItemChart(song, index)
	if chart then return chart:GetDifficulty() end
	local current = GAMESTATE:GetCurrentSteps(pn)
	return current and current:GetDifficulty()
end

-- Selects, for every player, the chart of the row under the cursor (the arcade does this too: you pick a song
-- from LEVEL 12 and it comes up on its 12). Returns false if the engine has not moved to that song yet.
local function PickChart(c, index)
	local song = GAMESTATE:GetCurrentSong()
	local entry = song and EntryAtIndex(c, index, song)
	if not entry then return false end

	if not entry.difficulty then return true end   -- a plain song row: the player's chart stays
	local chart = song:GetOneSteps(CurrentStepsType(), entry.difficulty)
	if not chart then return true end
	for _, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		local current = GAMESTATE:GetCurrentSteps(pn)
		if not current or current:GetDifficulty() ~= entry.difficulty then
			GAMESTATE:SetCurrentSteps(pn, chart)
			GAMESTATE:SetPreferredDifficulty(pn, entry.difficulty)
		end
	end
	return true
end

-- Called every frame while the music wheel is shown: keeps the open section and the one under the cursor filled
-- (the engine only reads the list when it opens a section, so changing the file while the cursor moves does not
-- disturb the wheel that is on screen) and selects the chart of the row under the cursor.
local lastOpen
function LevelSort.Poll(wheel)
	if not LevelSort.Loaded or not data or GAMESTATE:GetSortOrder() ~= "SortOrder_Preferred" then return end

	local open = GAMESTATE:GetExpandedSectionName()
	-- A level was opened or closed: the rows were drawn while the wheel was changing, so draw them again
	if open ~= lastOpen then
		lastOpen = open
		MESSAGEMAN:Broadcast("LevelSortCalibrated")
	end
	if not data.byName[open] then open = nil end
	local onSection = ToEnumShortString(wheel:GetSelectedType()) == "Section"
	local focus
	if onSection then
		focus = wheel:GetSelectedSection()
		if not data.byName[focus] then focus = nil end
	end

	-- Which sections are filled, whatever their role: when the open section is closed it becomes the one under the
	-- cursor, with the same songs, so the file must not be written again (it would make the engine rebuild the
	-- wheel a second time: lag and the section sound twice).
	local key = open or focus or ""
	if open and focus and open ~= focus then
		key = (open < focus) and (open .. "|" .. focus) or (focus .. "|" .. open)
	end
	if filledKey ~= "all" and key ~= "" and key ~= filledKey then
		local filled = {}
		if open then filled[open] = true end
		if focus then filled[focus] = true end
		WriteList(filled, key)
	end

	-- the chart of the row under the cursor (retried for a moment until the engine has moved to that song)
	local c = Context()
	if onSection or not c then
		focusKey, pickTries = nil, 0
		return
	end
	local index = selectedIndex or wheel:GetCurrentIndex()
	local rowKey = c.name .. "/" .. index
	if rowKey ~= focusKey then
		if PickChart(c, index) then
			focusKey, pickTries = rowKey, 0
		else
			pickTries = pickTries + 1
			if pickTries > 30 then focusKey, pickTries = rowKey, 0 end   -- give up on this row
		end
	end
end
