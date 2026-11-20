-- ============================================================================
-- SONG ORDER: letters / numbers / Japanese titles, in the order of the language (like DDR WORLD)
-- ============================================================================
--   English, Korean   titles that start with a letter, then the ones that start with a number (or symbol), then the ones in
--                     Japanese (kana / kanji)
--   Japanese          the ones in Japanese, then the ones with a letter, then the ones with a number (or symbol)
-- The ARCADE list (the main one) keeps the order of Other/SongManager PreferredSongs.txt (which is NOT modified) inside the
-- Latin part, and the theme writes a second list from it, Other/SongManager DDRWORLD_Order.txt, and gives it to the engine.
-- It is rewritten only when the language or the source list changes. The lists the theme builds itself (Group, Title, Artist,
-- Genre and the Filter results) use TitleClass / ClassRank below.
-- ============================================================================

SongOrder = {}

-- lists already written in this session (mode|language|titles|number of songs): they are not built again
local built = {}
local function BuiltKey(mode, language)
	return mode .. "|" .. language .. "|" .. (PREFSMAN:GetPreference("ShowNativeLanguage") and "native" or "translit") .. "|" .. tostring(SONGMAN:GetNumSongs()) .. "|" .. (Filter and Filter.Signature() or "")
end

local LIST_NAME = "DDRWORLD_Order"
local SOURCE_NAME = "PreferredSongs"
local appliedKey

local function ThemeOtherPath(name)
	local dir = THEME:GetCurrentThemeDirectory()
	if string.sub(dir, 1, 1) ~= "/" then dir = "/" .. dir end
	if string.sub(dir, -1) ~= "/" then dir = dir .. "/" end
	return dir .. "Other/SongManager " .. name .. ".txt"
end

local function ReadFile(path)
	local file = RageFileUtil.CreateRageFile()
	local text
	if file:Open(path, 1) then text = file:Read() end
	file:Close()
	file:destroy()
	return text
end

-- true when the title STARTS in Japanese, like in the arcade: the first letter or number decides, so
-- "SAYONARA☆ディスコライト" is a Latin title and "リスペク風神" a Japanese one. Spaces, punctuation and symbols at the
-- beginning are skipped. Japanese = kana and CJK punctuation (U+3000..U+30FF, UTF-8 E3) or kanji (U+3400..U+9FFF, E3..E9).
-- Hangul and Latin titles are not Japanese.
local function IsJapanese(title)
	if not title then return false end
	for i = 1, #title do
		local b = string.byte(title, i)
		if b >= 227 and b <= 233 then return true end                                   -- kana / kanji lead byte
		if (b >= 48 and b <= 57) or (b >= 65 and b <= 90) or (b >= 97 and b <= 122) then return false end   -- 0-9 A-Z a-z
	end
	return false
end

