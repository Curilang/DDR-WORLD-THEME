-- Entry animation of the music wheel: WHEN it plays. The animation itself (the cards rise as black cells, show their title
-- over a gradient and are uncovered from the top down, in a wave from the bottom right card; the card with the cursor
-- turns) is done by the cards, driven by hand every frame: see "ENTRY ANIMATION" in Scripts/08 WheelLayout.lua and the
-- parts of the card in Graphics/MusicWheelItem Song NormalPart/default.lua.
--
-- This actor:
--   * hides the wheel (WheelLayout.IntroPending) from the moment the screen is built until the songs are ordered
--     (Scripts/08 SongOrder.lua, message WheelOrdered) and the engine is calm (it stops for a while loading jackets and
--     ordering, and the animation must not be eaten by those stops);
--   * starts the animation (WheelLayout.IntroStart) after IntroDelay seconds: 0.35 when the screen's doors are opening (in the
--     original the cards begin to rise under the disc), 0.15 after a filter / folder / sort was chosen;
--   * keeps the wheel from taking input while it plays (Screen:lockinput; if that does not exist the animation simply ends
--     when the cursor moves, see WheelLayout.IntroFrame).
-- It plays when the screen is shown, when a filter or folder is applied (the screen is built again) and when a new sort is
-- chosen (message MusicWheelSort). Coming back from the difficulty selection or from the options menu there is none.

-- true when coming back from the difficulty selection: no animation, the wheel only fades in (default.lua)
local skip = ...

local DELAY_DOORS = 0.35
local DELAY_OTHER = 0.15
-- (all the waiting is counted in frames of at most 0.05 s, not in real time: the first time the screen is built the engine
-- stops for seconds ordering the songs and loading jackets, and counting that as waiting made the animation give up)
local MAX_COVER = 1.5                -- start anyway after this long if the "ordered" message never comes
local GIVE_UP = 2.0                  -- show the wheel as it is if the animation could not start (no layout)

local reloaded = (function() local v = getenv("DDRWORLD_FilterReload"); return type(v) == "number" and GetTimeSinceStart() - v < 1.5 end)()
local delay = reloaded and DELAY_OTHER or DELAY_DOORS

local STEP_LIMIT = 0.05              -- a frame longer than this is the engine stopping (loading textures, ordering)
local CALM_FRAMES = 3                -- frames in a row below STEP_LIMIT before it starts
local calm = 0

local ordered, orderedTime, lastTime
local waited, orderedWait = 0, 0      -- seconds (in frames of at most 0.05 s) since the wait began / since "ordered"
local started = false

-- the wheel takes no input while the animation plays (ITGmania: Screen:lockinput)
local function Lock(seconds)
	if seconds <= 0 then return end
	local screen = SCREENMAN:GetTopScreen()
	if screen and screen:GetName() == "ScreenSelectMusic" then screen:lockinput(seconds) end
end

local function Off()
	started = true
	if WheelLayout then WheelLayout.IntroOff() end
end

local SOUND_LEAD = 0.09   -- segundos que el sonido suena ANTES de que arranque la animación (ajústalo)
local soundPlayed = false

local function PlayIntroSound()
	if soundPlayed then return end
	soundPlayed = true
	SOUND:PlayOnce(THEME:GetPathS("WORLD/Wheel", "in"))
end

local t = Def.ActorFrame{}

t.InitCommand = function(self)
	lastTime = GetTimeSinceStart()
	if skip then
		Off()
	elseif WheelLayout then
		WheelLayout.IntroPending()
	end
	self:SetUpdateFunction(function(frame)
		if not WheelLayout then return end
		local now = GetTimeSinceStart()
		local step = now - lastTime
		lastTime = now
		if step > STEP_LIMIT then calm = 0 else calm = calm + 1 end
		if started then
			-- (the animation is running: the wheel does not take input)
			if WheelLayout.IntroState() == "run" then Lock(WheelLayout.IntroRemaining()) end
			return
		end
		local dt = math.min(step, STEP_LIMIT)
		waited = waited + dt
		if ordered then orderedWait = orderedWait + dt end
		if calm < CALM_FRAMES and waited < MAX_COVER then return end
		if ordered and not soundPlayed and orderedWait >= delay - SOUND_LEAD then
			PlayIntroSound()
		end
		if (ordered and orderedWait >= delay) or waited >= MAX_COVER then
			if WheelLayout.IntroStart() then
				started = true
				PlayIntroSound()   -- NUEVO
				Trace(string.format('WheelIntro: start at %.3f (ordered %s, waited %.2f)', now, tostring(orderedTime), waited))
				Lock(WheelLayout.IntroRemaining())
			elseif waited >= GIVE_UP then
				Trace('WheelIntro: the layout is not ready, the wheel is shown as it is')
				Off()
			end
		end
	end)
end

-- sent by the select music overlay when the order of the songs is applied (or there was nothing to do)
t.WheelOrderedMessageCommand = function(self)
	if started then return end
	ordered = true
	orderedTime = GetTimeSinceStart()
	waited, orderedWait = 0, 0
	Trace(string.format('WheelIntro: ordered at %.3f', orderedTime))
end

-- a new sort is chosen in the sort list (BGAnimations/ScreenSortList overlay): the wheel is hidden and the animation plays
-- again once the new order is on screen
t.MusicWheelSortMessageCommand = function(self)
	if not WheelLayout then return end
	started = false
	soundPlayed = false   -- NUEVO
	ordered = true
	orderedTime = GetTimeSinceStart()
	waited, orderedWait = 0, 0
	delay = DELAY_OTHER
	calm = 0
	WheelLayout.IntroPending()
	Trace('WheelIntro: new sort')
end

-- the options menu opens or closes, or the filter menu opens: no animation (the wheel fades in / is hidden by metrics.ini)
t.POMenuClosingMessageCommand = function(self) Trace('WheelIntro: POMenuClosing'); Off() end
t.POMenuOpenedMessageCommand = function(self) Off() end
t.FilterOpenedMessageCommand = t.POMenuOpenedMessageCommand

return t
