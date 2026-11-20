-- coming back from the difficulty selection with ESC (TwoPartDiff): the wheel only fades in and the panels slide in
local backToWheel = (function() local v = getenv("DDRWORLD_BackToWheel"); return type(v) == "number" and GetTimeSinceStart() - v < 1.5 end)()

if backToWheel then setenv("DDRWORLD_ReturnedFromDiff", GetTimeSinceStart()) end

-- a new select music screen: the difficulty selection is not open (see Screen cancel.lua)
setenv("DDRWORLD_InDiff", nil)
setenv("DDRWORLD_POMenuOpen", nil)

-- scores may have changed since the last time this screen was shown (a song was played): forget the cached ones
WheelCache.Reset()
if Filter then Filter.Touch() end   -- the filter lists that depend on scores are built again

-- EXTRA STAGE: the engine builds this wheel in its own way (it looks for the extra stage song) and it crashed with
-- the filter's single list ("Assertion data.size() != 0" in WheelBase). In an extra stage the theme goes back to the
-- plain arcade list of before the filter (the one the engine was always tested with) and the filter list is built again
-- on the next normal stage.
local isExtraStage = false
do
	local ok, value = pcall(function() return GAMESTATE:IsExtraStage() or GAMESTATE:IsExtraStage2() end)
	isExtraStage = ok and value and true or false
	Trace("Extra stage check: extra = " .. tostring(isExtraStage) .. ", sort = " .. tostring(GAMESTATE:GetSortOrder())
		.. ", section = " .. tostring(GAMESTATE:GetExpandedSectionName()))