-- The class of a title, for the order of the lists: 0 = letters (the first character is a letter), 1 = numbers and symbols
-- (the first character is a digit or a symbol, like "3y3s" or "[ ]DENTITY"), 2 = Japanese (see IsJapanese). As in the arcade the
-- first character decides.
local function TitleClass(title)
	if IsJapanese(title) then return 2 end
	title = string.gsub(title or "", "^%s+", "")
	local b = string.byte(title, 1)
	if not b or (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or b >= 128 then return 0 end
	return 1
end

-- The title a song is sorted by. Titles in Japanese (or any title that does not start with an ASCII character) use the
-- romanized title (TITLETRANSLIT), as the engine does. The rest use the title as it is written: some songs carry a TITLETRANSLIT
-- made for another purpose (for example "IX" has TITLETRANSLIT "9", which put it before "A").
local function SortTitle(song)
	local main = song:GetMainTitle() or ""
	local translit = song:GetTranslitMainTitle() or ""
	if IsJapanese(main) then return translit end
	local b = string.byte(string.gsub(main, "^%s+", ""), 1)
	if b and b < 128 then return main end
	return translit
end

SongOrder.SortTitle = SortTitle   -- (the TITLE category of the Filter uses it too)

-- Position of a class in the list: English and Korean = letters, numbers, Japanese; Japanese = Japanese, letters, numbers.
local function ClassRank(class, japaneseFirst)
	if japaneseFirst then return (class + 1) % 3 end
	return class
end
local function SongOfLine(line)
	local key = string.gsub(line, "\\", "/")
	if SONGMAN.FindSong then return SONGMAN:FindSong(key) end
	return nil
end

-- With a filter on, the sections that lost all their songs are not written.
local function DropEmptySections(lines)
	local result, header, body, songs = {}, nil, {}, 0
	local function close()
		if header == nil then
			for _, l in ipairs(body) do result[#result + 1] = l end
		elseif songs > 0 then
			result[#result + 1] = header
			for _, l in ipairs(body) do result[#result + 1] = l end
		end
		header, body, songs = nil, {}, 0
	end
	for _, l in ipairs(lines) do
		if string.sub(l, 1, 3) == "---" then
			close()
			header = l
		else
			body[#body + 1] = l
			if l ~= "" and string.sub(l, 1, 2) ~= "//" and string.sub(l, 1, 1) ~= "#" then songs = songs + 1 end
		end
	end
	close()
	return result
end

-- Writes the ordered list and gives it to the engine. Returns true when the list is in use.
function SongOrder.Apply(force)
	if LevelSort and LevelSort.Loaded then return false end   -- the LEVEL sort has its own list
	if SongOrder.GroupMode then return false end              -- the GROUP list is in use
	local language = ThemePrefs and ThemePrefs.Get and ThemePrefs.Get("Language") or "English"
	local nativeTitles = PREFSMAN:GetPreference("ShowNativeLanguage") and "native" or "translit"
	local key = language .. "|" .. nativeTitles .. "|" .. (Filter and Filter.Signature() or "")
	if not force and appliedKey == key then return true end

	local text = ReadFile(ThemeOtherPath(SOURCE_NAME))
	if not text or text == "" then return false end

	local japaneseFirst = (language == "Japanese")
	local filtering = Filter and Filter.Restricts()
	local out, latin, japanese = {}, {}, {}
	local function flush()
		local first, second = latin, japanese
		if japaneseFirst then first, second = japanese, latin end
		for _, l in ipairs(first) do out[#out + 1] = l end
		for _, l in ipairs(second) do out[#out + 1] = l end
		latin, japanese = {}, {}
	end

	for line in (text .. "\n"):gmatch("(.-)\r?\n") do
		if string.sub(line, 1, 3) == "---" then
			flush()
			out[#out + 1] = line
		elseif line == "" or string.sub(line, 1, 2) == "//" or string.sub(line, 1, 1) == "#" then
			out[#out + 1] = line   -- blank lines and comments stay where they are (end of a group)
		else
			local song = SongOfLine(line)
			if filtering and not (song and Filter.Pass(song)) then
				-- the filter leaves this song out
			elseif song and IsJapanese(song:GetMainTitle()) then
				japanese[#japanese + 1] = line
			else
				latin[#latin + 1] = line
			end
		end
	end
	flush()
	if filtering then out = DropEmptySections(out) end

	local file = RageFileUtil.CreateRageFile()
	if not file:Open(ThemeOtherPath(LIST_NAME), 2) then
		file:destroy()
		return false
	end
	file:Write(table.concat(out, "\n"))
	file:Close()
	file:destroy()
	SONGMAN:SetPreferredSongs(LIST_NAME)
	appliedKey = key
	return true
end

-- The GROUP sort with the same rule. The engine sorts the songs of each group by their romanized title and does not let a
-- theme change that, so the theme builds the list itself (the way the LEVEL sort does) from the engine's own groups and
-- order, moves the Japanese titles, gives it to the engine as the Preferred list and switches the wheel to it.
-- Returns true when the wheel was switched (otherwise the caller uses the engine's Group sort).
local GROUP_LIST = "DDRWORLD_GroupOrder"
SongOrder.GroupMode = false

function SongOrder.ApplyGroup(wheel)
	if not (wheel and SONGMAN.GetSongGroupNames and SONGMAN.GetSongsInGroup) then
		Trace("SongOrder.ApplyGroup: missing wheel or SONGMAN functions")
		return false
	end
	local language = ThemePrefs and ThemePrefs.Get and ThemePrefs.Get("Language") or "English"
	local japaneseFirst = (language == "Japanese")
	local filtering = Filter and Filter.Restricts()
	local key = BuiltKey("Group", language)
	if built.Group == key then
		SongOrder.Mode = "Group"
		SongOrder.GroupMode = true
		SongOrder.ModeLanguage = language
		appliedKey = nil
		SONGMAN:SetPreferredSongs(GROUP_LIST)
		wheel:ChangeSort("SortOrder_Preferred")
		return true
	end
	local lines = {}
	for _, group in ipairs(SONGMAN:GetSongGroupNames()) do
		local buckets = { {}, {}, {} }   -- letters, numbers, Japanese (see ClassRank)
		for _, song in ipairs(SONGMAN:GetSongsInGroup(group) or {}) do
			local folder = string.match(string.gsub(song:GetSongDir(), "/$", ""), "([^/]+)$")
			if folder and (not filtering or Filter.Pass(song)) then
				local item = { line = group .. "/" .. folder,
						-- sorted by romanized title like the engine's own Group sort (GetSongsInGroup is in loading order)
						key = string.upper(SortTitle(song)) .. "\1" .. string.upper(song:GetTranslitSubTitle() or "") }
					table.insert(buckets[ClassRank(TitleClass(song:GetMainTitle()), japaneseFirst) + 1], item)
				end
			end
			if #buckets[1] + #buckets[2] + #buckets[3] > 0 then
				lines[#lines + 1] = "---" .. group
				local function byKey(a, b)
					if a.key ~= b.key then return a.key < b.key end
					return a.line < b.line
				end
				for _, bucket in ipairs(buckets) do table.sort(bucket, byKey) end
				local ordered = {}
				for _, bucket in ipairs(buckets) do for _, it in ipairs(bucket) do ordered[#ordered + 1] = it end end
				for _, it in ipairs(ordered) do lines[#lines + 1] = it.line end
				lines[#lines + 1] = ""
		end
	end
	if #lines == 0 then Trace("SongOrder.ApplyGroup: no lines") return false end

	local file = RageFileUtil.CreateRageFile()
	if not file:Open(ThemeOtherPath(GROUP_LIST), 2) then
		Trace("SongOrder.ApplyGroup: cannot write " .. ThemeOtherPath(GROUP_LIST))
		file:destroy()
		return false
	end
	Trace("SongOrder.ApplyGroup: writing " .. #lines .. " lines")
	file:Write(table.concat(lines, "\n"))
	file:Close()
	file:destroy()
	built.Group = key
	SongOrder.Mode = "Group"
	SongOrder.GroupMode = true
	SongOrder.ModeLanguage = language
	appliedKey = nil   -- the Arcade list has to be written again when it is needed
	SONGMAN:SetPreferredSongs(GROUP_LIST)
	wheel:ChangeSort("SortOrder_Preferred")
	return true
end

-- The TITLE, ARTIST and GENRE sorts with the same rule. The sections are the engine's own (SongUtil::
-- GetSectionNameFromSongAndSort: the first letter of the romanized title or artist, "0-9", "OTHER", or the genre) and so
-- is the order of the songs inside each one (by romanized title). The sections go letters, then "0-9", then "OTHER"; inside
-- a section the songs go by class (letters, numbers, Japanese; Japanese first in the Japanese language). No section is added:
-- the songs in Japanese stay in the section of their romanized title, at its end (or its beginning).
local function SectionName(song, mode)
	if mode == "Genre" then
		local genre = song.GetGenre and song:GetGenre() or ""
		if genre == "" then return "NOT AVAILABLE" end
		return genre
	end
	local s = (mode == "Artist") and song:GetTranslitArtist() or SortTitle(song)
	s = string.upper(s or "")
	local c = string.sub(s, 1, 1)
	if c == "" then return "OTHER" end
	if string.find(c, "%d") then return "0-9" end
	if string.find(c, "%u") then return c end
	return "OTHER"
end

local function SectionRank(name)
	if name == "0-9" then return 1 end    -- letters, then numbers, then the rest (like the arcade)
	if name == "OTHER" then return 2 end
	return 0
end

function SongOrder.ApplySorted(wheel, mode)
	if not (wheel and SONGMAN.GetAllSongs) then return false end
	local language = ThemePrefs and ThemePrefs.Get and ThemePrefs.Get("Language") or "English"
	local japaneseFirst = (language == "Japanese")
	local filtering = Filter and Filter.Restricts()

	local key = BuiltKey(mode, language)
	if built[mode] == key then
		SongOrder.Mode = mode
		SongOrder.GroupMode = true
		SongOrder.ModeLanguage = language
		appliedKey = nil
		SONGMAN:SetPreferredSongs("DDRWORLD_" .. mode .. "Order")
		wheel:ChangeSort("SortOrder_Preferred")
		return true
	end

	local sections, names = {}, {}
	for _, song in ipairs(SONGMAN:GetAllSongs()) do
		local dir = string.gsub(song:GetSongDir(), "/$", "")
		local folder = string.match(dir, "([^/]+)$")
		if folder and (not filtering or Filter.Pass(song)) then
			local name = SectionName(song, mode)
			local section = sections[name]
			if not section then
				section = { {}, {}, {} }   -- letters, numbers, Japanese (see ClassRank)
				sections[name] = section
				names[#names + 1] = name
			end
			local title = string.upper(SortTitle(song))
			local key = title
			if mode == "Artist" then key = string.upper(song:GetTranslitArtist() or "") .. "\1" .. title end
			local item = { line = song:GetGroupName() .. "/" .. folder, key = key }
			table.insert(section[ClassRank(TitleClass(song:GetMainTitle()), japaneseFirst) + 1], item)
		end
	end

	local function byKey(a, b)
		if a.key ~= b.key then return a.key < b.key end
		return a.line < b.line
	end
	table.sort(names, function(a, b)
		local ra, rb = SectionRank(a), SectionRank(b)
		if ra ~= rb then return ra < rb end
		return string.upper(a) < string.upper(b)
	end)

	local lines = {}
	for _, name in ipairs(names) do
		local section = sections[name]
		for _, part in ipairs(section) do table.sort(part, byKey) end
		lines[#lines + 1] = "---" .. name
		for _, part in ipairs(section) do for _, item in ipairs(part) do lines[#lines + 1] = item.line end end
		lines[#lines + 1] = ""
	end
	if #lines == 0 then return false end

	local file = RageFileUtil.CreateRageFile()
	if not file:Open(ThemeOtherPath("DDRWORLD_" .. mode .. "Order"), 2) then
		file:destroy()
		return false
	end
	file:Write(table.concat(lines, "\n"))
	file:Close()
	file:destroy()
	built[mode] = key
	SongOrder.Mode = mode
	SongOrder.GroupMode = true
	SongOrder.ModeLanguage = language
	appliedKey = nil
	SONGMAN:SetPreferredSongs("DDRWORLD_" .. mode .. "Order")
	wheel:ChangeSort("SortOrder_Preferred")
	return true
end

function SongOrder.ApplyTitle(wheel) return SongOrder.ApplySorted(wheel, "Title") end
-- Sort key of a song for lists the theme builds from songs of any group (the filter): the same order as the lists
-- above: letters, numbers, Japanese (Japanese, letters, numbers in the Japanese language), then the romanized title and subtitle.
function SongOrder.OrderKey(song)
	local language = ThemePrefs and ThemePrefs.Get and ThemePrefs.Get("Language") or "English"
	local rank = ClassRank(TitleClass(song:GetMainTitle()), language == "Japanese")
	return rank .. string.upper(SortTitle(song)) .. "\1" .. string.upper(song:GetTranslitSubTitle() or "")
end

-- Back to this list after the LEVEL sort (which uses its own).
function SongOrder.Restore()

	appliedKey = nil
	SongOrder.GroupMode = false
	SongOrder.Mode = nil
	if not SongOrder.Apply(true) then SONGMAN:SetPreferredSongs(SOURCE_NAME) end
end
