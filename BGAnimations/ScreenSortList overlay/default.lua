local steps = GAMESTATE:GetCurrentSteps(GAMESTATE:GetMasterPlayerNumber())
local timer = SCREENMAN:GetTopScreen():GetChild("Timer"):GetSeconds()


local sortorders = {
	"Title",
	"Genre",
	"Group",
	"Artist",
	"TopGrades",
	"BPM",
	"EasyMeter",
	"Popularity",
	"Length",
	"Preferred",
	"Filter",      -- opens the filter menu (Scripts/08 Filter.lua, filter.lua)
	"FilterOff",   -- turns the filter off
}
-- true: the old sort list (TITLE, GENRE, GROUP, ARTIST, BPM...) opens first and FILTER is one of its entries.
-- false: the FILTER menu opens directly (as in DDR WORLD) and the old sort list is not shown.
local SORT_LIST_ENABLED = false

local mw = SCREENMAN:GetTopScreen():GetChild("MusicWheel")
local curIndex = 1;
local filterOpen = false     -- the filter menu is on screen: it gets the buttons
local filterSignature = ""   -- the filter when the menu opened (the wheel is only built again if it changed)
local gridActor              -- the sort list, hidden while the filter menu is open
local dimActor               -- the dark layer behind the menus
local folderOpen = false     -- the folder screen is on screen (it also gets the buttons)

-- Opens the filter menu: the wheel and the panels of the select music screen go away at once (the original does the
-- same), and the menu fades in over the dimmed background.
local function OpenFilter()
	if filterOpen then return end
	filterOpen = true
	filterSignature = Filter.Signature()
	Filter.Snapshot()   -- (put back by RestoreSnapshot when the menu timer runs out)
	MESSAGEMAN:Broadcast("FilterOpened")
	if gridActor then gridActor:visible(false) end
	FilterMenu.Open()
end

-- The filter menu closed with a filter: the wheel is built again for the sort on screen.
local function CloseFilter()
	filterOpen = false
	Trace("CloseFilter: changed = " .. tostring(Filter.Signature() ~= filterSignature))
	if Filter.Signature() ~= filterSignature then
		-- The engine ignores a change to the sort that is already on, and going through another sort plays the
		-- animation and the sound twice. So the list is only written and the select music screen is loaded again:
		-- the wheel is built once, with the new list (and the entry animation of the wheel plays once).
		-- (the sort menu is a screen on top of the select music screen: it only closes here, and the select music
		-- screen loads itself again once it is the top screen, see Filter.Poll)
		Filter.Prepare()
		Filter.RequestReload()
		MESSAGEMAN:Broadcast("FilterClosed")   -- (the background is kept when the screen loads again: the dark panel comes back)
		SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
		return
	end
	Filter.RequestOpen()   -- (START on the FILTER button of the wheel also reached the engine, which closed the list)
	MESSAGEMAN:Broadcast("FilterClosed")   -- the wheel and the panels are shown again
	SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
end

-- Opens the folder screen (FIRST STEP, POP MUSIC, ...): like the filter menu it replaces the wheel and the panels, but
-- the background is not dimmed (the original shows it as it is).
local function OpenFolder()
	if folderOpen then return end
	folderOpen = true
	MESSAGEMAN:Broadcast("FolderOpened")
	filterSignature = Filter.Signature()
	MESSAGEMAN:Broadcast("FilterOpened")
	if gridActor then gridActor:visible(false) end
	if dimActor then dimActor:visible(false) end
	--Filter.PlayMenuMusic(15.9)   -- the preview of the song the cursor was on stops: the menu music plays
	FolderMenu.Open()
end

