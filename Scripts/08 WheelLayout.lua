-- ============================================================================
-- WHEEL LAYOUT: where the songs of the open pack are drawn (3 per row), and how the rows scroll
-- ============================================================================
-- The engine's wheel is ONE column of items, one item per song. This theme draws the songs of the open pack as a grid
-- of three per row by moving every item to its cell. The arcade does it like this:
--   * the cursor moves along the row (LEFT / RIGHT) and the ROW STAYS STILL: the grid only moves to the next row once
--     the cursor has gone past the last song of the row;
--   * UP / DOWN move a whole row; when they come fast the view lags behind a little (the cursor row drifts off the
--     middle) and it settles on the row of the cursor when the cursor stops.
-- The view therefore does not follow the cursor item by item: it follows the ROW of the cursor, with its own easing.
--
-- Layout, in the units of the wheel items (an item is 105 units from the next one in the engine's column):
--   the open pack is  header, song 1, song 2, ... song n  (the wheel's items, numbered like the Set messages)
--   header at y = 0, the first row of songs HEADER_GAP below, then a row every ROW units; the pack repeats after the
--   last row (the wheel is a circle).
--   column of a song: x = -225, 0, +225
--
-- Every item remembers the wheel index of the song it shows in item.dataIndex (set by its Set message, see the
-- NormalPart files), because the engine moves the items to new slots before the Set message arrives.
-- Used from: BGAnimations/ScreenSelectMusic overlay/LevelSort.lua (Update, every frame) and metrics.ini
-- ([MusicWheel] ItemTransformFunction).
-- ============================================================================

WheelLayout = {}

local ROW = 315          -- distance between two rows of songs
local HEADER_GAP = 210   -- from the header to the first row
local HEADER_ABOVE = 210 -- from the last row to the header
-- With the two buttons (Scripts/08 WheelButtons.lua) the header is a block 258 units high, centered on the header's y: it
-- needs more room on both sides (half the block + the gap to the cards + the half height of a row of cards).
local BUTTONS_GAP = 286
local BUTTONS_ABOVE = 284
local COLUMN = 225       -- distance between columns
local ROW_Y0 = 0         -- where the row of the cursor rests (the old theme rested at 0 with the cursor in the middle column)
local TAU = 0.045        -- seconds the view takes to cover about two thirds of the way to the row of the cursor
-- true: at rest (nothing moved for 0.6 s) the items are not walked every frame. Off until it is shown to be safe: the first version
-- of the per-frame savings left the wheel in one column.
local IDLE_SKIP = false
local SNAP_ROWS = 4      -- farther than this many rows: the view jumps (a new list, a jump in the wheel)
local MAX_LAG = ROW * 0.75  -- the most the view can be behind the cursor row (the wheel has 10 items on each side)

-- The turn of the card that gets the cursor (the "Turn" frame of Graphics/MusicWheelItem Song NormalPart).
-- Measured from the original (30 fps frames): the cell goes dark and empty for about 0.04 s, the back of the card
-- turns up (dark, seen from behind) until it is edge-on, then the front turns in and slows down until it faces the
-- screen: about 0.18 s in all. sign: 1 or -1 turns it the other way round; from: the angle it starts at (degrees, 90 =
-- edge-on); empty / back / front: seconds of each part; dark: the color of the back of the card.
-- enabled = false: no turn at all (used to find out whether the turn is what makes cards go missing while scrolling).
WheelLayout.TURN = { enabled = true, rotate = true, darken = true, sign = 1, from = 125, empty = 0.04, back = 0.04, front = 0.10, dark = "#1C1C1C" }

local state = { time = -1, active = false }
local view = { y = nil, time = nil, key = nil }
local focusIndex         -- index of the song that the last item with the focus shows (WheelLayout.NoteFocus)
local cursor             -- the cursor in wheel numbering, not wrapped (it can go past the last item and keep counting)

-- position of an item of the pack: unwrapped index -> y of its row, and its place in the pack (0 = header)
local function Place(u, head, n1, rows)
	local rel = u - head
	local k = math.floor(rel / n1)
	local j = rel - k * n1
	local below, above = state.below or HEADER_GAP, state.above or HEADER_ABOVE
	local y = (j == 0) and 0 or (below + ROW * math.floor((j - 1) / 3))
	return k * (ROW * (rows - 1) + below + above) + y, j
end

-- Worked out once per frame: the state of the layout and where the view is.
local function Prepare()
	local now = GetTimeSinceStart()
	if state.time == now then return state.active end
	local previous = state.time
	state.time = now
	state.active = false

	local b = WheelCache.Block()
	-- The cursor is the card that has the focus, as its Set message told (NOT the engine's GetCurrentIndex plus a
	-- difference worked out from the messages: while scrolling the messages arrive late and that difference drifted by
	-- one, which put the turn on the next card and the row change one song early).
	if not b or focusIndex == nil or b.total < 2 then
		if state.wasOn ~= false then
			state.wasOn = false
			Trace("WheelLayout: off (block = " .. tostring(b ~= nil) .. ", focus = " .. tostring(focusIndex)
				.. ", total = " .. tostring(b and b.total) .. ", open = '" .. tostring(GAMESTATE:GetExpandedSectionName()) .. "')")
		end
		view.y, cursor = nil, nil
		return false
	end
	state.wasOn = true

	local n = b.last - b.first + 1
	state.head, state.n1, state.rows, state.total = b.first - 1, n + 1, math.ceil(n / 3), b.total
	local buttons = WheelButtons and WheelButtons.Enabled() or false
	state.below = buttons and BUTTONS_GAP or HEADER_GAP
	state.above = buttons and BUTTONS_ABOVE or HEADER_ABOVE

	-- the cursor in the numbering of the Set messages, kept continuous when the wheel wraps around
	local sel = focusIndex % b.total
	state.cursorNow = sel
	local key = b.first .. "/" .. b.total .. "/" .. (buttons and "b" or "h")
	if cursor == nil or view.key ~= key then
		cursor = sel
		view.y = nil
		view.key = key
		Trace("WheelLayout: on, songs = " .. n .. ", rows = " .. state.rows .. ", items = " .. b.total
			.. ", cursor = " .. sel)
	else
		local d = (sel - cursor) % b.total
		if d > b.total / 2 then d = d - b.total end
		cursor = cursor + d
	end

	local target = Place(cursor, state.head, state.n1, state.rows)
	if view.y == nil or math.abs(target - view.y) > SNAP_ROWS * ROW then
		view.y = target
	else
		local dt = math.min(0.1, math.max(0, now - (view.time or now)))
		local gap = target - view.y
		if math.abs(gap) < 0.5 then
			view.y = target
		else
			view.y = view.y + gap * (1 - math.exp(-dt / TAU))
		end
		-- never farther behind the cursor than the wheel has items for (NumWheelItems in metrics.ini): past that the rows
		-- at the edge of the screen would have no cards
		view.y = math.min(target + MAX_LAG, math.max(target - MAX_LAG, view.y))
	end
	view.time = now
	if view.y ~= target or cursor ~= state.lastCursor then state.activity = now end
	state.lastCursor = cursor
	state.active = true
	return true
end

-- The item under the cursor tells which song the cursor is on (the Set message of the item with the focus). This is
-- the cursor in the numbering of the items, whatever number the engine's own cursor index carries.
function WheelLayout.NoteFocus(index)
	local previous = focusIndex
	focusIndex = index
	state.activity = GetTimeSinceStart()
	-- (the header is two buttons: which one has the cursor depends on the side it came from)
	if previous ~= index and WheelButtons then WheelButtons.Arrived(previous, index) end
end

-- A Set message arrived (an item changed what it shows): the items are walked again for a moment.
function WheelLayout.Touch()
	state.activity = GetTimeSinceStart()
end

-- The index (in the numbering of the items) of the song under the cursor, nil while it is not known yet.
function WheelLayout.Focus()
	return focusIndex
end

function WheelLayout.Active()
	return state.active
end

-- Puts one wheel item in its cell. `offset` is how many items it is from the cursor (it can be fractional). Returns
-- false when the item is not placed by the layout (the engine's column is used).
local function PlaceItem(item, offset)
	local index = item.dataIndex
	if not index or not Prepare() then return false end
	if item.innerShifted and item.inner then
		item.inner:xy(0, 0)   -- it was set up for the engine's column
		item.innerShifted = false
	end
	if item.headShifted and item.headInner then
		item.headInner:xy(0, 0)   -- (the header's part: see Graphics/MusicWheelItem SectionCollapsed NormalPart.lua)
		item.headShifted = false
	end
	local total = state.total
	local u = index + total * math.floor((cursor + offset - index) / total + 0.5)
	local y, j = Place(u, state.head, state.n1, state.rows)
	local x = (j == 0) and 0 or (((j - 1) % 3) - 1) * COLUMN
	item:xy(x, y - view.y + ROW_Y0)   -- (always: the engine can put the item somewhere else when it rebuilds the wheel)
	-- where the card sits (the entry animation needs its row and column, see UpdateIntro)
	item.layoutY, item.layoutJ = y - view.y + ROW_Y0, j
	item.layoutCol = (j == 0) and 0 or ((j - 1) % 3)
	-- the two buttons of the header (Scripts/08 WheelButtons.lua) are shown while the item sits in the header's place
	local buttons = item.buttons
	if buttons then
		local want = (j == 0)
		if item.buttonsShown ~= want then
			item.buttonsShown = want
			for frame in pairs(buttons) do frame:visible(want) end
		end
	end
	return true
end

local WHITE, DARK   -- (colors: made the first time they are needed, `color` is not ready while the scripts load)

-- Starts the turn of a card that has the cursor and ends the one of a card that lost it. Done here, every frame, and
-- not in the Set messages: those do not come in order (the one of the card that loses the focus can arrive before the
-- one of the card that gains it) and left cards turned or dark while scrolling fast.
-- The turn is driven by hand: every frame the pose (angle and color) is computed from the time since the card got the
-- cursor and set directly. No tween is ever queued on the Turn frame (tweens on parts of a wheel item made cards go
-- missing while scrolling fast, even when the tween changed nothing that could be seen).
local function Decelerate(x) return 1 - (1 - x) * (1 - x) end

local function Pose(turn, angle, dark)
	if turn.poseAngle ~= angle then turn.poseAngle = angle; turn:rotationy(angle) end
	if turn.poseDark ~= dark then
		turn.poseDark = dark
		turn:diffuse(dark and DARK or WHITE)
	end
end

local function UpdateTurn(item)
	local turn = item.turn
	local t = WheelLayout.TURN
	if not turn or not t.enabled then return end
	WHITE = WHITE or color("#FFFFFF")
	DARK = DARK or color(t.dark)
	local want = (item.dataIndex ~= nil and item.dataIndex == state.cursorNow)
	local now = GetTimeSinceStart()
	if want then
		if turn.turnIndex ~= item.dataIndex then
			turn.turnIndex = item.dataIndex
			turn.turnStart = now
			turn.turnDone = false
		end
		if turn.turnDone then return end
		local e = now - turn.turnStart
		if e < t.empty then
			Pose(turn, 0, t.darken)                                              -- the cell is dark and empty
		elseif e < t.empty + t.back then
			local x = (e - t.empty) / t.back                                     -- the back turns up until it is edge-on
			Pose(turn, t.rotate and t.sign * (t.from + (90 - t.from) * x) or 0, t.darken)
		elseif e < t.empty + t.back + t.front then
			local x = (e - t.empty - t.back) / t.front                           -- the front turns in and slows down
			Pose(turn, t.rotate and t.sign * 90 * (1 - Decelerate(x)) or 0, false)
		else
			Pose(turn, 0, false)
			turn.turnDone = true
		end
	elseif turn.turnIndex ~= nil then
		turn.turnIndex = nil
		Pose(turn, 0, false)
	end
end

-- ============================================================================
-- ENTRY ANIMATION of the cards (after the screen's doors, after a filter / folder / sort is chosen)
-- ============================================================================
-- Measured from the original (60 fps video, 720p window; the capture shows ~30 fps of game frames). Every card on screen
-- goes through the same steps, one after another in a wave that starts at the bottom right card and moves up and to the
-- left (a card starts STEP_ROW later per row up and STEP_COL later per column to the left):
--   0.00  the cell appears as a black box that rises ~76 px into its place (slowing down, 0.4 s);
--   0.17  the title shows over a gradient that lights up towards the bottom (peak 0.20, gone by 0.36);
--   0.47  the jacket is uncovered from the top down (0.06 s) and the rest of the card (clear marks, level) with it;
--   the card with the cursor then swings like a door (IntroFlip, ~0.17 s; its own turn, UpdateTurn, is not used).
-- Only the cards that are on screen move (4 rows); the others are left as they are. The wheel does not take input meanwhile
-- (the overlay locks it with Screen:lockinput: BGAnimations/ScreenSelectMusic overlay/WheelIntro.lua). Like the turn, it is
-- driven by hand every frame (no tweens on the parts of a wheel item), with its own clock (see IntroFrame).
-- states: "off" (cards as they are), "pending" (the whole wheel is hidden until the overlay says go), "run".
WheelLayout.INTRO = {
	enabled = true,
	stepRow = 0.083, stepCol = 0.10,       -- seconds between two cards of the wave
	rise = 76, riseTime = 0.40,            -- the box rises this many units (about 1 px each) in this long
	riseZ = 40,                            -- and comes this many units closer to the viewer (3D: it grows ~3% and drifts outwards)
	appear = 0.04,                         -- fade in of the black box
	gradAt = 0.17, gradPeak = 0.20, gradEnd = 0.36, gradLevel = 0.38,   -- title + gradient (brightness at the bottom)
	reveal = 0.47, wipe = 0.06,            -- the jacket starts to show, and is shown in this long
	rows = 4,                              -- rows on screen counted from the bottom row
	-- The turn of the card with the cursor (measured: it swings like a door). The card closes around its RIGHT edge (the left
	-- edge goes away from the viewer) until it is edge-on, and the selected card opens from its LEFT edge (the right edge comes
	-- towards the viewer), both at a steady pace. The jacket and the texts fade out in the first part and back in in the second.
	flipBack = 0.084, flipFront = 0.083, jacketOut = 0.034, cardHalf = 64,
}
local intro = { state = "off", id = 0, time = 0 }

function WheelLayout.IntroState() return intro.state end

-- The cards are hidden (the whole wheel goes transparent) until WheelLayout.IntroStart.
function WheelLayout.IntroPending()
	if not WheelLayout.INTRO.enabled then return end
	intro.state = "pending"
end

-- Plays the animation now. Returns false (and does nothing) while the layout is not ready to place the cards.
function WheelLayout.IntroStart()
	local I = WheelLayout.INTRO
	if not I.enabled or not state.active or focusIndex == nil then return false end
	intro.state = "run"
	intro.id = intro.id + 1
	intro.time = 0               -- the animation's own clock: it only counts frames of up to 0.05 s (see IntroFrame)
	intro.last = GetTimeSinceStart()
	intro.length = I.stepRow * (I.rows - 1) + I.stepCol * 2 + I.reveal + I.wipe + I.flipBack + I.flipFront + 0.05
	return true
end

-- Remaining seconds of the animation (the overlay locks the input for that long).
function WheelLayout.IntroRemaining()
	if intro.state ~= "run" then return 0 end
	return math.max(0, intro.length - intro.time)
end

function WheelLayout.IntroOff()
	intro.state = "off"
end

-- every frame, with the wheel: hides it while pending, shows it again, runs the animation's clock and ends it.
-- The clock does NOT follow the real time: a frame counts for at most 0.05 s. The first time the screen is shown the engine
-- stops for a second or more (loading jackets), and with real time that stop used up the whole animation in one frame.
-- (While hidden the wheel keeps an alpha of 0.004, invisible but still drawn: an actor with alpha 0 is not drawn, and its
-- textures would be sent to the card at the first frame of the animation, which is the stop again.)
local HIDDEN_ALPHA = 0.004
local function IntroFrame(wheel)
	local now = GetTimeSinceStart()
	local dt = math.min(0.05, math.max(0, now - (intro.last or now)))
	intro.last = now
	if intro.state == "pending" then
		if not intro.hidden then intro.hidden = true; wheel:diffusealpha(HIDDEN_ALPHA) end
		return
	end
	if intro.hidden then intro.hidden = false; wheel:diffusealpha(1) end
	if intro.state == "run" then
		intro.time = intro.time + dt
		if intro.time > intro.length then intro.state = "off" end
	end
end

-- puts every part of the card back the way it is when nothing animates
local function IntroRestore(item)
	item.introDirty = false
	local p = item.introParts
	if not p then return end
	if item.inner then item.inner:visible(true) end
	if p.under then p.under:visible(true) end
	if p.seldeco then p.seldeco:visible(true) end
	if p.diff then p.diff:visible(true) end
	if p.title then p.title:visible(true) end
	if p.banner then p.banner:visible(true):cropbottom(0):diffusealpha(1) end
	if p.title then p.title:diffusealpha(1) end
	if p.diff then p.diff:diffusealpha(1) end
	if p.dark then p.dark:visible(false); p.darkA, p.darkG = nil, nil end
	local turn = item.turn
	if turn then
		if turn.introY and turn.introY ~= 0 then turn.introY = 0; turn:y(0):z(0) end
		if turn.flipOn then
			turn.flipOn = false
			turn:rotationy(0):x(0):z(0)
			turn.poseAngle = 0
		end
	end
end

-- The turn of the card with the cursor at the end of the animation: a door that closes around its right edge and opens
-- around its left edge (see WheelLayout.INTRO). The card is turned about its centre and moved so that the hinge stays still.
-- ef = seconds since the turn began.
local function IntroFlip(item, p, ef)
	local I = WheelLayout.INTRO
	local turn, half = item.turn, I.cardHalf
	item.inner:visible(true)
	p.under:visible(true)
	p.dark:visible(false)
	local angle, dx, dz, alpha, selected
	if ef < I.flipBack then
		angle = -90 * ef / I.flipBack                       -- the left edge goes away
		local r = math.rad(angle)
		dx, dz = half * (1 - math.cos(r)), half * math.sin(r)
		alpha = math.max(0, 1 - ef / I.jacketOut)
		selected = false
	else
		local x = (ef - I.flipBack) / I.flipFront
		angle = 90 * (1 - x)                                -- the right edge comes closer
		local r = math.rad(angle)
		dx, dz = -half * (1 - math.cos(r)), -half * math.sin(r)
		alpha = x
		selected = true
	end
	p.seldeco:visible(selected)
	p.banner:visible(true):cropbottom(0):diffusealpha(alpha)
	p.title:visible(true):diffusealpha(alpha)
	p.diff:visible(true):diffusealpha(alpha)
	turn.flipOn = true
	turn:rotationy(angle):x(dx):z(dz)
end

-- Brightness at the bottom of the dark cell at e seconds: nothing, a quick rise to the peak, a slower fall to nothing.
local function Gradient(e, I)
	if e < I.gradAt then return 0 end
	if e < I.gradPeak then return I.gradLevel * (e - I.gradAt) / (I.gradPeak - I.gradAt) end
	if e < I.gradEnd then return I.gradLevel * (1 - (e - I.gradPeak) / (I.gradEnd - I.gradPeak)) end
	return 0
end

-- Poses one card for the animation. Returns true when the card is being animated (its turn must not run).
local function UpdateIntro(item)
	local I = WheelLayout.INTRO
	if intro.state ~= "run" then
		if item.introDirty then IntroRestore(item) end
		return false
	end
	local p, turn, inner = item.introParts, item.turn, item.inner
	local j = item.layoutJ
	if not (p and turn and inner and p.under and p.dark and p.banner and p.title and p.seldeco and p.diff)
			or j == nil or j == 0 or item.layoutY == nil or item.dataIndex == nil then
		if item.introDirty then IntroRestore(item) end
		return false
	end
	-- row counted from the bottom row on screen (the cursor row is at y = 0, the next one down at +ROW)
	local rowsUp = math.floor((ROW - item.layoutY) / ROW + 0.5)
	if rowsUp < 0 or rowsUp > I.rows - 1 then
		if item.introDirty then IntroRestore(item) end
		return false
	end
	local delay = I.stepRow * rowsUp + I.stepCol * (2 - item.layoutCol)
	local e = intro.time - delay
	local done = I.reveal + I.wipe

	if e < 0 then
		item.introDirty = true
		inner:visible(false)
		return true
	end

	if e >= done then
		-- finished: the card is as it always is; the one with the cursor turns first (its own turn is not used)
		local cursor = (item.dataIndex == state.cursorNow)
		local ef = e - done
		if cursor and ef < I.flipBack + I.flipFront then
			item.introDirty = true
			IntroFlip(item, p, ef)
			return true
		end
		if item.introDirty then IntroRestore(item) end
		if cursor and item.introStamp ~= intro.id then
			item.introStamp = intro.id
			turn.turnIndex = item.dataIndex   -- (no second turn)
			turn.turnDone = true
		end
		return false
	end

	item.introDirty = true
	inner:visible(true)
	WHITE = WHITE or color("#FFFFFF")
	DARK = DARK or color(WheelLayout.TURN.dark)
	Pose(turn, 0, false)
	-- the box rises into its place and slows down
	local k = 1 - math.min(1, e / I.riseTime)
	local dy = I.rise * k * k
	if turn.introY ~= dy then turn.introY = dy; turn:y(dy):z(-I.riseZ * k * k) end

	p.under:visible(false)
	p.seldeco:visible(false)
	p.diff:visible(false)
	p.title:visible(e >= I.gradAt)
	p.dark:visible(true)
	local a = math.min(1, e / I.appear)
	local g = math.floor(Gradient(e, I) * 100 + 0.5) / 100
	if p.darkA ~= a or p.darkG ~= g then
		p.darkA, p.darkG = a, g
		p.dark:diffusetopedge({ 0, 0, 0, a }):diffusebottomedge({ g, g, g, a })
	end
	if e >= I.reveal then
		p.banner:visible(true):cropbottom(1 - (e - I.reveal) / I.wipe)   -- the jacket is uncovered from the top down
	else
		p.banner:visible(false)
	end
	return true
end

-- [MusicWheel] ItemTransformFunction
function WheelLayout.Transform(item, offset)
	item:z(1 - math.abs(offset))
	if not PlaceItem(item, offset) then
		item:x(0)
		item:y(offset * 105)
	else
		if not UpdateIntro(item) then UpdateTurn(item) end   -- (the engine also positions the items at the ends that Update does not reach)
	end
end

-- Every frame, with the wheel: the items are placed here too, so that the view keeps easing toward its row even when
-- the engine does not ask for positions (it only does while the wheel moves).
local SLOTS
function WheelLayout.Update(wheel)
	if not wheel then return end
	IntroFrame(wheel)
	if not SLOTS then SLOTS = THEME:GetMetric("MusicWheel", "NumWheelItems") end
	if not Prepare() then return end
	-- At rest nothing has to be placed again: the engine keeps the positions. The items are only walked while the view
	-- or the cursor moved, or a Set message came (WheelLayout.Touch), and for a moment after (the turn of a card).
	if IDLE_SKIP and GetTimeSinceStart() - (state.activity or 0) > 0.6 then return end
	local middle = math.floor(SLOTS / 2)
	for slot = 0, SLOTS - 1 do
		local ok, item = pcall(wheel.GetWheelItem, wheel, slot)
		if ok and item then
			PlaceItem(item, slot - middle)
			if not UpdateIntro(item) then UpdateTurn(item) end
		end
	end
end
