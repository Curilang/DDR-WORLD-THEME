-- Menu timer drawn with the original's digits. One file for every screen that has a timer: build it with
-- DDRWORLD_MenuTimer(screenName, x, y) (Scripts/08 MenuTimer.lua); x, y = centre of the LEFT digit's 64x72 cell in theme units.
-- Measured from the original (60 fps video + 720p screenshots of its window):
--   * the number changes in one frame when the second changes: no zoom, no tween;
--   * two digits always ("09"); the left one is a dark digit with a white outline, the right one a white digit with a dark outline,
--     47 px (720p) to the right of the left one;
--   * from 10 on (10 ... 00) both turn red in the same frame the number changes to 10 (red #FE250D), and stay red;
--   * "00" is on screen only for the instant before the screen changes, and the timer leaves together with the screen;
--   * every screen uses this same animation, only the position changes.
-- The engine's own timer is hidden in metrics.ini (TimerOnCommand=visible,false) but keeps counting and ending the screen:
-- this actor only reads its seconds. Textures (this folder, 4x4 sheets of 64x72 cells, digit = frame 0-9):
-- digits_left / digits_right, and the same two in red.
--
-- THE FILTER / FOLDER MENUS (ScreenSortList, a screen on top of the select music screen) dim everything under them and take the
-- messages of the engine's timer (the time running out is posted to the TOP screen, which is the menu). So:
--   * the select music screen's timer publishes its seconds in DDRWORLD_MenuTimerState every frame and hides its digits while a
--     menu is open (FilterOpened / FilterClosed messages);
--   * the menu screen draws a MIRROR of the timer (args.mirror, DDRWORLD_MenuTimerMirror) above the dark layer, counting down from
--     that state, and calls args.onZero when it reaches 0 (the menu closes, see ScreenSortList overlay/default.lua);
--   * the menu then sets DDRWORLD_TimerExpired and, when the select music screen is the top one again, its timer posts SM_MenuTimer
--     to it: the screen ends as if the time had run out on the wheel.
local args = ... or {}
local SCREEN_NAME = args.screen or "ScreenSelectMusic"
local MIRROR = args.mirror                       -- the copy drawn by the menu screen (reads DDRWORLD_MenuTimerState)
-- args.player: screens with one timer per player (profile selection, data save) show it only for the players that are joined
-- (both timers when both are); if nobody is joined yet, the player 1 one is shown. nil = a single timer, always shown.
local PLAYER = args.player
-- default position = the select music screen. Measured on a 720p screenshot of the original (cells at 720p px (1152,82) and
-- (1199,82)); checked against our own screenshot (the same matching found our cells where they were placed).
local TENS_X = args.x or 789.33
local DIGIT_Y = args.y or 78.67
local ONES_X = TENS_X + 47 / 1.5             -- the right digit is 47 px (720p) further right
local ZOOM = 2 / 3                            -- the textures are drawn for 720p, the theme is 854x480
local RED_FROM = 5                           -- seconds left from which the digits are red

local sprites = {}
local function digit(key, file, x)
	return Def.Sprite{
		Texture=file,
		InitCommand=function(s)
			sprites[key] = s
			s:xy(SCREEN_LEFT + x, DIGIT_Y):zoom(ZOOM):pause():setstate(0):visible(false)
		end,
	}
end

local timer          -- the engine's timer of the screen (found once)
local lastN, lastRed
local leaving = false   -- the screen started its way out (a player pressed Enter, or the time ran out): the timer is gone
local covered = false   -- (select music screen) a menu is open: the mirror draws the timer instead
local mirrorOn = false  -- (mirror) the menu is open: the mirror is drawn
local fired = false     -- (mirror) onZero was called
local expiredAt, selectTried   -- (select music screen) waiting to hand it the end of the time, see Refresh

local function FindTimer()
	local screen = SCREENMAN:GetTopScreen()
	if screen and screen:GetName() == SCREEN_NAME and screen.GetChild then
		local ok, child = pcall(function() return screen:GetChild("Timer") end)
		if ok and child and child.GetSeconds then return child end
	end
	return nil
end

local function PlayerShown()
	if not PLAYER then return true end
	if GAMESTATE:IsSideJoined(PLAYER) then return true end
	return PLAYER == PLAYER_1 and not GAMESTATE:IsSideJoined(PLAYER_2)
end

local function HideAll()
	for _, s in pairs(sprites) do s:visible(false) end
	lastN, lastRed = nil, nil
end

-- the seconds to show: the engine's timer, or (the mirror) the state published by the select music screen, counted on
local function Seconds()
	if MIRROR then
		local st = DDRWORLD_MenuTimerState
		if not st or st.screen ~= SCREEN_NAME then return nil end
		return st.secs - (GetTimeSinceStart() - st.stamp)
	end
	if not timer then timer = FindTimer() end
	if not timer then return nil end
	local ok, secs = pcall(function() return timer:GetSeconds() end)
	if not ok or type(secs) ~= "number" then return nil end
	return secs
end

local function Refresh()
	if not sprites.tensN then return end

	-- the menu closed because the time ran out: when the select music screen is the top one again it gets the message
	-- the engine posted to the menu instead
	-- (The menus open from the header of the list, so the cursor may be on the header: the list opens again by itself
	-- (Filter.RequestOpen) and the cursor goes back to the last song, which is the current one. The message waits for that.)
	if not MIRROR and SCREEN_NAME == "ScreenSelectMusic" and getenv("DDRWORLD_TimerExpired") then
		local screen = SCREENMAN:GetTopScreen()
		if screen and screen:GetName() == "ScreenSelectMusic" and screen.PostScreenMessage then
			expiredAt = expiredAt or GetTimeSinceStart()
			local waited = GetTimeSinceStart() - expiredAt
			local wheel = screen.GetMusicWheel and screen:GetMusicWheel()
			local song = GAMESTATE:GetCurrentSong()
			local onSong = false
			if wheel then pcall(function() onSong = ToEnumShortString(wheel:GetSelectedType()) == "Song" end) end
			if not onSong and wheel and song and wheel.SelectSong and waited > 0.4 and not selectTried then
				selectTried = true
				pcall(function() wheel:SelectSong(song) end)
			end
			if onSong or waited > 1.2 then
				setenv("DDRWORLD_TimerExpired", nil)
				expiredAt, selectTried = nil, false
				screen:PostScreenMessage("SM_MenuTimer", 0)
			end
		end
	end

	if leaving then return end
	if MIRROR and not mirrorOn then return end
	if not PREFSMAN:GetPreference("MenuTimer") or not PlayerShown() then
		if lastN ~= nil then HideAll() end
		return
	end
	local secs = Seconds()
	if not secs then return end

	if not MIRROR and SCREEN_NAME == "ScreenSelectMusic" then
		-- (read by the mirror of the menu screens)
		DDRWORLD_MenuTimerState = { screen = SCREEN_NAME, secs = secs, stamp = GetTimeSinceStart() }
	end
	if covered then return end

	if MIRROR and secs <= 0 and not fired then
		fired = true
		if args.onZero then args.onZero() end
	end

	local n = math.max(0, math.min(99, math.ceil(secs)))
	local red = n <= RED_FROM
	if n == lastN and red == lastRed then return end
	lastN, lastRed = n, red
	local tens, ones = math.floor(n / 10), n % 10
	sprites.tensN:setstate(tens):visible(not red)
	sprites.onesN:setstate(ones):visible(not red)
	sprites.tensR:setstate(tens):visible(red)
	sprites.onesR:setstate(ones):visible(red)
end

return Def.ActorFrame{
	InitCommand=function(self)
		if not MIRROR and SCREEN_NAME == "ScreenSelectMusic" then DDRWORLD_MenuTimerState = nil end   -- (a new screen: no old seconds)
		self:SetUpdateFunction(Refresh)
	end,
	-- The screen is leaving (Enter, or the end of the time): the timer goes at once, in the same frame as the screen's own Off.
	-- (The engine's timer stops at 00 when the screen starts to leave, and the digits stayed on screen until the next one
	-- appeared: the transition can take a second or two.) The original's timer also leaves with the screen, with no animation.
	OffCommand=function(self)
		leaving = true
		HideAll()
	end,
	-- a menu (filter, folders) opened / closed on top of the select music screen: its dark layer would grey the digits, so the
	-- menu screen draws them (mirror) and these hide in the meantime
	FilterOpenedMessageCommand=function(self)
		if MIRROR then
			mirrorOn, fired = true, false
			lastN, lastRed = nil, nil
		elseif SCREEN_NAME == "ScreenSelectMusic" then
			covered = true
			HideAll()
		end
	end,
	FilterClosedMessageCommand=function(self)
		if MIRROR then
			mirrorOn = false
			HideAll()
		elseif SCREEN_NAME == "ScreenSelectMusic" then
			covered = false
			lastN, lastRed = nil, nil   -- (drawn again on the next frame)
		end
	end,
	digit("tensN", "digits_left 4x4.png",      TENS_X),
	digit("onesN", "digits_right 4x4.png",     ONES_X),
	digit("tensR", "digits_left_red 4x4.png",  TENS_X),
	digit("onesR", "digits_right_red 4x4.png", ONES_X),
}