-- The folder screen closed: if the folder changed the wheel is built again, like after the filter menu.
local function CloseFolder(chosen)
	folderOpen = false
	MESSAGEMAN:Broadcast("FolderClosed")
	Trace("CloseFolder: changed = " .. tostring(Filter.Signature() ~= filterSignature) .. ", chosen = " .. tostring(chosen))
	-- CHOOSING a folder (START) always starts from its first song, even when it is the folder that was already on: the
	-- wheel is built again with no current song, so that the list opens with the cursor on the header and LevelSort.lua
	-- moves it on to the first song. (This is what makes the folder screen, which opens from the buttons and with UP, DOWN
	-- from anywhere, a way back to the start of the list.) BACK leaves everything as it was.
	if chosen then
		pcall(function() GAMESTATE:SetCurrentSong(nil) end)
	else
		Filter.RestoreSong()   -- the song the cursor was on is the current one again (see Filter.PlayMenuMusic)
	end
	if chosen or Filter.Signature() ~= filterSignature then
		Filter.Prepare()
		Filter.RequestReload()
		-- (the select music screen is loaded again but its background is kept, with the dark panel hidden by FilterOpened)
		MESSAGEMAN:Broadcast("FilterClosed")
		SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
		return
	end
	Filter.RequestOpen()   -- the engine closed the list when START was pressed on its header
	Filter.ResumePreview()   -- (nothing changed: the song under the cursor sounds again)
	MESSAGEMAN:Broadcast("FilterClosed")
	SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
end

-- The menu timer ran out while the filter or the folder screen was open (the mirror of the timer calls this, see
-- ScreenSelectMusic overlay/Timer/default.lua): the menu closes WITHOUT applying what was changed (the filter is put back as it
-- was when it opened) and the select music screen goes on as if the time had run out on the wheel, with the last song.
local function TimerExpired()
	if not (filterOpen or folderOpen) then return end
	setenv("DDRWORLD_TimerExpired", true)
	if folderOpen then
		FolderMenu.Cancel()
	else
		Filter.RestoreSnapshot()
		FilterMenu.Cancel()
	end
end

-- this handles user input
local function input(event, param)
	if not event.PlayerNumber or not event.button then
		return false
	end

	if folderOpen then
		FolderMenu.Input(event)
		return true
	end

	if filterOpen then
		FilterMenu.Input(event)
		return true   -- the screen must not also act on the button (Back would leave the sort menu)
	end

	if event.type ~= "InputEventType_Release" then
		local overlay = SCREENMAN:GetTopScreen():GetChild("Overlay")
		if event.GameButton == "Start" and sortorders[curIndex] == "Filter" then
			overlay:GetChild("start_sound"):play()
			OpenFilter()
		elseif event.GameButton == "Start" and sortorders[curIndex] == "FilterOff" then
			overlay:GetChild("start_sound"):play()
			filterSignature = Filter.Signature()
			Filter.ClearAll()
			CloseFilter()
		elseif event.GameButton == "Start" then
			overlay:GetChild("start_sound"):play()
			MESSAGEMAN:Broadcast("MusicWheelSort")
			if sortorders[curIndex] == "EasyMeter" then
				-- LEVEL (Scripts/08 LevelSort.lua): songs grouped by level whatever their difficulty, like the arcade.
				-- If that list cannot be built, the engine's sort by the current difficulty is used.
				if not LevelSort.Apply(mw) then
					mw:ChangeSort("SortOrder_"..ToEnumShortString(steps:GetDifficulty()).."Meter")
				end
			elseif sortorders[curIndex] == "Preferred" then
				-- the level sort replaces the Preferred list while it is active: bring the real one back
				LevelSort.RestorePreferred()
				if SongOrder then SongOrder.Restore() end   -- the curated list, with the language order
				mw:ChangeSort("SortOrder_Preferred")
			elseif sortorders[curIndex] == "Group" and SongOrder and SongOrder.ApplyGroup(mw) then
				-- GROUP with the language order (Scripts/08 SongOrder.lua): the wheel is already switched
				if LevelSort then LevelSort.Loaded = false end
			elseif (sortorders[curIndex] == "Title" or sortorders[curIndex] == "Artist" or sortorders[curIndex] == "Genre")
				and SongOrder and SongOrder.ApplySorted(mw, sortorders[curIndex]) then
				if LevelSort then LevelSort.Loaded = false end
			else
				if SongOrder then SongOrder.GroupMode = false; SongOrder.Mode = nil end
				mw:ChangeSort("SortOrder_"..sortorders[curIndex])
			end
			SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
		elseif event.GameButton == "Back" then
			SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
		elseif event.GameButton == "MenuRight" then
			if curIndex >= #sortorders then
				curIndex = 1
			else
				curIndex = curIndex+1
			end
			overlay:GetChild("change_sound"):play()
		elseif event.GameButton == "MenuUp" then
			if curIndex == 1 then
				curIndex = #sortorders-1
			elseif curIndex == 2 then
				curIndex = #sortorders
			else
				curIndex = curIndex - 2
			end
			overlay:GetChild("change_sound"):play()
		elseif event.GameButton == "MenuDown" then
			if curIndex >= #sortorders then
				curIndex = 2
			elseif curIndex >= #sortorders-1 then
				curIndex = 1
			else
				curIndex = curIndex + 2
			end
			overlay:GetChild("change_sound"):play()
		elseif event.GameButton == "MenuLeft" then
			if curIndex == 1 then
				curIndex = #sortorders
			else
				curIndex = curIndex-1
			end
			overlay:GetChild("change_sound"):play()
		end
		MESSAGEMAN:Broadcast("MoveScroller");
	end

	return false
