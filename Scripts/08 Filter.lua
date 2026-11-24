-- ============================================================================
-- FILTER (like DDR WORLD's "Filter" in the sort menu)
-- ============================================================================
-- The player picks values in several categories (LEVEL, DIFFICULTY, VERSION...) and the music wheel only shows the
-- songs that fit. Inside a category the values are OR (level 11 or 12); between categories they are AND.
--
-- Two kinds of categories:
--   song categories   VERSION, MUSIC TITLE, BPM, GENRE, EVENT: they look at the song.
--   chart categories  LEVEL, DIFFICULTY, CLEAR RANK, CLEAR TYPE, FLARE RANK, FLARE SKILL TARGET: they look at ONE chart,
--                     and all of them must be true for the SAME chart (level 11 + EXPERT = a chart that is both).
-- A song is listed when it fits the song categories and has at least one chart that fits the chart categories.
--
-- How it reaches the wheel: the lists the theme already writes for its sorts (Scripts/08 SongOrder.lua and
-- Scripts/08 LevelSort.lua) skip the songs / charts that do not pass (Filter.Pass / Filter.PassChart), and their
-- cache keys include Filter.Signature(), so a new filter rebuilds them. Filter.Reapply(wheel) builds the list again
-- for the sort that is on screen. The sorts that the engine builds by itself (BPM, TOP GRADES, POPULARITY, LENGTH)
-- cannot be filtered: applying a filter while one of them is on moves the wheel to the series list.
--
-- EVENT has no data in a simfile: the player defines events in Other/FilterEvents.txt (see that file).
-- FLARE SKILL TARGET needs the flare skill points, which the game does not have yet; Filter.SkillBase / SkillMult
-- are an approximation and can be edited (see the comment next to them).
-- ============================================================================

Filter = {
	-- true: the theme's main sort is ONE big list with every song (of the packs without itg.ini), like the arcade;
	-- the filter narrows it. false: the GROUP list is the main one and the filter list only shows with a filter on.
	FlatByDefault = true,
	Mode = "Simple",   -- "Simple": choosing a value closes the menu (one value per category); "Normal": several values   -- "Normal": several values per category; "Simple": one value per category
}

local Selected = {}     -- [category id] = { [value id] = true }
local folder = nil      -- id of the folder chosen in the folder screen (nil = ALL MUSIC), see Filter.Folders
local signature = ""
local stamp = 0         -- changes when scores may have changed (a song was played)

-- ---------------------------------------------------------------------------
-- Values of each category
-- ---------------------------------------------------------------------------

local VERSIONS = {
	{ id = "GOLD", label = "GROUP GOLD", members = { "WORLD", "A3", "A20" } },
	{ id = "WHITE", label = "GROUP WHITE", members = { "A", "2013" } },
	{ id = "CLASSIC", label = "GROUP CLASSIC", members = { "X", "SN", "MAX", "1ST" } },
	{ id = "WORLD", label = "WORLD" },
	{ id = "A3", label = "A3" },
	{ id = "A20", label = "A20 - A20 PLUS" },
	{ id = "A", label = "A" },
	{ id = "2013", label = "2013 - 2014" },
	{ id = "X", label = "X - X3 VS 2ndMIX" },
	{ id = "SN", label = "SuperNOVA - SuperNOVA2" },
	{ id = "MAX", label = "MAX - EXTREME" },
	{ id = "1ST", label = "1st - 5thMIX" },
	{ id = "OTHER", label = "OTHER" },
	{ id = "ITG", label = "ITG PACKS" },   -- only listed when a pack has an itg.ini file
}

-- song folder (group) name, without the "NN - " prefix and in lower case -> version id. Anything else is OTHER.
local VERSION_OF = {
	["ddr world"] = "WORLD", ["ddr a3"] = "A3",
	["ddr a20"] = "A20", ["ddr a20 plus"] = "A20",
	["ddr a"] = "A",
	["ddr 2013"] = "2013", ["ddr 2014"] = "2013",
	["ddr x"] = "X", ["ddr x2"] = "X", ["ddr x3 vs 2ndmix"] = "X",
	["ddr supernova"] = "SN", ["ddr supernova2"] = "SN",
	["ddr max"] = "MAX", ["ddr max2"] = "MAX", ["ddr extreme"] = "MAX",
	["ddr 1st"] = "1ST", ["ddr 2ndmix"] = "1ST", ["ddr 3rdmix"] = "1ST", ["ddr 4thmix"] = "1ST", ["ddr 5thmix"] = "1ST",
}

-- version id -> flare skill group
local SKILL_GROUP = {}
for _, v in ipairs(VERSIONS) do
	if v.members then
		for _, m in ipairs(v.members) do SKILL_GROUP[m] = v.id end
	end
end

-- UTF-8 helpers: the code points of a text (the kana labels are written as code points, so the file does not depend on its
-- encoding) and the first character of a title
local function Utf8(...)
	local out = {}
	for _, cp in ipairs({ ... }) do
		if cp < 0x80 then
			out[#out + 1] = string.char(cp)
		elseif cp < 0x800 then
			out[#out + 1] = string.char(0xC0 + math.floor(cp / 64), 0x80 + cp % 64)
		else
			out[#out + 1] = string.char(0xE0 + math.floor(cp / 4096), 0x80 + math.floor(cp / 64) % 64, 0x80 + cp % 64)
		end
	end
	return table.concat(out)
end

local function FirstCodepoint(s)
	local b = string.byte(s or "", 1)
	if not b then return nil end
	if b < 0x80 then return b end
	local n, cp
	if b >= 0xF0 then n, cp = 3, b % 8
	elseif b >= 0xE0 then n, cp = 2, b % 16
	elseif b >= 0xC0 then n, cp = 1, b % 32
	else return nil end
	for i = 2, n + 1 do
		local c = string.byte(s, i)
		if not c or c < 0x80 or c >= 0xC0 then return nil end
		cp = cp * 64 + (c % 64)
	end
	return cp
end

local RANKS = {
	{ id = "Tier01", label = "AAA" }, { id = "Tier02", label = "AA+" }, { id = "Tier03", label = "AA" },
	{ id = "Tier04", label = "AA-" }, { id = "Tier05", label = "A+" }, { id = "Tier06", label = "A" },
	{ id = "Tier07", label = "A-" }, { id = "Tier08", label = "B+" }, { id = "Tier09", label = "B" },
	{ id = "Tier10", label = "B-" }, { id = "Tier11", label = "C+" }, { id = "Tier12", label = "C" },
	{ id = "Tier13", label = "C-" }, { id = "Tier14", label = "D+" }, { id = "Tier15", label = "D" },
	{ id = "E", label = "E" }, { id = "NOPLAY", label = "NO PLAY" },
}

-- (the order and the names of the arcade's list: FC is the Good FC and GFC the Great FC; ASSIST and LIFE4 are there for the
-- list to be the same, the game does not record them yet, so they never match a chart)
local CLEAR_TYPES = {
	{ id = "NOPLAY", label = "NO PLAY" }, { id = "FAILED", label = "FAILED" },
	{ id = "ASSIST", label = "ASSIST" }, { id = "CLEAR", label = "CLEARED" },
	{ id = "LIFE4", label = "LIFE4" }, { id = "GFC", label = "FC" },
	{ id = "GRFC", label = "GFC" }, { id = "PFC", label = "PFC" },
	{ id = "MFC", label = "MFC" },
}

local BPM_RANGES = {
	{ id = "1", label = "0-100", lo = 0, hi = 99 }, { id = "2", label = "100-120", lo = 100, hi = 119 },
	{ id = "3", label = "120-140", lo = 120, hi = 139 }, { id = "4", label = "140-160", lo = 140, hi = 159 },
	{ id = "5", label = "160-180", lo = 160, hi = 179 }, { id = "6", label = "180-200", lo = 180, hi = 199 },
	{ id = "7", label = "200-300", lo = 200, hi = 299 }, { id = "8", label = Utf8(0x33, 0x30, 0x30, 0x2D, 0x221E), lo = 300, hi = 99999 },
}

local DIFFICULTIES = {
	{ id = "Difficulty_Beginner", label = "Beginner" }, { id = "Difficulty_Easy", label = "Basic" },
	{ id = "Difficulty_Medium", label = "Difficult" }, { id = "Difficulty_Hard", label = "Expert" },
	{ id = "Difficulty_Challenge", label = "Challenge" },
}

-- Order in which the player's own difficulty is looked for when a chart has to be chosen
local DIFFICULTY_ORDER = {
	Difficulty_Beginner = 1, Difficulty_Easy = 2, Difficulty_Medium = 3, Difficulty_Hard = 4, Difficulty_Challenge = 5,
}

-- Flare skill (approximation, edit as needed): points of a chart = SkillBase[level] * SkillMult[FLARE level].
-- Only the order of the points matters here: the 30 best charts of each group (GOLD, WHITE, CLASSIC) are the ones that
-- "count"; the FLARE SKILL TARGET values select the charts that count and the ones that do not.
Filter.SkillBase = {}
for level = 1, 30 do Filter.SkillBase[level] = level * level end
Filter.SkillMult = { 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 1.00, 1.10, 1.20 }
Filter.SkillCount = 30

-- id, name, number of columns of the values grid, and (for fixed lists) the values
local function Range(first, last, label)
	local out = {}
	for i = first, last do out[#out + 1] = { id = tostring(i), label = label and label(i) or tostring(i) } end
	return out
end

local LEVELS = Range(1, 19)
LEVELS[#LEVELS + 1] = { id = "20", label = "20+" }

-- MUSIC TITLE (the arcade's list, in the order it is drawn: four columns): the kana rows (a title that starts with a kana,
-- hiragana or katakana), then the Latin letters in groups, then OTHER (digits, symbols, kanji...). Each kana row has its
-- first kana big and the rest small (`big`, `small`).
local TITLES = {}
local KANA_ROWS = {   -- id, first kana, the others of the row (code points)
	{ "K_A", 0x30A2, { 0x30A4, 0x30A6, 0x30A8, 0x30AA } }, { "K_KA", 0x30AB, { 0x30AD, 0x30AF, 0x30B1, 0x30B3 } },
	{ "K_SA", 0x30B5, { 0x30B7, 0x30B9, 0x30BB, 0x30BD } }, { "K_TA", 0x30BF, { 0x30C1, 0x30C4, 0x30C6, 0x30C8 } },
	{ "K_NA", 0x30CA, { 0x30CB, 0x30CC, 0x30CD, 0x30CE } }, { "K_HA", 0x30CF, { 0x30D2, 0x30D5, 0x30D8, 0x30DB } },
	{ "K_MA", 0x30DE, { 0x30DF, 0x30E0, 0x30E1, 0x30E2 } }, { "K_YA", 0x30E4, { 0x30E6, 0x30E8 } },
	{ "K_RA", 0x30E9, { 0x30EA, 0x30EB, 0x30EC, 0x30ED } }, { "K_WA", 0x30EF, { 0x30F2, 0x30F3 } },
}
for _, row in ipairs(KANA_ROWS) do
	local big, small = Utf8(row[2]), Utf8(unpack(row[3]))
	TITLES[#TITLES + 1] = { id = row[1], label = big .. small, big = big, small = small, summary = string.sub(row[1], 3) }
end
local LATIN_GROUPS = { "ABC", "DEF", "GHI", "JKL", "MNO", "PQR", "STU", "VWX", "YZ" }
local LATIN_GROUP_OF = {}
for _, group in ipairs(LATIN_GROUPS) do
	local letters = {}
	for i = 1, #group do
		LATIN_GROUP_OF[string.sub(group, i, i)] = group
		letters[#letters + 1] = string.sub(group, i, i)
	end
	TITLES[#TITLES + 1] = { id = group, label = table.concat(letters, ",") }
end
TITLES[#TITLES + 1] = { id = "OTHER", label = "OTHER" }

-- the kana rows by the code point of the katakana (a hiragana is moved to its katakana first)
local KANA_RANGES = {
	{ 0x30A1, 0x30AA, "K_A" }, { 0x30AB, 0x30B4, "K_KA" }, { 0x30B5, 0x30BE, "K_SA" }, { 0x30BF, 0x30C9, "K_TA" },
	{ 0x30CA, 0x30CE, "K_NA" }, { 0x30CF, 0x30DD, "K_HA" }, { 0x30DE, 0x30E2, "K_MA" }, { 0x30E3, 0x30E8, "K_YA" },
	{ 0x30E9, 0x30ED, "K_RA" }, { 0x30EE, 0x30F3, "K_WA" }, { 0x30F4, 0x30F4, "K_A" }, { 0x30F5, 0x30F6, "K_KA" },
}

-- FLARE RANK: NO RANK on its own row and then I ... EX in two rows of five
local FLARES = { { id = "NOFLARE", label = "NO RANK" } }
local ROMAN = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "EX" }
for i = 1, 10 do
	FLARES[#FLARES + 1] = { id = tostring(i), label = ROMAN[i] }
end

-- GENRE (the arcade's list). A song is in a genre when it is in the folder of the same name (Other/FolderCategories.txt) or
-- when its genre tag has one of the words (`words`; `anywhere` also looks at its title and artist). Edit the words to taste.
local GENRES = {
	{ id = "POP", label = "POP MUSIC", folder = "POP", words = { "pop music" } },
	{ id = "VIRTUAL", label = "VIRTUAL POP", folder = "VIRTUAL", words = { "virtual pop" } },
	{ id = "ANIME", label = "ANIME & GAME", folder = "ANIME", words = { "anime & game", "anime and game" } },
	{ id = "TOUHOU", label = "TOUHOU", folder = "TOUHOU", words = { "touhou" } },
	{ id = "VARIETY", label = "VARIETY", words = { "variety" } },
	{ id = "HINABITA", label = Utf8(0x3072, 0x306A, 0x30D3, 0x30BF, 0x266A, 0x20, 0x26, 0x20, 0x30D0, 0x30F3, 0x3081, 0x3057, 0x266A), jp = true,
		words = { Utf8(0x3072, 0x306A, 0x30D3, 0x30BF), Utf8(0x30D0, 0x30F3, 0x3081, 0x3057), "hinabita" }, anywhere = true,
		summary = "HINABITA" },
	{ id = "AUDITION", label = "AUDITION", words = { "audition" } },
}

-- (as in the original): TARGET = charts that are not among the ones that count for the flare skill yet, NON-TARGET = the
-- ones that do count
local SKILLS = { { id = "TARGET", label = "TARGET" }, { id = "NONTARGET", label = "NON-TARGET" } }

Filter.Categories = {
	-- (cols and cellW = the columns of the values grid and the distance between them, measured on the original)
	{ id = "LEVEL", name = "LEVEL", cols = 5, cellW = 42, values = LEVELS },
	-- the ITG categories only exist with the theme option "Include ITG" (Filter.IncludeItg) and when there are ITG packs
	{ id = "ITGLEVEL", name = "ITG LEVEL", cols = 5, cellW = 42 },   -- charts of the ITG packs (rated differently): values come from the songs
	{ id = "DIFFICULTY", name = "DIFFICULTY", cols = 1, values = DIFFICULTIES },
	-- VERSION: the arcade's list (three group buttons, then the DDR versions grouped like the arcade does), and after it the
	-- custom packs by name. Values come from the songs (a value chooses packs: the pack ids are their folders).
	{ id = "VERSION", name = "VERSION", cols = 2, cellW = 107 },   -- (the second column is 107 px from the first)
	{ id = "ITGVERSION", name = "ITG VERSION", cols = 1 },   -- the packs with an itg.ini file
	{ id = "TITLE", name = "MUSIC TITLE", cols = 4, cellW = 52, values = TITLES },
	{ id = "RANK", name = "CLEAR RANK", cols = 3, cellW = 68, values = RANKS },
	{ id = "CLEARTYPE", name = "CLEAR TYPE", cols = 2, cellW = 101, values = CLEAR_TYPES },
	{ id = "FLARE", name = "FLARE RANK", cols = 5, cellW = 40, values = FLARES },
	{ id = "SKILL", name = "FLARE SKILL TARGET", cols = 1, values = SKILLS },
	{ id = "BPM", name = "BPM", cols = 1, values = BPM_RANGES },
	{ id = "GENRE", name = "GENRE", cols = 1, values = GENRES },
	{ id = "EVENT", name = "EVENT", cols = 1 },   -- values come from Other/FilterEvents.txt
}

local CATEGORY = {}
for _, c in ipairs(Filter.Categories) do CATEGORY[c.id] = c end

-- ---------------------------------------------------------------------------
-- Selection
-- ---------------------------------------------------------------------------

function Filter.IsSelected(cat, id)
	return Selected[cat] ~= nil and Selected[cat][id] == true
end

local function Rebuild()
	local parts = {}
	for _, c in ipairs(Filter.Categories) do
		local set = Selected[c.id]
		if set then
			local ids = {}
			for id in pairs(set) do ids[#ids + 1] = id end
			table.sort(ids)
			parts[#parts + 1] = c.id .. "=" .. table.concat(ids, ",")
		end
	end
	if folder then parts[#parts + 1] = "FOLDER=" .. folder end
	signature = table.concat(parts, ";")
end

-- ---------------------------------------------------------------------------
-- Folders (the "folder screen" of DDR WORLD): FIRST STEP, POP MUSIC, VIRTUAL POP, ANIME & GAME, TOUHOU, FOR MUSIC
-- GAMERS and ALL MUSIC. A folder is one more condition of the filter (always on top of the other categories).
-- FIRST STEP is worked out from the charts (every song of the normal packs with a BEGINNER chart, listed by that
-- chart); the others come from Other/FolderCategories.txt (keywords and song lists, see that file).
-- ---------------------------------------------------------------------------
Filter.Folders = {
	{ id = "FIRST", name = "FIRST STEP", label = "FIRST STEP FOLDER",
		desc = { "Still getting your DDR groove?", "Keep dancing here!" } },
	{ id = "POP", name = "POP MUSIC", label = "POP MUSIC FOLDER",
		desc = { "Looking for famous songs?", "Get dancing to popular hits!" } },
	{ id = "VIRTUAL", name = "VIRTUAL POP", label = "VIRTUAL POP FOLDER",
		desc = { "Looking for songs sung by virtual singers?", "Look no further and get dancing!" } },
	{ id = "ANIME", name = "ANIME & GAME", label = "ANIME & GAME FOLDER",
		desc = { "Looking for hard-to-find anime and game songs?", "We've got you!" } },
	{ id = "TOUHOU", name = "TOUHOU", label = "TOUHOU Project FOLDER",
		desc = { "Looking for TOUHOU Project arrangement music?", "Find what you want here!" } },
	{ id = "GAMERS", name = "FOR MUSIC GAMERS", label = "FOR MUSIC GAMERS FOLDER",
		desc = { "Familiar with other music games but still getting a feel for DDR?", "Find all your favorite songs here!" } },
	{ id = "ALL", name = "ALL MUSIC", label = "ALL MUSIC FOLDER",
		desc = { "Browse the whole collection of songs!", "Filter the songs to help find the song you want!" } },
}

local FOLDER_BY_ID = {}
for _, f in ipairs(Filter.Folders) do FOLDER_BY_ID[f.id] = f end

-- the folder on (nil / "ALL" = the whole collection)
function Filter.GetFolder()
	return folder or "ALL"
end

function Filter.FolderName(id)
	local f = FOLDER_BY_ID[id or folder or "ALL"]
	return f and f.name or "ALL MUSIC"
end

function Filter.SetFolder(id)
	if id == "ALL" or not FOLDER_BY_ID[id or ""] then id = nil end
	folder = id
	Rebuild()
end

-- true when a category of the filter menu has values chosen (the folder does not count)
function Filter.CategoriesActive()
	return next(Selected) ~= nil
end

function Filter.Active()
	return signature ~= ""
end

-- Part of the cache key of the lists that are built with the filter.
function Filter.Signature()
	if signature == "" then return "" end
	return signature .. "#" .. stamp
end

-- true if the selection of a group (GOLD, WHITE, CLASSIC) has every member selected
function Filter.GroupSelected(value)
	if not value.members then return false end
	for _, m in ipairs(value.members) do
		if not Filter.IsSelected("VERSION", m) then return false end
	end
	return true
end

function Filter.Toggle(cat, value)
	local set = Selected[cat]
	if not set then
		set = {}
		Selected[cat] = set
	end

	if value.members then
		-- a group button: all its versions on, or all off when they already are
		local all = Filter.GroupSelected(value)
		if Filter.Mode == "Simple" then for k in pairs(set) do set[k] = nil end end
		for _, m in ipairs(value.members) do
			if all then set[m] = nil else set[m] = true end
		end
	elseif set[value.id] then
		set[value.id] = nil
	else
		if Filter.Mode == "Simple" then for k in pairs(set) do set[k] = nil end end
		set[value.id] = true
	end

	if next(set) == nil then Selected[cat] = nil end
	Rebuild()
end

function Filter.ClearAll()
	Selected = {}
	Rebuild()
end

function Filter.ClearCategory(cat)
	Selected[cat] = nil
	Rebuild()
end

-- The menus (filter, folders) edit the selection as they go. Snapshot() is taken when the filter menu opens and RestoreSnapshot()
-- puts everything back as it was: used when the menu timer runs out (the menu closes WITHOUT applying what was changed).
local snapshot
function Filter.Snapshot()
	local copy = {}
	for cat, set in pairs(Selected) do
		local s = {}
		for k, v in pairs(set) do s[k] = v end
		copy[cat] = s
	end
	snapshot = { selected = copy, folder = folder, mode = Filter.Mode }
end

function Filter.RestoreSnapshot()
	if not snapshot then return end
	local copy = {}
	for cat, set in pairs(snapshot.selected) do
		local s = {}
		for k, v in pairs(set) do s[k] = v end
		copy[cat] = s
	end
	Selected = copy
	folder = snapshot.folder
	Filter.Mode = snapshot.mode
	Rebuild()
end

-- Number of values selected in a category (for the marker in the category list).
function Filter.CountSelected(cat)
	local n = 0
	for _ in pairs(Selected[cat] or {}) do n = n + 1 end
	return n
end

-- ---------------------------------------------------------------------------
-- Song data
-- ---------------------------------------------------------------------------

local function CurrentStepsType()
	local style = GAMESTATE:GetCurrentStyle()
	return style and style:GetStepsType() or "StepsType_Dance_Single"
end

local function Players()
	local list = GAMESTATE:GetEnabledPlayers()
	if not list or #list == 0 then return { PLAYER_1 } end
	return list
end

local function VersionOf(group)
	local name = string.lower(group or "")
	name = string.gsub(name, "^%d+%s*%-%s*", "")
	name = string.gsub(name, "^%s+", "")
	name = string.gsub(name, "%s+$", "")
	return VERSION_OF[name] or "OTHER"
end

local function SongKey(song)
	local dir = string.gsub(song:GetSongDir(), "/$", "")
	local folder = string.match(dir, "([^/]+)$")
	if not folder then return nil end
	return string.lower(song:GetGroupName() .. "/" .. folder)
end

-- the group of MUSIC TITLE a song is in: a kana row when the title starts with a kana, else the group of its first Latin
-- letter, else OTHER
local function TitleInitial(song)
	local cp = FirstCodepoint(song:GetDisplayMainTitle() or "")
	if cp then
		if cp >= 0x3041 and cp <= 0x3096 then cp = cp + 0x60 end   -- hiragana -> katakana
		for _, r in ipairs(KANA_RANGES) do
			if cp >= r[1] and cp <= r[2] then return r[3] end
		end
	end
	local sortTitle = SongOrder and SongOrder.SortTitle and SongOrder.SortTitle(song) or song:GetTranslitMainTitle() or ""
	local c = string.upper(string.sub(sortTitle, 1, 1))
	return LATIN_GROUP_OF[c] or "OTHER"
end

local function ThemeFile(rel)
	local dir = THEME:GetCurrentThemeDirectory()
	if string.sub(dir, 1, 1) ~= "/" then dir = "/" .. dir end
	if string.sub(dir, -1) ~= "/" then dir = dir .. "/" end
	return dir .. rel
end

-- Other/FilterEvents.txt: "---EVENT NAME" and then the songs ("Group/Folder", one per line)
local function LoadEvents()
	local events, names = {}, {}   -- [song key] = { event name... }, ordered list of names
	local file = RageFileUtil.CreateRageFile()
	local text
	if file:Open(ThemeFile("Other/FilterEvents.txt"), 1) then text = file:Read() end
	file:Close()
	file:destroy()
	if not text then return events, names end

	local current
	for line in (text .. "\n"):gmatch("(.-)\r?\n") do
		line = string.gsub(line, "^%s+", "")
		line = string.gsub(line, "%s+$", "")
		if string.sub(line, 1, 3) == "---" then
			current = string.upper(string.sub(line, 4))
			if current ~= "" then names[#names + 1] = current else current = nil end
		elseif line ~= "" and string.sub(line, 1, 2) ~= "//" and string.sub(line, 1, 1) ~= "#" and current then
			local key = string.lower(string.gsub(line, "\\", "/"))
			events[key] = events[key] or {}
			table.insert(events[key], current)
		end
	end
	return events, names
end

-- Other/FolderCategories.txt: "---FOLDER NAME" (POP MUSIC, VIRTUAL POP, ANIME & GAME, TOUHOU, FOR MUSIC GAMERS) and then
-- lines "@word" (a song belongs to the folder when its title, artist or genre has that WORD) and
-- "Group/Folder" (one song). Returns { [folder id] = { words = {pattern...}, songs = { [song key] = true } } }.
local FOLDER_HEADINGS = {
	["POP MUSIC"] = "POP", ["VIRTUAL POP"] = "VIRTUAL", ["ANIME & GAME"] = "ANIME", ["ANIME AND GAME"] = "ANIME",
	["TOUHOU"] = "TOUHOU", ["TOUHOU PROJECT"] = "TOUHOU", ["FOR MUSIC GAMERS"] = "GAMERS",
}

-- a pattern that finds the word as a whole word (so "tag" does not match "stage")
local function WordPattern(word)
	local escaped = string.gsub(word, "%p", "%%%0")
	if string.find(word, "^%w") then escaped = "%f[%w]" .. escaped end
	if string.find(word, "%w$") then escaped = escaped .. "%f[%W]" end
	return escaped
end

local function LoadFolderData()
	local data = {}
	local file = RageFileUtil.CreateRageFile()
	local text
	if file:Open(ThemeFile("Other/FolderCategories.txt"), 1) then text = file:Read() end
	file:Close()
	file:destroy()
	if not text then return data end

	local current
	for line in (text .. "\n"):gmatch("(.-)\r?\n") do
		line = string.gsub(line, "^%s+", "")
		line = string.gsub(line, "%s+$", "")
		if string.sub(line, 1, 3) == "---" then
			current = FOLDER_HEADINGS[string.upper(string.sub(line, 4))]
			if current then data[current] = data[current] or { words = {}, songs = {} } end
		elseif line ~= "" and current and string.sub(line, 1, 2) ~= "//" and string.sub(line, 1, 1) ~= "#" then
			if string.sub(line, 1, 1) == "@" then
				local word = string.lower(string.sub(line, 2))
				if word ~= "" then table.insert(data[current].words, WordPattern(word)) end
			else
				data[current].songs[string.lower(string.gsub(line, "\\", "/"))] = true
			end
		end
	end
	return data
end

-- info of every song: version, title initial, genre, BPM, events and the charts of the current steps type
local index     -- { list = {...}, byDir = {...}, stepsType, count, genres = {...}, eventValues = {...} }
local building   -- an index that is being built a few songs per frame (Filter.Warm)

local function StartBuild(stepsType, n)
	local events, eventNames = LoadEvents()
	building = {
		songs = SONGMAN:GetAllSongs(), i = 0, stepsType = stepsType, n = n,
		events = events, eventNames = eventNames, list = {}, byDir = {}, genreSet = {}, itgPack = {}, itgLevels = {}, packs = {},
		folderData = LoadFolderData(),
	}
end

-- the folders a song is in: { [folder id] = true }
local function FoldersOf(b, song, key, itg, charts)
	local out = {}
	if itg then return out end   -- the folders are for the normal packs
	for _, chart in ipairs(charts) do
		if chart.diff == "Difficulty_Beginner" then out.FIRST = true break end
	end
	local text
	for id, entry in pairs(b.folderData) do
		if entry.songs[key] then
			out[id] = true
		elseif #entry.words > 0 then
			if not text then
				text = string.lower(table.concat({
					song:GetDisplayMainTitle() or "", song:GetTranslitMainTitle() or "", song:GetDisplaySubTitle() or "",
					song:GetDisplayArtist() or "", song:GetTranslitArtist() or "", song.GetGenre and song:GetGenre() or "",
				}, "\n"))
			end
			for _, pattern in ipairs(entry.words) do
				if string.find(text, pattern) then out[id] = true break end
			end
		end
	end
	return out
end

local function AddSong(b, song)
	local key = SongKey(song)
	if not key then return end
	local bpm = song.GetDisplayBpms and song:GetDisplayBpms() or { 0, 0 }
	local genre = song.GetGenre and song:GetGenre() or ""
	local charts = {}
	for _, steps in ipairs(song:GetStepsByStepsType(b.stepsType)) do
		local difficulty = steps:GetDifficulty()
		if difficulty ~= "Difficulty_Edit" and steps:GetMeter() >= 1 then
			charts[#charts + 1] = { steps = steps, diff = difficulty, meter = steps:GetMeter() }
		end
	end
	-- a pack with an itg.ini file is rated with the ITG system (the same rule as Scripts/08 LevelSort.lua)
	local packDir = string.match(song:GetSongDir(), "^(.*/)[^/]+/$")
	local itg = false
	if packDir then
		itg = b.itgPack[packDir]
		if itg == nil then
			itg = FILEMAN:DoesFileExist(packDir .. "itg.ini") and true or false
			b.itgPack[packDir] = itg
		end
	end
	if itg then
		for _, chart in ipairs(charts) do b.itgLevels[chart.meter] = true end
	end
	local info = {
		song = song, dir = song:GetSongDir(), itg = itg,
		group = song:GetGroupName(),   -- the pack (its folder name): what the VERSION / ITG VERSION categories choose
		version = itg and "ITG" or VersionOf(song:GetGroupName()),
		initial = TitleInitial(song),
		genre = genre,
		bpmMin = bpm[1] or 0, bpmMax = bpm[2] or bpm[1] or 0,
		events = b.events[key],
		charts = charts,
		folders = FoldersOf(b, song, key, itg, charts),
	}
	-- the GENRE values the song is in (see GENRES)
	local lowGenre = string.lower(genre)
	local lowAll
	for _, g in ipairs(GENRES) do
		local hit = g.folder and info.folders[g.folder]
		if not hit then
			local text = lowGenre
			if g.anywhere then
				lowAll = lowAll or string.lower(table.concat({
					song:GetDisplayMainTitle() or "", song:GetDisplayArtist() or "", genre }, "\n"))
				text = lowAll
			end
			for _, word in ipairs(g.words) do
				if string.find(text, word, 1, true) then hit = true break end
			end
		end
		if hit then
			info.genreIds = info.genreIds or {}
			info.genreIds[g.id] = true
		end
	end
	b.list[#b.list + 1] = info
	b.byDir[info.dir] = info
	b.genreSet[genre] = true
	if not b.packs[info.group] then b.packs[info.group] = { group = info.group, itg = itg, version = info.version } end
end

-- ---------------------------------------------------------------------------
-- Group names to SHOW (the real folder name stays the id of the pack, for filtering).
--   Filter.GroupIniName(group)      the name written in the pack's group.ini, or nil when it has none
--   Filter.GroupDisplayName(group)  group.ini; if none, SongAttributes.GetGroupName without the "NN - " prefix
-- The results are kept in memory: after editing a group.ini or reloading the songs, restart the game.
-- ---------------------------------------------------------------------------
do
	local iniCache, nameCache = {}, {}
	local KEYS = { "displaytitle", "displayname", "groupname", "name", "title" }   -- by priority

	local function Trim(s) return (tostring(s):gsub("^%s+", ""):gsub("%s+$", "")) end

	local function ReadIniName(group)
		local songs = SONGMAN:GetSongsInGroup(group)
		local first = songs and songs[1]
		if not first then return nil end
		-- the folder of the pack: one level above the folder of the song
		local dir = string.match(first:GetSongDir(), "^(.*/)[^/]+/?$")
		if not dir then return nil end
		for _, fname in ipairs({ "group.ini", "Group.ini" }) do
			local p = dir .. fname
			if FILEMAN:DoesFileExist(p) then
				local ini = IniFile.ReadFile(p)
				if type(ini) == "table" then
					for _, want in ipairs(KEYS) do
						for _, sec in pairs(ini) do
							if type(sec) == "table" then
								for k, v in pairs(sec) do
									if tostring(k):lower() == want and Trim(v) ~= "" then return Trim(v) end
								end
							end
						end
					end
				end
			end
		end
		return nil
	end

	function Filter.GroupIniName(group)
		if group == nil then return nil end
		local c = iniCache[group]
		if c == nil then
			c = ReadIniName(group) or false
			iniCache[group] = c
		end
		return c or nil
	end

	function Filter.GroupDisplayName(group)
		if group == nil then return "" end
		if nameCache[group] == nil then
			local name = Filter.GroupIniName(group)
			if not name then
				local base = (SongAttributes and SongAttributes.GetGroupName and SongAttributes.GetGroupName(group)) or group
				name = (tostring(base):gsub("^%d+%s*%-%s*", ""))
			end
			nameCache[group] = name
		end
		return nameCache[group]
	end
end

-- the name of a pack without the number of its folder ("21 - DDR WORLD" -> "DDR WORLD"), or the one of its group.ini
-- (the same name the rest of the theme shows for the group: group.ini, then SongAttributes.GetGroupName, then the folder name)
local function PackName(group)
	return Filter.GroupDisplayName(group)
end

-- The values of VERSION, in the arcade's order and format: the three group buttons (GOLD / WHITE / CLASSIC), then WORLD,
-- A3, A20 - A20 PLUS, A, 2013 - 2014, X - X3 VS 2ndMIX, SuperNOVA - SuperNOVA2, MAX - EXTREME and 1st - 5thMIX (each one
-- chooses all the packs it covers: see VERSIONS / VERSION_OF), and after them the packs without itg.ini that are not
-- DDR, by their full name in alphabetical order. ITG VERSION: the packs with itg.ini, in alphabetical order.
local function PackValues(packs)
	local ddr, custom, itgList = {}, {}, {}
	for _, p in pairs(packs) do
		if p.itg then
			itgList[#itgList + 1] = p
		elseif p.version ~= "OTHER" then
			ddr[#ddr + 1] = p
		else
			custom[#custom + 1] = p
		end
	end
	local function ByName(a, b) return string.lower(PackName(a.group)) < string.lower(PackName(b.group)) end
	table.sort(custom, ByName)
	table.sort(itgList, ByName)

	local version, itgVersion = {}, {}
	for _, v in ipairs(VERSIONS) do
		-- (the three group buttons list the versions they cover in `members`; the others are one version each)
		local covers = v.members or { v.id }
		if v.id ~= "OTHER" and v.id ~= "ITG" then
			local members = {}
			for _, p in ipairs(ddr) do
				for _, m in ipairs(covers) do
					if p.version == m then members[#members + 1] = p.group break end
				end
			end
			if #members > 0 then
				version[#version + 1] = { id = v.id, label = v.label, members = members, tag = v.members ~= nil }
			end
		end
	end
	for _, p in ipairs(custom) do version[#version + 1] = { id = p.group, label = PackName(p.group) } end
	for _, p in ipairs(itgList) do itgVersion[#itgVersion + 1] = { id = p.group, label = PackName(p.group) } end
	return version, itgVersion
end

-- Works on the index that is being built for `seconds` (nil = until it is done). Returns true when it is done.
local function Work(b, seconds)
	local stop = seconds and (GetTimeSinceStart() + seconds)
	local songs = b.songs
	while b.i < #songs do
		b.i = b.i + 1
		AddSong(b, songs[b.i])
		if stop and b.i % 16 == 0 and GetTimeSinceStart() >= stop then return false end
	end

	local genres = {}
	for genre in pairs(b.genreSet) do
		genres[#genres + 1] = { id = genre, label = genre == "" and "NOT AVAILABLE" or string.upper(genre) }
	end
	table.sort(genres, function(a, c) return a.label < c.label end)
	local eventValues = {}
	for _, name in ipairs(b.eventNames) do eventValues[#eventValues + 1] = { id = name, label = name } end

	local itgValues = {}
	for meter in pairs(b.itgLevels) do itgValues[#itgValues + 1] = meter end
	table.sort(itgValues)
	for i, meter in ipairs(itgValues) do itgValues[i] = { id = tostring(meter), label = tostring(meter) } end

	local versionValues, itgVersionValues = PackValues(b.packs)

	index = {
		list = b.list, byDir = b.byDir, stepsType = b.stepsType, count = b.n,
		genres = genres, eventValues = eventValues, itgValues = itgValues, hasItg = next(b.itgLevels) ~= nil,
		versionValues = versionValues, itgVersionValues = itgVersionValues,
	}
	building = nil
	return true
end

-- The index is asked for once per song by the lists, so this must be cheap when nothing changed: it only compares
-- the steps type and the number of songs (GetAllSongs makes a new table of every song each time).
local function BuildIndex()
	local stepsType = CurrentStepsType()
	local n = SONGMAN:GetNumSongs()
	if index and index.stepsType == stepsType and index.count == n then return index end
	if not building or building.stepsType ~= stepsType or building.n ~= n then StartBuild(stepsType, n) end
	Work(building, nil)
	return index
end

-- Builds the index a little each frame (the caution screen calls this). Returns true when it is ready.
function Filter.Warm(seconds)
	local stepsType = CurrentStepsType()
	local n = SONGMAN:GetNumSongs()
	if index and index.stepsType == stepsType and index.count == n then return true end
	if not building or building.stepsType ~= stepsType or building.n ~= n then StartBuild(stepsType, n) end
	return Work(building, seconds)
end
-- Values of a category (the fixed ones, or the ones taken from the songs / the events file).
function Filter.Values(cat)
	local c = CATEGORY[cat]
	if not c then return {} end
	if c.values then return c.values end
	local idx = BuildIndex()
	if cat == "VERSION" then return idx.versionValues end
	if cat == "ITGVERSION" then return idx.itgVersionValues end
	if cat == "GENRE" then return idx.genres end
	if cat == "ITGLEVEL" then return idx.itgValues end
	if cat == "EVENT" then return idx.eventValues end
	return {}
end

-- ---------------------------------------------------------------------------
-- Matching
-- ---------------------------------------------------------------------------

-- The theme option "Include ITG" (Theme Options, off by default): without it the ITG packs are never shown and the ITG
-- categories of the filter do not exist.
function Filter.IncludeItg()
	local ok, value = pcall(function() return ThemePrefs.Get("IncludeITG") end)
	return ok and value == "On"
end

-- ITG packs (a pack with an itg.ini file) are not part of the theme's normal lists: they are left out unless the filter
-- asks for them (ITG LEVEL or ITG VERSION). When no pack has that file nothing is left out.
local function ItgRequested()
	return Filter.IncludeItg() and (Selected.ITGLEVEL ~= nil or Selected.ITGVERSION ~= nil)
end

-- true when there is at least one pack with an itg.ini file
function Filter.HasItg()
	return BuildIndex().hasItg == true
end

-- true when the ITG packs are left out of the lists right now
function Filter.HidesItg()
	return Filter.HasItg() and not ItgRequested()
end

-- true when the lists of the theme have to ask Filter.Pass (a filter is on, or the ITG packs are left out)
function Filter.Restricts()
	return signature ~= "" or Filter.HidesItg()
end

-- The categories the menu shows: the ITG ones only exist with the theme option "Include ITG" and when there are ITG packs.
function Filter.VisibleCategories()
	local list = {}
	local itg = Filter.IncludeItg() and Filter.HasItg()
	if not itg and (Selected.ITGLEVEL or Selected.ITGVERSION) then
		-- the option was turned off (or the packs are gone): their values do not count any more
		Selected.ITGLEVEL, Selected.ITGVERSION = nil, nil
		Rebuild()
	end
	for _, c in ipairs(Filter.Categories) do
		if (c.id ~= "ITGLEVEL" and c.id ~= "ITGVERSION") or itg then list[#list + 1] = c end
	end
	return list
end

local function SongMatches(info)
	local sel = Selected
	if info.itg and not ItgRequested() then return false end
	if folder and not info.folders[folder] then return false end
	if sel.ITGVERSION and not (info.itg and sel.ITGVERSION[info.group]) then return false end
	if sel.VERSION and not sel.VERSION[info.group] then return false end
	if sel.TITLE and not sel.TITLE[info.initial] then return false end
	if sel.GENRE then
		local ok = false
		if info.genreIds then
			for id in pairs(sel.GENRE) do
				if info.genreIds[id] then ok = true break end
			end
		end
		if not ok then return false end
	end
	if sel.BPM then
		local ok = false
		for _, r in ipairs(BPM_RANGES) do
			if sel.BPM[r.id] and info.bpmMax >= r.lo and info.bpmMin <= r.hi then ok = true break end
		end
		if not ok then return false end
	end
	if sel.EVENT then
		local ok = false
		for _, name in ipairs(info.events or {}) do
			if sel.EVENT[name] then ok = true break end
		end
		if not ok then return false end
	end
	return true
end

-- the 30 best charts (by approximate flare skill points) of each group, per player: [pn] = { [chart key] = true }
local counted = {}

local function ChartKey(info, chart)
	return info.dir .. "|" .. chart.diff
end

local function CountedSet(pn)
	if counted[pn] then return counted[pn] end
	local perGroup = {}
	if FlareGauge and FlareGauge.GetClear then
		for _, info in ipairs(BuildIndex().list) do
			local group = SKILL_GROUP[info.version]
			if group then
				for _, chart in ipairs(info.charts) do
					local level = FlareGauge.GetClear(pn, info.song, chart.steps)
					if level and level >= 1 and level <= 10 then
						local points = (Filter.SkillBase[chart.meter] or chart.meter * chart.meter) * (Filter.SkillMult[level] or 1)
						perGroup[group] = perGroup[group] or {}
						table.insert(perGroup[group], { key = ChartKey(info, chart), points = points })
					end
				end
			end
		end
	end
	local set = {}
	for _, list in pairs(perGroup) do
		table.sort(list, function(a, b) return a.points > b.points end)
		for i = 1, math.min(Filter.SkillCount, #list) do set[list[i].key] = true end
	end
	counted[pn] = set
	return set
end

-- true if a chart fits the score categories for this player (all of them at once)
local function PlayerMatches(pn, info, chart)
	local sel = Selected

	if sel.RANK or sel.CLEARTYPE then
		local data = WheelCache and WheelCache.Chart and WheelCache.Chart(pn, info.song, BuildIndex().stepsType, chart.diff) or { score = 0 }
		local played = data.gradeFile ~= nil
		local failed = data.gradeFile == "Grade_Failed"

		if sel.RANK then
			local id
			if not played then
				id = "NOPLAY"
			elseif failed then
				id = "E"
			else
				id = string.sub(data.gradeFile, 7)   -- "Grade_Tier01" -> "Tier01"
				if id == "Tier16" or id == "Tier17" then id = "E" end
			end
			if not sel.RANK[id] then return false end
		end

		if sel.CLEARTYPE then
			local id
			if not played then
				id = "NOPLAY"
			elseif failed then
				id = "FAILED"
			elseif data.mark == "MarvelousFullCombo" then
				id = "MFC"
			elseif data.mark == "PerfectFullCombo" then
				id = "PFC"
			elseif data.mark == "GreatFullCombo" then
				id = "GRFC"
			elseif data.mark == "GoodFullCombo" then
				id = "GFC"
			else
				id = "CLEAR"
			end
			if not sel.CLEARTYPE[id] then return false end
		end
	end

	if sel.FLARE then
		local level = FlareGauge and FlareGauge.GetClear and FlareGauge.GetClear(pn, info.song, chart.steps)
		local id = level and tostring(level) or "NOFLARE"
		if not sel.FLARE[id] then return false end
	end

	if sel.SKILL then
		local id = CountedSet(pn)[ChartKey(info, chart)] and "NONTARGET" or "TARGET"
		if not sel.SKILL[id] then return false end
	end

	return true
end

local function ChartMatches(info, chart)
	local sel = Selected
	-- FIRST STEP lists the BEGINNER chart of every song
	if folder == "FIRST" and chart.diff ~= "Difficulty_Beginner" then return false end
	if sel.LEVEL or sel.ITGLEVEL then
		if info.itg then
			if not (sel.ITGLEVEL and sel.ITGLEVEL[tostring(chart.meter)]) then return false end
		else
			local id = chart.meter >= 20 and "20" or tostring(chart.meter)
			if not (sel.LEVEL and sel.LEVEL[id]) then return false end
		end
	end
	if sel.DIFFICULTY and not sel.DIFFICULTY[chart.diff] then return false end
	if sel.RANK or sel.CLEARTYPE or sel.FLARE or sel.SKILL then
		for _, pn in ipairs(Players()) do
			if PlayerMatches(pn, info, chart) then return true end
		end
		return false
	end
	return true
end

-- true when any chart category has a value selected (the filter then also decides WHICH chart of a song is shown)
function Filter.HasChartCondition()
	local s = Selected
	return folder == "FIRST" or (s.LEVEL or s.ITGLEVEL or s.DIFFICULTY or s.RANK or s.CLEARTYPE or s.FLARE or s.SKILL) ~= nil
end

-- What the folder screen shows for a folder: how many songs it has (the ones of the normal packs, whatever the filter
-- says) and which difficulties it has. Worked out once per index. Returns count, { [difficulty] = true }.
local folderStats, folderStatsFor
function Filter.FolderStats(id)
	local idx = BuildIndex()
	if folderStatsFor ~= idx then
		folderStats, folderStatsFor = {}, idx
	end
	if folderStats[id] then return folderStats[id].count, folderStats[id].difficulties end
	local count, difficulties = 0, {}
	for _, info in ipairs(idx.list) do
		if not info.itg and (id == "ALL" or info.folders[id]) then
			count = count + 1
			for _, chart in ipairs(info.charts) do
				if id ~= "FIRST" or chart.diff == "Difficulty_Beginner" then difficulties[chart.diff] = true end
			end
		end
	end
	folderStats[id] = { count = count, difficulties = difficulties }
	return count, difficulties
end

local function SongPasses(info)
	if not SongMatches(info) then return false end
	if not Filter.HasChartCondition() then return true end
	for _, chart in ipairs(info.charts) do
		if ChartMatches(info, chart) then return true end
	end
	return false
end

-- true when the song is listed with the current filter (always true when there is no filter)
function Filter.Pass(song)
	if signature == "" and not Filter.HidesItg() then return true end
	local info = BuildIndex().byDir[song:GetSongDir()]
	if not info then return false end
	return SongPasses(info)
end

-- true when this chart of the song is listed (the LEVEL sort lists charts)
function Filter.PassChart(song, steps)
	if signature == "" and not Filter.HidesItg() then return true end
	local info = BuildIndex().byDir[song:GetSongDir()]
	if not info or not SongMatches(info) then return false end
	-- (compared by difficulty: the chart objects the engine hands out are not always the same ones)
	local difficulty = steps:GetDifficulty()
	for _, chart in ipairs(info.charts) do
		if chart.diff == difficulty then return ChartMatches(info, chart) end
	end
	return false
end

-- Number of songs listed with the current selection (for "Filtering Results").
local countKey, countValue
function Filter.Count()
	local idx = BuildIndex()
	local key = signature .. "#" .. stamp .. "#" .. idx.count
	if countKey == key then return countValue end
	-- with a chart category the result is a list of charts (a song with two matching charts is two results)
	local n = 0
	local chartMode = Filter.HasChartCondition()
	for _, info in ipairs(idx.list) do
		if SongMatches(info) then
			if chartMode then
				for _, chart in ipairs(info.charts) do
					if ChartMatches(info, chart) then n = n + 1 end
				end
			else
				n = n + 1
			end
		end
	end
	countKey, countValue = key, n
	return n
end

-- What the filter menu has chosen, in a few words, for the FILTER button of the wheel ("A3 + LEVEL: 11"). "" when nothing
-- is chosen (the folder does not count).
function Filter.Summary()
	local parts = {}
	for _, c in ipairs(Filter.Categories) do
		local set = Selected[c.id]
		if set then
			local labels = {}
			if c.id == "VERSION" or c.id == "ITGVERSION" then
				-- the selection holds the real folders of the packs ("21 - DDR WORLD"), whatever button was pressed:
				-- they are shown with the name of their group.ini, or without the "NN - " prefix (in the order of the folders)
				local ids = {}
				for id in pairs(set) do ids[#ids + 1] = id end
				table.sort(ids)
				for _, id in ipairs(ids) do labels[#labels + 1] = PackName(id) end
			else
				for _, v in ipairs(Filter.Values(c.id)) do
					if set[v.id] then labels[#labels + 1] = v.summary or v.label end
				end
				if #labels == 0 then
					for id in pairs(set) do labels[#labels + 1] = id end
					table.sort(labels)
				end
			end
			local text = #labels <= 2 and table.concat(labels, " / ") or (#labels .. " selected")
			if c.id ~= "VERSION" and c.id ~= "ITGVERSION" and c.id ~= "DIFFICULTY" then text = c.name .. ": " .. text end
			parts[#parts + 1] = text
		end
	end
	return table.concat(parts, " + ")
end

-- The result as ONE list (like the arcade): every song that fits, in the alphabetical order of the theme (Latin
-- titles first or last depending on the language), and a song with several matching charts appears once per chart,
-- the easier chart first. Each entry: { song, difficulty (nil when no chart category is on) }.
function Filter.Entries()
	local idx = BuildIndex()
	local chartMode = Filter.HasChartCondition()
	local out = {}
	for _, info in ipairs(idx.list) do
		if SongMatches(info) then
			local key = SongOrder and SongOrder.OrderKey and SongOrder.OrderKey(info.song)
				or string.upper(info.song:GetTranslitMainTitle() or "")
			if chartMode then
				for _, chart in ipairs(info.charts) do
					if ChartMatches(info, chart) then
						out[#out + 1] = { song = info.song, difficulty = chart.diff, key = key,
							order = DIFFICULTY_ORDER[chart.diff] or 0 }
					end
				end
			else
				out[#out + 1] = { song = info.song, key = key, order = 0 }
			end
		end
	end
	table.sort(out, function(a, b)
		if a.key ~= b.key then return a.key < b.key end
		if a.order ~= b.order then return a.order < b.order end
		return a.song:GetSongDir() < b.song:GetSongDir()
	end)
	return out, chartMode
end

-- ---------------------------------------------------------------------------
-- Life cycle
-- ---------------------------------------------------------------------------

-- Call when scores may have changed (the select music screen starts): lists that depend on them are built again.
function Filter.Touch()
	counted = {}
	if Filter.HasChartCondition() and (Selected.RANK or Selected.CLEARTYPE or Selected.FLARE or Selected.SKILL) then
		stamp = stamp + 1
	end
end

-- Call when the filter menu opens: the scores of the players are read again (in the background, see WarmScores).
local warmPlayer, warmSong, warmChart = 1, 1, 1
function Filter.Refresh()
	counted = {}
	countKey = nil
	warmPlayer, warmSong, warmChart = 1, 1, 1
end

-- Reads the best score of every chart for the players, `seconds` per call, so that choosing CLEAR RANK or CLEAR TYPE
-- later does not have to do it all at once. Returns true when it is done.
function Filter.WarmScores(seconds)
	if not (WheelCache and WheelCache.Chart) then return true end
	local idx = BuildIndex()
	local players = Players()
	local stop = GetTimeSinceStart() + seconds
	while warmPlayer <= #players do
		local pn = players[warmPlayer]
		local list = idx.list
		while warmSong <= #list do
			local info = list[warmSong]
			for _, chart in ipairs(info.charts) do WheelCache.Chart(pn, info.song, idx.stepsType, chart.diff) end
			warmSong = warmSong + 1
			if warmSong % 8 == 0 and GetTimeSinceStart() >= stop then return false end
		end
		warmPlayer, warmSong = warmPlayer + 1, 1
	end
	return true
end
-- true while the LEVEL sort is on screen because of a LEVEL filter (and not because the player chose it)
local levelByFilter = false

-- The single section of the filter list must be OPEN when the wheel appears. The engine opens the section that has the
-- current song; after a folder / filter change the song may not be in the list, and the wheel would show only the
-- closed header. Call every frame with the wheel (BGAnimations/ScreenSelectMusic overlay/LevelSort.lua).
local needOpen, openTries, openSince = false, 0, 0
local reloadPending = false   -- (see Filter.RequestReload)

-- START on the header of the list ("Change folder") also reaches the engine, which closes the section: the menus ask
-- for it to be opened again when they close without changing the list.
function Filter.RequestOpen()
	needOpen, openTries, openSince = true, 0, GetTimeSinceStart()
end

-- Called when the select music screen has just been built (before the wheel intro shows anything): a list that came
-- up closed is opened at once, so the player never sees the header first. Returns nothing; Filter.OpenedAtStart() tells
-- LevelSort.lua to put the cursor on the first song once the wheel is quiet.
local openedAtStart = false
function Filter.OpenAtStart(wheel)
	if not wheel or reloadPending then return end
	local name = Filter.SectionName
	if not name or GAMESTATE:GetSortOrder() ~= "SortOrder_Preferred" then return end
	Trace("Filter.OpenAtStart: items = " .. tostring(wheel:GetNumItems()) .. ", open = '"
		.. tostring(GAMESTATE:GetExpandedSectionName()) .. "', needOpen = " .. tostring(needOpen)
		.. ", song = " .. tostring(GAMESTATE:GetCurrentSong() ~= nil))
	-- (a closed list, only its header, is never wanted here: coming back from the difficulty selection the wheel was built
	-- closed and stayed that way, because nobody had asked for it to be opened)
	if not (needOpen or (Filter.FlatByDefault and LevelSort and LevelSort.Loaded)) then return end
	if wheel:GetNumItems() ~= 1 or not wheel.SetOpenSection then return end
	Trace("Filter: opening the list '" .. name .. "' at once")
	wheel:SetOpenSection(name)
	openedAtStart = true
end

function Filter.OpenedAtStart()
	local value = openedAtStart
	openedAtStart = false
	return value
end

-- The wheel is checked by what it shows, not by the name the game remembers as open: after a reload the name can be the
-- new one while the wheel was built closed (only the header, which then repeats all over the wheel). A closed list has
-- one item; an open one has the songs too.
function Filter.EnsureOpen(wheel)
	if not wheel or reloadPending then return end
	if not needOpen then
		-- a list that is closed (one item) in the main sort is opened even if nobody asked: see Filter.OpenAtStart
		-- (not while the filter / folder screens are on top: they closed it with START on purpose and ask for it later)
		local top = SCREENMAN:GetTopScreen()
		if top and top:GetName() == "ScreenSelectMusic" and Filter.FlatByDefault and LevelSort and LevelSort.Loaded and Filter.SectionName
				and GAMESTATE:GetSortOrder() == "SortOrder_Preferred" and wheel:GetNumItems() == 1 then
			Filter.RequestOpen()
		end
		return
	end
	if GAMESTATE:GetSortOrder() ~= "SortOrder_Preferred" then return end
	if wheel.IsSettled and not wheel:IsSettled() then return end
	if wheel.IsLocked and wheel:IsLocked() then return end
	local name = Filter.SectionName
	if not name or wheel:GetNumItems() > 1 then
		needOpen = false
		return
	end
	local now = GetTimeSinceStart()
	if now - openSince < 0.4 then return end
	openSince = now
	openTries = openTries + 1
	if openTries > 4 then
		needOpen = false   -- (a list with one song never has more than one item)
		return
	end
	if wheel.SetOpenSection then
		Trace("Filter: opening the list '" .. name .. "' (try " .. openTries .. ", items " .. wheel:GetNumItems() .. ")")
		wheel:SetOpenSection(name)
	end
end

-- What the main list was built for. The list is kept between visits to the select music screen, but it depends on the
-- style (single / double / versus...: the charts are the ones of that steps type), the players (the scores), the
-- language (the order), the filter and the songs: when any of them changed it has to be built again.
local builtKey
local function BuildKey()
	local style = GAMESTATE:GetCurrentStyle()
	local language = ThemePrefs and ThemePrefs.Get and ThemePrefs.Get("Language") or ""
	return table.concat({ signature, stamp, style and style:GetStepsType() or "", #GAMESTATE:GetEnabledPlayers(),
		tostring(language), SONGMAN:GetNumSongs() }, "|")
end

function Filter.NeedsRebuild()
	return builtKey ~= BuildKey()
end

-- The wheel changes sort a moment AFTER ChangeSort is called, and a ChangeSort to the sort that is already on does
-- nothing (a second ChangeSort in the same frame is ignored too). All the theme's lists use the engine's Preferred
-- sort, so a new list is shown by going through another sort first and finishing from Filter.Poll once it is on.
local pendingApply, pendingSince
-- After the list is applied the sort is checked: if the wheel did not end up on the Preferred sort (the engine ignores
-- a ChangeSort while the wheel is still busy) it is applied again.
local verifyApply, verifySince, verifyTries

local function TopWheel()
	local screen = SCREENMAN:GetTopScreen()
	return screen and screen.GetMusicWheel and screen:GetMusicWheel() or nil
end

local function Settled(wheel)
	if wheel.IsSettled and not wheel:IsSettled() then return false end
	if wheel.IsLocked and wheel:IsLocked() then return false end
	return true
end

local function Run(wheel, apply)
	apply(wheel)
	verifyApply, verifySince, verifyTries = apply, GetTimeSinceStart(), 1
end

local function RunApply(wheel, apply)
	-- No hop and no ChangeSort: the lists are only WRITTEN (the wheel passed in is a stand-in, see Filter.Prepare)
	-- and the select music screen is loaded again, so the wheel is built once, with one animation and one sound.
	apply(wheel)
end

-- A wheel that does nothing: the list functions of SongOrder and LevelSort write the list and then ask the wheel to
-- change sort; here only the writing is wanted.
local STAND_IN_WHEEL = { ChangeSort = function() return true end }

-- Writes the list for the sort that is on screen, with the filter, and gives it to the engine. The caller loads the
-- select music screen again to show it.
function Filter.Prepare()
	Filter.Reapply(STAND_IN_WHEEL)
end

-- Builds the wheel again for the sort that is on screen, with the filter. `wheel` is the MusicWheel.
function Filter.Reapply(wheel)
	if not wheel then return end
	Trace("Filter.Reapply: sort = " .. tostring(GAMESTATE:GetSortOrder()) .. ", filter = '" .. signature .. "'")

	local apply
	if LevelSort and LevelSort.ApplyFlat and (signature ~= "" or Filter.FlatByDefault) then
		-- A filter is ONE list, whatever the group (the arcade does the same): the songs that fit in alphabetical
		-- order, a song once per matching chart. It uses the machinery of the LEVEL sort (the wheel rows that stand
		-- for a chart), with a single section.
		apply = function(w)
			local entries, chartMode = Filter.Entries()
			-- (the name of the only section: the folder when there is only a folder, FILTER when categories are chosen)
			local title = Filter.CategoriesActive() and "FILTER" or Filter.FolderName()
			local name = string.format("%s (%d %s)", title, #entries, chartMode and "CHARTS" or "SONGS")
			if LevelSort.ApplyFlat(w, entries, name) then
				levelByFilter = true
				builtKey = BuildKey()
				-- the list has a NEW name (it holds the folder and the count): the engine only opens a section by itself
				-- when it has the current song, so the wheel is asked to open it (Filter.EnsureOpen)
				Filter.SectionName = name
				Filter.RequestOpen()
				-- The engine builds the wheel OPEN when the current song is in the list. If it is not (another folder),
				-- the first song of the list becomes the current one, so the wheel comes up on a song and not on the
				-- closed header that opens a moment later.
				local current = GAMESTATE:GetCurrentSong()
				local currentDir = current and current:GetSongDir()
				local found = false
				for _, e in ipairs(entries) do
					if e.song:GetSongDir() == currentDir then found = true break end
				end
				if not found and entries[1] then GAMESTATE:SetCurrentSong(entries[1].song) end
			else
				levelByFilter = false
				LevelSort.RestorePreferred()
				w:ChangeSort("SortOrder_Preferred")
			end
		end
	elseif levelByFilter and LevelSort then
		-- the filter was removed: back to the series (GROUP) list
		levelByFilter = false
		LevelSort.RestorePreferred()
		apply = function(w)
			if not (SongOrder and SongOrder.ApplyGroup(w)) then w:ChangeSort("SortOrder_Preferred") end
		end
	elseif LevelSort and LevelSort.Loaded then
		apply = function(w)
			if not LevelSort.Apply(w) then
				LevelSort.RestorePreferred()
				w:ChangeSort("SortOrder_Preferred")
			end
		end
	elseif SongOrder and SongOrder.GroupMode and SongOrder.Mode == "Group" then
		apply = function(w) SongOrder.ApplyGroup(w) end
	elseif SongOrder and SongOrder.GroupMode and SongOrder.Mode then
		local mode = SongOrder.Mode
		apply = function(w) SongOrder.ApplySorted(w, mode) end
	else
		-- the series list (also what the engine's own sorts turn into when a filter is on)
		apply = function(w)
			if SongOrder then
				SongOrder.GroupMode = false
				SongOrder.Mode = nil
				SongOrder.Apply(true)
			end
			w:ChangeSort("SortOrder_Preferred")
		end
	end

	RunApply(wheel, apply)
end
-- ---------------------------------------------------------------------------
-- Chart selection: with a chart filter the cursor lands on a chart that fits (the arcade does this too)
-- ---------------------------------------------------------------------------

local lastSong, tries = nil, 0
local POLL_FRAMES = 12   -- the engine can change the steps again right after the song changes: they are checked for a while

-- Asks the select music screen to load itself again as soon as it is the top screen (the sort menu closed).
-- Opens the folder screen from the music wheel (UP + DOWN, see CodeFolderMenu in metrics.ini). It is the sort menu
-- screen with a flag that makes it show the folder screen. Not in an extra stage or a course, and not while the
-- difficulty selection or the options menu is open.
function Filter.OpenFolderScreen()
	if not Filter.FlatByDefault or GAMESTATE:IsCourseMode() then return end
	local extra = false
	pcall(function() extra = GAMESTATE:IsExtraStage() or GAMESTATE:IsExtraStage2() end)
	if extra or getenv("DDRWORLD_InDiff") or getenv("DDRWORLD_POMenuOpen") then return end
	local screen = SCREENMAN:GetTopScreen()
	if not screen or screen:GetName() ~= "ScreenSelectMusic" then return end
	setenv("DDRWORLD_OpenFolder", true)
	SCREENMAN:AddNewScreenToTop("ScreenSortList")
end

-- The music of the folder screen: the menu music of the select music screen, in place of the preview of the song the
-- cursor was on. From a song the preview kept playing, and after about half a second the select music screen (that is
-- still alive under this one) started the preview of the current song again. So while the folder screen is open there
-- is no current song (it is kept in `savedSong` and given back when the screen closes) and the preview is stopped.
local savedSong
local MENU_MUSIC = "music (loop)"

function Filter.PlayMenuMusic()
	pcall(function()
		savedSong = GAMESTATE:GetCurrentSong()
		GAMESTATE:SetCurrentSong(nil)
		SOUND:StopMusic()
		SOUND:PlayMusicPart(THEME:GetPathS("ScreenSelectMusic", MENU_MUSIC), 0, 16, 0.3, 0.3, true, false)
	end)
end

-- Called by the folder screen now and then: if the preview of the wheel started again anyway, the menu music is put back.
function Filter.KeepMenuMusic()
	pcall(function()
		if not SOUND.GetPlayingMusicFile then return end
		local playing = SOUND:GetPlayingMusicFile()
		local wanted = THEME:GetPathS("ScreenSelectMusic", MENU_MUSIC)
		if playing and playing ~= "" and not string.find(string.lower(playing), "music %(loop%)") then
			SOUND:PlayMusicPart(wanted, 0, 300, 0.3, 0.3, true, false)
		end
	end)
end

-- The folder screen is closing: the song the cursor was on is the current one again.
function Filter.RestoreSong()
	pcall(function()
		if savedSong and not GAMESTATE:GetCurrentSong() then GAMESTATE:SetCurrentSong(savedSong) end
	end)
end

-- The folder screen closed without a change: the preview of the song under the cursor comes back.
function Filter.ResumePreview()
	pcall(function()
		local song = GAMESTATE:GetCurrentSong()
		if song and song:GetMusicPath() then
			SOUND:PlayMusicPart(song:GetMusicPath(), song:GetSampleStart(), song:GetSampleLength(), 0.5, 1.5, true, true)
		end
	end)
end
function Filter.RequestReload()
	reloadPending = true
end

-- Call every frame while the wheel is on screen.
function Filter.Poll()
	if reloadPending then
		local screen = SCREENMAN:GetTopScreen()
		if screen and screen:GetName() == "ScreenSelectMusic" then
			reloadPending = false
			-- The list that is open is closed before the screen loads again (START on a button of the wheel does this by
			-- itself, the combinations LEFT+RIGHT / UP+DOWN do not). The new wheel is then built closed and
			-- Filter.OpenAtStart opens it. Left open, the engine remembered the name of the OLD list, which is not in the new
			-- one, and the wheel came up empty (or with the header repeated all over it).
			local wheel = TopWheel()
			if wheel and wheel.SetOpenSection and wheel:GetNumItems() > 1 then
				pcall(function() wheel:SetOpenSection("") end)
			end
			Filter.RequestOpen()
			setenv("DDRWORLD_FilterReload", GetTimeSinceStart())   -- no doors (BGAnimations/ScreenSelectMusic in.lua)
			Trace("Filter: loading the select music screen again")
			SCREENMAN:SetNewScreen("ScreenSelectMusic")
			return
		end
	end
	if pendingApply then
		local wheel = TopWheel()
		-- the other sort is on and the wheel is quiet (or it never came: do it anyway after a while)
		if wheel and ((GAMESTATE:GetSortOrder() ~= "SortOrder_Preferred" and Settled(wheel))
				or GetTimeSinceStart() - pendingSince > 4) then
			local apply = pendingApply
			pendingApply = nil
			Trace("Filter: finishing the sort change, sort = " .. tostring(GAMESTATE:GetSortOrder()))
			Run(wheel, apply)
		end
	end

	if verifyApply then
		local wheel = TopWheel()
		if wheel then
			if GAMESTATE:GetSortOrder() == "SortOrder_Preferred" and Settled(wheel) then
				verifyApply = nil
			elseif GetTimeSinceStart() - verifySince > 0.7 then
				if verifyTries >= 4 then
					Trace("Filter: the wheel did not reach the list")
					verifyApply = nil
				else
					verifyTries = verifyTries + 1
					verifySince = GetTimeSinceStart()
					Trace("Filter: applying again (" .. verifyTries .. "), sort = " .. tostring(GAMESTATE:GetSortOrder()))
					verifyApply(wheel)
				end
			end
		end
	end
	if signature == "" or not Filter.HasChartCondition() or (LevelSort and LevelSort.Loaded) then
		lastSong = nil
		return
	end

	local song = GAMESTATE:GetCurrentSong()
	if not song then
		lastSong = nil
		return
	end
	if song ~= lastSong then
		lastSong, tries = song, 0
	end
	tries = tries + 1
	if tries > POLL_FRAMES then return end

	local idx = BuildIndex()
	local info = idx.byDir[song:GetSongDir()]
	if not info then return end

	for _, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		local current = GAMESTATE:GetCurrentSteps(pn)
		local currentDifficulty = current and current:GetDifficulty()

		local fits = false
		for _, chart in ipairs(info.charts) do
			if chart.diff == currentDifficulty then fits = ChartMatches(info, chart) break end
		end

		if not fits then
			-- the matching chart nearest to the difficulty the player is on
			local wanted = DIFFICULTY_ORDER[currentDifficulty or ""] or 3
			local best, bestDistance
			for _, chart in ipairs(info.charts) do
				if ChartMatches(info, chart) then
					local distance = math.abs((DIFFICULTY_ORDER[chart.diff] or 3) - wanted)
					if not best or distance < bestDistance then best, bestDistance = chart, distance end
				end
			end
			if best then
				GAMESTATE:SetCurrentSteps(pn, best.steps)
				GAMESTATE:SetPreferredDifficulty(pn, best.diff)
			end
		end
	end
end
