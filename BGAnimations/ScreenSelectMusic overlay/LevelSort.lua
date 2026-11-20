-- Keeps the LEVEL sort working while the music wheel is on screen (see Scripts/08 LevelSort.lua): every frame it
-- fills the section the cursor is on, so it is complete when the player opens it, and selects the chart of the
-- row under the cursor.
--
-- It also gets a pack ready while the cursor rests on it, closed: one song per frame it loads the jacket (the
-- engine keeps it in memory, see DelayedTextureDelete) and works out the scores the wheel items will ask for
-- (Scripts/08 WheelCache.lua). When the pack is opened, its items find everything already done instead of
-- loading 18 jackets and reading 18 score lists in the same frame. Nothing is drawn differently.
local WARM_DELAY = 0.45   -- seconds the cursor must rest on the pack before the work starts (not while scrolling)
local WARM_EVERY = 0.03    -- seconds between two songs (a frame is about a millisecond, so frames cannot be counted)
local warm = { section = nil, list = nil, index = 0, since = 0, last = 0 }

local function WarmStep(wheel, sprite)
	local section
	if ToEnumShortString(wheel:GetSelectedType()) == "Section" then
		section = wheel:GetSelectedSection()
	end
	if section ~= warm.section then
		warm.section, warm.list, warm.index, warm.since = section, nil, 0, GetTimeSinceStart()
	end
	if not section or LevelSort.Loaded then return end
	local now = GetTimeSinceStart()
	if now - warm.since < WARM_DELAY or now - warm.last < WARM_EVERY then return end
	warm.last = now
	if not warm.list then
		warm.list = SONGMAN:GetSongsInGroup(section) or {}
	end
	warm.index = warm.index + 1
	local song = warm.list[warm.index]
	if not song then return end

	-- jacket: loaded the same way the wheel item does, so the engine already has the texture when the item asks
	local image = WheelCache.JacketInfo(song)
	sprite:LoadFromCached(image.cache, image.path)

	-- scores of the selected difficulty of each player
	local st = GAMESTATE:GetCurrentStyle():GetStepsType()
	for _, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		local steps = GAMESTATE:GetCurrentSteps(pn)
		if steps then WheelCache.Chart(pn, song, st, steps:GetDifficulty()) end
	end
end