end
if isExtraStage then
	-- The extra stage used to force 4 lives (metrics.ini). Now the player chooses the gauge in the options menu
	-- (FLARE, FLOATING FLARE, LIFE4 or RISKY); whoever has not chosen one (NORMAL) gets the arcade default:
	-- LIFE4 in the first extra stage, RISKY in the second.
	for _, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		pcall(function()
			local flare = POMenu and POMenu.FlareLevel and POMenu.FlareLevel(pn) or 0
			local life = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred"):LifeSetting()
			if flare <= 0 and life ~= "LifeType_Battery" then
				local lives = GAMESTATE:IsExtraStage2() and "1 lives" or "4 lives"
				GAMESTATE:ApplyPreferredModifiers(pn, lives .. ",battery,failimmediate")
				Trace("Extra stage: " .. tostring(pn) .. " had the normal gauge, now " .. lives)
			end
		end)
	end
	if LevelSort then LevelSort.Loaded = false end
	if SongOrder then
		-- The sections of the list are the real group folders ("17 - DDR A20"), like the engine's own GROUP sort: in an
		-- extra stage the engine opens the group of the extra stage song BY NAME, and with this wheel (it only shows
		-- the open section) a name that is not a section leaves the wheel with no items at all. The arcade list
		-- names its sections "DDR A20" and the single list "ALL MUSIC (...)", so neither matches.
		local standIn = { ChangeSort = function() return true end }   -- only the list is written; the wheel is built after
		SongOrder.GroupMode = false
		SongOrder.Mode = nil
		local ok = SongOrder.ApplyGroup and SongOrder.ApplyGroup(standIn)
		Trace("Extra stage: group list written = " .. tostring(ok))
		if not ok then SongOrder.Apply(true) end
	end
	local group, count = "?", "?"
	pcall(function() group = GAMESTATE:GetPreferredSongGroup() end)
	pcall(function() count = #SONGMAN:GetPreferredSortSongs() end)
	Trace("Extra stage: preferred group = " .. tostring(group) .. ", songs in the preferred list = " .. tostring(count)
		.. ", current song = " .. tostring(GAMESTATE:GetCurrentSong() and GAMESTATE:GetCurrentSong():GetSongDir()))
end

-- songs with Latin/romanized titles first or last depending on the language (Scripts/08 SongOrder.lua)
local flatPending = false
if isExtraStage then
	-- (nothing: the plain list was just written above)
elseif Filter and Filter.FlatByDefault and LevelSort and LevelSort.ApplyFlat and not GAMESTATE:IsCourseMode() then
	-- The main sort is the filter's single list (Scripts/08 Filter.lua). It is kept between visits to this screen;
	-- it is built the first time, when the wheel exists (OnCommand below).
	if LevelSort.Loaded and GAMESTATE:GetSortOrder() == "SortOrder_Preferred" then
		-- kept between visits, but written again when the style, the players, the language or the songs changed
		-- (here, before the wheel exists: it is then built from the new list)
		if Filter.NeedsRebuild() then
			Trace("Filter: the main list is out of date (style, players, language or songs changed): building it again")
			Filter.Prepare()
		end
	else
		flatPending = true
	end
elseif SongOrder then
	local sort = GAMESTATE:GetSortOrder()
	Trace("SongOrder: entering select music, sort order = " .. tostring(sort) .. ", language = " .. tostring(ThemePrefs.Get("Language")))
	local language = ThemePrefs.Get("Language")
	if sort == nil or sort == "SortOrder_Invalid" then
		-- first time on this screen: the engine has not chosen a sort yet and will open on Group
		SongOrder.PendingGroup = "Group"
	elseif sort == "SortOrder_Group" or sort == "SortOrder_Title" or sort == "SortOrder_Artist" or sort == "SortOrder_Genre" then
		-- the Group or Title sort is the one on screen: it is replaced by the language-ordered one as soon as the wheel exists
		SongOrder.PendingGroup = string.gsub(sort, "SortOrder_", "")
	elseif SongOrder.GroupMode and SongOrder.Mode and SongOrder.ModeLanguage ~= language then
		-- the list of the sort in use was written for another language: it is written again
		SongOrder.PendingGroup = SongOrder.Mode
	else
		SongOrder.Apply()
	end
end

local t = Def.ActorFrame{
	OnCommand=function(self)
		MESSAGEMAN:Broadcast("WheelPanelShow")   -- the dark panel behind the wheel (background.lua) is shown
		do
			local screen = SCREENMAN:GetTopScreen()
			local wheel = screen and screen.GetMusicWheel and screen:GetMusicWheel()
			Trace("ScreenSelectMusic start: back = " .. tostring(backToWheel) .. ", items = " .. tostring(wheel and wheel:GetNumItems())
				.. ", open = '" .. tostring(GAMESTATE:GetExpandedSectionName()) .. "', song = "
				.. tostring(GAMESTATE:GetCurrentSong() ~= nil))
		end
		if backToWheel then setenv("DDRWORLD_BackToWheel", nil) end
		if flatPending then
			-- the main sort: one list with every song of the packs without itg.ini (see Filter.Reapply)
			flatPending = false
			local screen = SCREENMAN:GetTopScreen()
			local wheel = screen and screen.GetMusicWheel and screen:GetMusicWheel()
			Trace("Filter: building the main list, wheel = " .. tostring(wheel))
			if wheel then Filter.Reapply(wheel) end
		end
		if SongOrder and SongOrder.PendingGroup then
			local which = SongOrder.PendingGroup
			SongOrder.PendingGroup = false
			local screen = SCREENMAN:GetTopScreen()
			local wheel = screen and screen.GetMusicWheel and screen:GetMusicWheel()
			local done = false
			Trace("SongOrder: applying " .. tostring(which) .. ", wheel = " .. tostring(wheel))
			if wheel and which == "Group" then done = SongOrder.ApplyGroup(wheel)
			elseif wheel then done = SongOrder.ApplySorted(wheel, which) end
			Trace("SongOrder: " .. tostring(which) .. " applied = " .. tostring(done))
			if not done then SongOrder.Apply() end
		end
		do
			-- a list that came up closed (only its header) is opened before the intro shows anything
			local screen = SCREENMAN:GetTopScreen()
			local wheel = screen and screen.GetMusicWheel and screen:GetMusicWheel()
			if wheel and Filter and Filter.OpenAtStart then Filter.OpenAtStart(wheel) end
		end
		MESSAGEMAN:Broadcast("WheelOrdered")   -- the wheel intro animation uncovers the cells
		if backToWheel then
			local screen = SCREENMAN:GetTopScreen()
			local wheel = screen and screen:GetChild("MusicWheel")
			if wheel then wheel:stoptweening():diffusealpha(0):linear(0.15):diffusealpha(1) end
			-- (the panels on the left are already on screen in the difficulty selection: they are not animated)
		end
	end,
}

local storedStyle = getenv("ForceStyle")
if storedStyle then
  GAMESTATE:SetCurrentStyle(storedStyle)
  setenv("ForceStyle", nil)
end


-- panels on the left come back sliding in from the left when the options menu closes (like the original)
local function SlideUpIn(s,pn)
	s.baseX = s.baseX or s:GetX()
	-- no stoptweening(): the panels queue their own "Set" command on themselves and it would be lost
	local p = pn == PLAYER_1 and -1 or 1
	s:x(s.baseX + SCREEN_WIDTH * 0.15 * p):decelerate(0.15):x(s.baseX)
end

local TwoPart = Def.ActorFrame{
	StartSelectingStepsMessageCommand=function(s) 
		setenv("DDRWORLD_InDiff", true)
		s:AddChildFromPath(THEME:GetPathB("ScreenSelectMusic","overlay/TwoPartDiff")) 
	end,
	SongUnchosenMessageCommand=function(s) 
		setenv("DDRWORLD_InDiff", nil)
		s:sleep(0.2):queuecommand("Remove")
	end,
	RemoveCommand=function(s) s:RemoveChild("TwoPartDiff") end,
};

for _,pn in pairs(GAMESTATE:GetEnabledPlayers()) do
	t[#t+1] = loadfile(THEME:GetPathB("ScreenSelectMusic","overlay/Difficulty"))(pn)..{
		InitCommand=function(s) s:y(16) end,
		POMenuOpenedMessageCommand=function(s) s:visible(false) end,
		POMenuClosingMessageCommand=function(s) s:visible(true); SlideUpIn(s,pn) end,
		-- the filter menu (ScreenSortList overlay) hides the panels and shows them again at once
		FilterOpenedMessageCommand=function(s) s:visible(false) end,
		FilterClosedMessageCommand=function(s) s:visible(true) end,
	};
	t[#t+1] = loadfile(THEME:GetPathB("ScreenSelectMusic","overlay/TargetScore/default.lua"))(pn)..{
		POMenuOpenedMessageCommand=function(s) s:visible(false) end,
		POMenuClosingMessageCommand=function(s) s:visible(true); SlideUpIn(s,pn) end,
		FilterOpenedMessageCommand=function(s) s:visible(false) end,
		FilterClosedMessageCommand=function(s) s:visible(true) end,
	};
end
-- FOLDER screen (Scripts/08 Filter.lua, BGAnimations/ScreenSortList overlay/folder.lua). It opens
--   * from the wheel: START on the header of the list (the "Change folder" card), and
--   * by itself on the first stage of a new profile (or a guest), once each time the game starts.
-- It is the sort menu screen with a flag that makes it open the folder screen instead of the filter.
local function OpenFolderScreen()
	setenv("DDRWORLD_OpenFolder", true)
	SCREENMAN:AddNewScreenToTop("ScreenSortList")
end

-- the filter menu: the sort menu screen opens it by itself when no folder is asked for (ScreenSortList overlay)
local function OpenFilterScreen()
	setenv("DDRWORLD_OpenFolder", nil)
	SCREENMAN:AddNewScreenToTop("ScreenSortList")
end

local function FolderAvailable()
	return Filter and Filter.FlatByDefault and Filter.Folders and not isExtraStage and not GAMESTATE:IsCourseMode()
end

local menuOpen = false   -- the options menu is on screen: START belongs to it

local function FolderInput(event)
	if event.type ~= "InputEventType_FirstPress" or event.GameButton ~= "Start" then return false end
	if menuOpen or getenv("DDRWORLD_InDiff") or not FolderAvailable() then return false end
	local screen = SCREENMAN:GetTopScreen()
	if not screen or screen:GetName() ~= "ScreenSelectMusic" then return false end
	local wheel = screen.GetMusicWheel and screen:GetMusicWheel()
	if not wheel or wheel:GetNumItems() < 1 then return false end
	if ToEnumShortString(wheel:GetSelectedType()) ~= "Section" then return false end
	if WheelButtons and WheelButtons.Enabled() and WheelButtons.Sel == WheelButtons.FILTER then
		OpenFilterScreen()   -- the FILTER button
	else
		OpenFolderScreen()   -- the "Change folder" button
	end
	return true   -- the wheel must not also open / close the list
end

local function IsNewProfile(pn)
	if not PROFILEMAN:IsPersistentProfile(pn) then return true end
	local profile = PROFILEMAN:GetProfile(pn)
	return profile ~= nil and profile:GetNumTotalSongsPlayed() == 0
end

-- The folder screen is NOT opened by itself any more: a new profile (first session) or a guest starts on the wheel, on the
-- first song of ALL MUSIC (the filter and the folder are cleared for them in the ScreenCaution overlay), like everybody
-- else. To bring the old behaviour back (cursor on the "Change folder" button and the folder screen opening by itself),
-- set OFFER_FOLDER_TO_NEW_PLAYERS to true.
local OFFER_FOLDER_TO_NEW_PLAYERS = false
local newStart = false
if OFFER_FOLDER_TO_NEW_PLAYERS and FolderAvailable() and not backToWheel and not getenv("DDRWORLD_FolderOffered")
		and GAMESTATE:GetCurrentStageIndex() == 0 then
	for _, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		if IsNewProfile(pn) then newStart = true end
	end
end
setenv("DDRWORLD_StartOnButtons", newStart and true or nil)
if newStart and WheelButtons then WheelButtons.Sel = WheelButtons.FOLDER end

-- A new profile (first session) or a guest starts on the FIRST SONG OF THE LIST (ALL MUSIC, in the theme's order), not
-- on the song the engine would pick (the first song of the first pack). The list is the one the filter builds
-- (Filter.Entries, the same order the wheel shows), so the theme always knows which song is first. It is given to the
-- engine here, while the screen is being built: the wheel chooses its starting song a moment later. Once per game
-- (DDRWORLD_FolderOffered is cleared in the ScreenCaution overlay).
if not OFFER_FOLDER_TO_NEW_PLAYERS and FolderAvailable() and not backToWheel and not getenv("DDRWORLD_FolderOffered")
		and GAMESTATE:GetCurrentStageIndex() == 0 then
	local newPlayer = false
	for _, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		if IsNewProfile(pn) then newPlayer = true end
	end
	if newPlayer then
		setenv("DDRWORLD_FolderOffered", true)
		local ok, entries = pcall(function() return Filter.Entries() end)
		local first = ok and entries and entries[1] and entries[1].song
		if first then
			Trace("New player: starting on the first song of the list: " .. tostring(first:GetDisplayMainTitle()))
			GAMESTATE:SetPreferredSong(first)
			GAMESTATE:SetCurrentSong(first)
		end
	end
end

t[#t+1] = Def.Actor{
	OnCommand=function(self)
		local screen = SCREENMAN:GetTopScreen()
		if screen and screen.AddInputCallback then screen:AddInputCallback(FolderInput) end
		if newStart then
			setenv("DDRWORLD_FolderOffered", true)
			self:sleep(0.6):queuecommand("OfferFolder")
		end
	end,
	OfferFolderCommand=function(self)
		local screen = SCREENMAN:GetTopScreen()
		if screen and screen:GetName() == "ScreenSelectMusic" then OpenFolderScreen() end
	end,
	POMenuOpenedMessageCommand=function() menuOpen = true; setenv("DDRWORLD_POMenuOpen", true) end,
	POMenuClosingMessageCommand=function() menuOpen = false; setenv("DDRWORLD_POMenuOpen", nil) end,
}

-- LEVEL sort helper (Scripts/08 LevelSort.lua): fills the level under the cursor, selects the chart of that level
t[#t+1] = loadfile(THEME:GetPathB("ScreenSelectMusic","overlay/LevelSort.lua"))()

-- entry animation of the wheel: it decides WHEN it plays (the cards animate themselves, see Scripts/08 WheelLayout.lua); the
-- wheel stays hidden until it starts, which also hides the song ordering
t[#t+1] = loadfile(THEME:GetPathB("ScreenSelectMusic","overlay/WheelIntro.lua"))(backToWheel)

t[#t+1] = loadfile(THEME:GetPathB("ScreenSelectMusic","overlay/StageDisplay"))()..{
	OnCommand=function(s) s:diffusealpha(1) end,
};

t[#t+1] = loadfile(THEME:GetPathB("ScreenSelectMusic","overlay/Info"))()..{
	FilterOpenedMessageCommand=function(s) s:visible(false) end,
	FilterClosedMessageCommand=function(s) s:visible(true) end,
};
-- the menu timer, drawn with the original's digits (red from 10); see Timer/default.lua
t[#t+1] = DDRWORLD_MenuTimer("ScreenSelectMusic", MenuTimerPositions.SelectMusic.x, MenuTimerPositions.SelectMusic.y);

return Def.ActorFrame{
	OffCommand=function(s) s:finishtweening() end,
	TwoPart;
	t;
}