end

local t = Def.ActorFrame{
	Def.Quad{
		InitCommand=function(s) dimActor = s; s:diffuse(color("0,0,0,0.5")):FullScreen() end,
		OnCommand=function(s) s:diffusealpha(0):sleep(0.1):smooth(0.15):diffusealpha(0.6) end,
		OffCommand=function(s) s:linear(0.2):diffusealpha(0) end,
	};
	Def.ActorFrame{
		InitCommand=function(s) gridActor = s; s:zoom(0.667):xy(_screen.cx,_screen.cy-25):queuecommand("Capture") end,
		CaptureCommand=function(s) 
			SCREENMAN:GetTopScreen():AddInputCallback(input)
			if getenv("DDRWORLD_OpenFolder") then
				-- asked for by the wheel ("Change folder") or by the first stage of a new profile
				setenv("DDRWORLD_OpenFolder", nil)
				OpenFolder()
				SOUND:PlayOnce(THEME:GetPathS("WORLD/Folder","in"))
			elseif not SORT_LIST_ENABLED then
				OpenFilter()
				SOUND:PlayOnce(THEME:GetPathS("WORLD/PlayerOptions","Open"))
			end
		end,
		Def.ActorScroller{
			SecondsPerItem=0;
			NumItemsToDraw=40;   -- the scroller draws only about half of this many items: 20 hid the last two
			TransformFunction=function(self,offsetFromCenter,itemIndex,numItems)
				self:y((offsetFromCenter*32)-170):draworder(math.abs(offsetFromCenter)*10)
					if itemIndex%2==0 then
						self:x(-84)
					else
						self:x(78)
					end;
			end,
			children=ItemList;
		}
	};
};

-- the filter menu (hidden until FILTER is chosen)
t[#t+1] = loadfile(THEME:GetPathB("ScreenSortList","overlay/filter.lua"))()
FilterMenu.OnClose = CloseFilter

-- the folder screen (hidden until it is asked for)
t[#t+1] = loadfile(THEME:GetPathB("ScreenSortList","overlay/folder.lua"))()
FolderMenu.OnClose = CloseFolder

-- the timer of the select music screen, drawn here above the dark layer (the layer greyed it) and ending the menu with the time
if DDRWORLD_MenuTimerMirror then t[#t+1] = DDRWORLD_MenuTimerMirror(TimerExpired) end

t[#t+1] = LoadActor( THEME:GetPathS("WORLD/Folder", "change") )..{ Name="folder_change", SupportPan = false }
t[#t+1] = LoadActor( THEME:GetPathS("WORLD/PlayerOptions", "move") )..{ Name="change_sound", SupportPan = false }
t[#t+1] = LoadActor( THEME:GetPathS("WORLD/PlayerOptions", "change") )..{ Name="move_sound", SupportPan = false }
t[#t+1] = LoadActor( THEME:GetPathS("common", "start") )..{ Name="start_sound", SupportPan = false }

return t