-- PREFETCH of the jackets around the cursor, for the single list (the filter / folder list, where the pack is the whole
-- list and WarmStep above has nothing to warm). About 500 jackets have no entry in Cache/Jacket (the log says "Cache file
-- ... couldn't be loaded"): the first time the wheel shows one the engine reads the full image, which stops the game for
-- 30-40 ms (the inputs go from 7 ms to 35-40 ms while scrolling over them). Here, once the cursor has rested, the
-- songs just beyond what the wheel already holds are loaded, nearest first and on the side the cursor was moving to,
-- so they are ready when the cursor gets there. Songs already loaded cost almost nothing, so many go in one frame; a slow
-- one ends the frame's work. Nothing is done while the cursor moves.
local PF_FIRST, PF_LAST = 11, 36   -- songs from the cursor, beyond the ones the wheel items hold already
local PF_IDLE = 0.25               -- seconds the cursor must rest first
local PF_BUDGET = 0.006            -- seconds of loading per frame (the last load can go over it)
local PF_SLOW = 0.008              -- a load longer than this ends the frame's work
local prefetch = { seen = {}, key = nil, last = nil, moved = 0, dir = 1, n = 0 }

local function PrefetchStep(wheel, sprite)
	if not (LevelSort.Loaded and WheelLayout and WheelLayout.Focus and LevelSort.EntrySong) then return end
	local focus = WheelLayout.Focus()
	if not focus then return end
	local now = GetTimeSinceStart()
	local open = GAMESTATE:GetExpandedSectionName() or ""
	if prefetch.key ~= open then
		prefetch.key, prefetch.seen, prefetch.last = open, {}, nil
	end
	if focus ~= prefetch.last then
		if prefetch.last and math.abs(focus - prefetch.last) < 40 then prefetch.dir = (focus > prefetch.last) and 1 or -1 end
		prefetch.last, prefetch.moved, prefetch.n = focus, now, 0
		return
	end
	if now - prefetch.moved < PF_IDLE then return end

	local total = 2 * (PF_LAST - PF_FIRST + 1)
	while prefetch.n < total and GetTimeSinceStart() - now < PF_BUDGET do
		prefetch.n = prefetch.n + 1
		local k = PF_FIRST + math.floor((prefetch.n - 1) / 2)
		local side = (prefetch.n % 2 == 1) and prefetch.dir or -prefetch.dir
		local song = LevelSort.EntrySong(focus + side * k)
		if song then
			local dir = song:GetSongDir()
			if not prefetch.seen[dir] then
				prefetch.seen[dir] = true
				local before = GetTimeSinceStart()
				local image = WheelCache.JacketInfo(song)
				sprite:LoadFromCached(image.cache, image.path)
				if GetTimeSinceStart() - before > PF_SLOW then return end
			end
		end
	end
end

-- When a group is opened with the cursor on its title, the cursor goes on to the first song of the group (with the
-- cursor on the title the wheel shows the end of the group above it, because it is circular; this way the title
-- is a row above the middle and the start of the group is what shows). The wheel keeps the cursor in the middle, so
-- the title is as many items above the middle as the cursor moves: OPEN_MOVE_ITEMS = 1 is the first song; larger
-- values put the cursor further into the group (4 = the first song of the second row) and raise the title.
-- Set SELECT_FIRST_SONG_ON_OPEN to false to keep the cursor on the title.
local SELECT_FIRST_SONG_ON_OPEN = true
local OPEN_MOVE_ITEMS = 1
local OPEN_RETRY_SECONDS = 0.6   -- the wheel may be busy opening the group: the move is tried for this long
local opened = { name = nil, pending = false, since = 0 }

-- The sound of the wheel (Sounds/WheelStep.ogg): ONE sound each time the cursor really changes, whatever moved it. The
-- engine's own sound (Sounds/MusicWheel change.redir) is silenced: it plays once per Move call, and UP / DOWN make
-- several Move calls per press (BGAnimations/ScreenSelectMusic decorations/InputHandler.lua), so it piled up.
-- The cursor moving by itself (a list opening, a reload) makes no sound.
local step = { index = nil, items = nil, section = nil, lastPlay = -1, mute = 0 }
local function StepSound(wheel, sound)
	local now = GetTimeSinceStart()
	local index, items = wheel:GetCurrentIndex(), wheel:GetNumItems()
	local section = GAMESTATE:GetExpandedSectionName() or ""
	if section ~= step.section then step.mute = now + 0.6 end
	if step.index ~= nil and index ~= step.index and items == step.items and now >= step.mute
			and now - step.lastPlay >= 0.03 then
		step.lastPlay = now
		sound:play()
	end
	step.index, step.items, step.section = index, items, section
end

local function OpenStep(wheel)
	local open = GAMESTATE:GetExpandedSectionName() or ""
	if opened.name == nil then
		if Filter and Filter.OpenedAtStart and Filter.OpenedAtStart() then
			-- the list was closed and has just been opened (Filter.OpenAtStart): it counts as opened now, so the cursor
			-- goes on to the first song, or to the song the player was on (see OpenStep below)
			opened.name = ""
			opened.atStart = true
		else
			opened.name = open   -- first frame: a group that is already open (coming back from a song) is left alone
			return
		end
	end
	if open ~= opened.name then
		opened.name = open
		opened.pending = SELECT_FIRST_SONG_ON_OPEN and open ~= "" and not getenv("DDRWORLD_StartOnButtons")
		opened.since = GetTimeSinceStart()
	end
	if not opened.pending then return end

	if GetTimeSinceStart() - opened.since > OPEN_RETRY_SECONDS
		or ToEnumShortString(wheel:GetSelectedType()) ~= "Section"
		or wheel:GetSelectedSection() ~= open then
		opened.pending = false   -- done (the cursor is already off the title), or the wheel never allowed it
		return
	end
	-- the wheel is still opening the group: wait (it ignores moves while it is busy)
	if wheel:IsLocked() or not wheel:IsSettled() then return end

	-- one move only: it is not repeated, that would go further than wanted
	opened.pending = false
	local block = WheelCache.Block()
	local songs = block and (block.last - block.first + 1) or 1
	local steps = math.max(1, math.min(OPEN_MOVE_ITEMS, songs))
	-- Coming back to this screen (after a song, the options...) the engine cannot reopen the single list by itself (it
	-- looks for the last open section by a name the theme's list never registers), so the list comes up closed and is
	-- opened here. The cursor then goes back to the song the player was on (the engine's "preferred" song: the last
	-- song the cursor was on, or the first song of the list chosen for a new player), not to the first song.
	if opened.atStart then
		opened.atStart = false
		local target = GAMESTATE:GetPreferredSong()
		if target and LevelSort.EntrySong then
			local dir = target:GetSongDir()
			local i = 1
			while true do
				local s = LevelSort.EntrySong(i)
				if not s then break end
				if s:GetSongDir() == dir then steps = i break end
				i = i + 1
			end
		end
	end
	step.mute = GetTimeSinceStart() + 0.4   -- (the cursor goes to the first song by itself: no sound)
	wheel:Move(steps)
	wheel:Move(0)
end

return Def.ActorFrame{
	InitCommand=function(self)
		local sprite = self:GetChild("Warm")
		local stepSound = self:GetChild("Step")
		self:SetUpdateFunction(function()
			WheelCache.Tick()   -- one tick per frame: the wheel caches things per frame (Scripts/08 WheelCache.lua)
			local screen = SCREENMAN:GetTopScreen()
			local wheel = screen and screen.GetMusicWheel and screen:GetMusicWheel()
			-- (a wheel without items cannot be asked anything: the engine would stop, see Scripts/08 WheelCache.lua)
			if wheel and wheel:GetNumItems() < 1 then wheel = nil end
			if LevelSort.Loaded and wheel then LevelSort.Poll(wheel) end
			if Filter then Filter.Poll() end   -- with a filter on, the cursor lands on a chart that fits it
			if wheel then OpenStep(wheel); WarmStep(wheel, sprite) end
			if wheel and stepSound then StepSound(wheel, stepSound) end
			if wheel then PrefetchStep(wheel, sprite) end
			-- (after OpenStep: it sees the section being opened and moves the cursor onto the first song)
			if wheel and Filter then Filter.EnsureOpen(wheel) end
			if wheel and WheelLayout then WheelLayout.Update(wheel) end   -- the rows of songs (Scripts/08 WheelLayout.lua)
		end)
	end,
	-- never visible: it only holds the texture that is being loaded
	Def.Sprite{ Name="Warm", InitCommand=function(s) s:visible(false) end },
	Def.Sound{ Name="Step", File=THEME:GetPathS("WORLD/Wheel", "change"), SupportPan=false },
}
