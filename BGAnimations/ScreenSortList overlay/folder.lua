-- The FOLDER screen (see Scripts/08 Filter.lua, "Folders"), drawn inside the sort menu screen like the filter menu.
-- default.lua opens it with FolderMenu.Open() and sends it the buttons through FolderMenu.Input(event).
-- FolderMenu.OnClose (set by default.lua) is called when it closes (with the folder the player chose, or without a
-- change when the player went back).
--
-- Layout measured from a video of the original (positions in a 1280 x 720 screen):
--   * a banner with the name of the folder and two lines about it, above a row of folder cards
--   * the chosen card (LEFT / RIGHT moves, the row is circular) is bright with a teal bar; the others are gray. The
--     chosen card always starts at the same x; the cards after it follow, each one as wide as it is (ALL MUSIC is wider)
--   * a "Playable difficulty" panel below the chosen card: the difficulties the folder has (3 rows; ALL MUSIC has 5)
--   * START chooses the folder, BACK leaves it as it was
--
-- Textures (BGAnimations/ScreenSortList overlay/folder/), drawn at their own size; a colored rectangle (or plain
-- text) is drawn while a PNG is missing. A card is made of layers, each one with an _on (chosen) and _off version:
--   folder_base_<on|off>.png               the card (dark, with its tab); folder_base_allmusic_<on|off>.png for ALL MUSIC
--   folder_bg_<name>_<on|off>.png          the art behind the logo
--   folder_text_<name>_<on|off>.png        the logo
--       <name>: firststep, popmusic, virtualpop, animegame, touhou, musicgamers, allmusic
--       (the chosen ANIME & GAME logo is also looked for as animegames: that is how it is named now)
--   folder_button.png                      the square at the right of the bar of the chosen card
--   folder_desc_bg.png                     the banner behind the name and the two lines
--   folder_difficulty_limit_3diff.png / _5diff.png   the "Playable difficulty" panel (3 rows / 5 rows)
-- ============================================================================
FolderMenu = {}

-- ---------------------------------------------------------------- layout (screen pixels, 1280 x 720)
local LEFT = 316                 -- left edge of the chosen card
local CARD_Y = 331               -- middle of the cards
local GAP = 6                    -- between two cards
local BANNER = { x = LEFT + 252, y = 180 }                      -- center of folder_desc_bg (504 x 108)
local BANNER_TEXT_X = LEFT + 17
local PANEL = { x = 441, y = 527 }                              -- center of the difficulty panel (288 x 180)
local ROW = { first = 479, step = 24, labelX = 338, boxX = 483 } -- rows of the difficulty panel

-- the card textures (their opaque part is 238 x 200 and 316 x 200: the card is 238 / 316 wide; the images have a few
-- pixels of shadow around, 4 on the left)
local CARDS = {
	normal = { w = 238, baseW = 248, bgH = 164, textH = 126 },
	all    = { w = 316, baseW = 324, bgH = 154, textH = 154 },
}
local BASE_TOP = -106            -- top of the base image, from the middle of the card (the image is 212 high)
local SHADOW_LEFT = 4            -- pixels of shadow at the left of the base image

-- the moving stripes along the bottom of the chosen card's bar (the same pattern as the options menu: 13 px period, 7 px
-- black, leaning 3 px; speed in pixels per second)
local STRIPES = { y = 87, h = 6, period = 13, black = 7, slant = 3, speed = 20 }

-- the "hover" of the card that gets the cursor, measured from the original at 30 fps: the row jumps at once and the new
-- card arrives small and tilted, straightens past the vertical and settles, in about 0.1 s. tilt: degrees (the sign
-- is the direction), the steps are { seconds, zoom, tilt }
local POP = { start = { zoom = 0.65, tilt = -30 }, steps = { { 0.035, 0.9, -12 }, { 0.035, 1.02, 5 }, { 0.035, 1, 0 } } }
local FADE_TEXT = 0.1            -- seconds the title and the two lines of the banner take to appear

local FONT = "_swis721 blk bt 28px"
local UI_FONT = "_avenirnext lt pro bold Bold 20px"   -- texts of the cards, the banner and the panel (sizes measured on a capture of the original)
local ACCENT = color("#19D3B0")
local YELLOW = color("#F2C230")

-- placeholder colors of the cards (chosen), used when the card has no textures
local COLORS = {
	FIRST = color("#13B89C"), POP = color("#F2A71B"), VIRTUAL = color("#2E8B57"), ANIME = color("#E0599A"),
	TOUHOU = color("#C93A3A"), GAMERS = color("#B8203A"), ALL = color("#6A6A6A"),
}
-- file names of each folder (see the list above)
local TEXTURE_NAMES = { FIRST = { "firststep" }, POP = { "popmusic" }, VIRTUAL = { "virtualpop" },
	ANIME = { "animegame", "animegames" }, TOUHOU = { "touhou" }, GAMERS = { "musicgamers" }, ALL = { "allmusic" } }

local DIFFICULTIES = {
	{ id = "Difficulty_Beginner", label = "Beginner", c = color("#1BA6E8"), text = "First, this!" },
	{ id = "Difficulty_Easy", label = "Basic", c = color("#F2B800"), text = "Next Steps!" },
	{ id = "Difficulty_Medium", label = "Difficult", c = color("#E8383D"), text = "Go for it!" },
	{ id = "Difficulty_Hard", label = "Expert", c = color("#3BC447"), text = "For experts!" },
	{ id = "Difficulty_Challenge", label = "Challenge", c = color("#B23AD6"), text = "The ultimate!" },
}

local function ThemeFile(rel)
	local dir = THEME:GetCurrentThemeDirectory()
	if string.sub(dir, 1, 1) ~= "/" then dir = "/" .. dir end
	if string.sub(dir, -1) ~= "/" then dir = dir .. "/" end
	return dir .. rel
end

local function TexturePath(name)
	local path = ThemeFile("BGAnimations/ScreenSortList overlay/folder/" .. name .. ".png")
	if FILEMAN:DoesFileExist(path) then return path end
	return nil
end

-- the texture of a layer ("bg" / "text") of a folder in a state ("on" / "off"): the first name that exists
local function LayerPath(layer, id, state)
	for _, name in ipairs(TEXTURE_NAMES[id]) do
		local path = TexturePath("folder_" .. layer .. "_" .. name .. "_" .. state)
		if path then return path end
	end
	return nil
end

local function Text(x, y, zoom, align, c, text)
	return Def.BitmapText{
		Font = FONT, Text = text,
		InitCommand = function(s) s:xy(x, y):zoom(zoom):halign(align):diffuse(c) end,
	}
end

-- ---------------------------------------------------------------- state
local FOLDERS = Filter.Folders
local N = #FOLDERS
local index = N                -- the folder under the cursor
local refs = { cards = {}, rows = {} }
local rootActor
local opened = false

-- The row does not wrap around: LEFT stops at FIRST STEP and RIGHT at ALL MUSIC.
local function Rel(i)
	return i - index
end

local function WidthOf(i)
	return (FOLDERS[i].id == "ALL" and CARDS.all or CARDS.normal).w
end

-- x of the left edge of every card: the chosen one at LEFT, the ones after it to the right, the ones before it to the left
local function Lefts()
	local lefts = {}
	lefts[index] = LEFT
	local left = LEFT
	for i = index - 1, 1, -1 do
		left = left - GAP - WidthOf(i)
		lefts[i] = left
	end
	local right = LEFT + WidthOf(index) + GAP
	for i = index + 1, N do
		lefts[i] = right
		right = right + WidthOf(i) + GAP
	end
	return lefts
end

-- ---------------------------------------------------------------- drawing
-- animate: the cards slide to their place (false: they are placed at once)
local function Refresh(animate)
	if not rootActor then return end
	local current = FOLDERS[index]
	local lefts = Lefts()

	for i, f in ipairs(FOLDERS) do
		local card = refs.cards[i]
		if card then
			local rel = Rel(i)
			local on = (rel == 0)
			-- the row jumps to its new place at once (the original does not slide it)
			local gained = on and animate and card.rel ~= 0
			card.rel = rel
			card.frame:x(lefts[i])
			card.pop:stoptweening():zoom(1):rotationz(0)
			if gained then
				card.pop:zoom(POP.start.zoom):rotationz(POP.start.tilt)
				for _, step in ipairs(POP.steps) do card.pop:linear(step[1]):zoom(step[2]):rotationz(step[3]) end
			end
			for _, s in ipairs(card.ons) do s:visible(on) end
			for _, s in ipairs(card.offs) do s:visible(not on) end
			if card.back then card.back:diffuse(on and COLORS[f.id] or color("#4A4A4A")) end
			if card.name then card.name:diffuse(on and color("#FFFFFF") or color("#9A9A9A")) end
			card.barBack:diffuse(on and ACCENT or color("#2B2B2B"))
			card.barText:diffuse(on and color("#FFFFFF") or color("#8A8A8A"))
			card.arrow:diffuse(on and color("#FFFFFF") or color("#8A8A8A"))
			if card.stripesActor then card.stripesActor:visible(on) end
			card.check:visible(on)
			card.label:diffuse(on and ACCENT or color("#CFCFCF"))
			card.labelBack:diffuse(on and color("#00000066") or color("#00000044"))
		end
	end

	-- banner
	refs.title:settext(current.name)
	refs.desc1:settext(current.desc[1] or "")
	refs.desc2:settext(current.desc[2] or "")
	if animate then
		for _, text in ipairs({ refs.title, refs.desc1, refs.desc2 }) do
			text:stoptweening():diffusealpha(0):linear(FADE_TEXT):diffusealpha(1)
		end
	end

	-- difficulties of the folder: 3 rows, 5 for ALL MUSIC
	local rows = (current.id == "ALL") and 5 or 3
	if refs.panel3 then refs.panel3:visible(rows == 3) end
	if refs.panel5 then refs.panel5:visible(rows == 5) end
	local _, have = Filter.FolderStats(current.id)
	for i, d in ipairs(DIFFICULTIES) do
		local row = refs.rows[i]
		if row then
			row.label:visible(i <= rows)
			row.box:visible(i <= rows)
			row.text:visible(i <= rows)
			local ok = have[d.id] == true
			row.label:diffuse(ok and d.c or color("#9A9A9A"))
			row.box:diffuse(ok and d.c or color("#9E9E9E"))
			row.text:settext(ok and d.text or "not selectable")
			row.text:diffuse(ok and color("#FFFFFF") or color("#F0F0F0"))
		end
	end
end

-- ---------------------------------------------------------------- input
local function Sound(name)
	if rootActor then
		local s = rootActor:GetParent() and rootActor:GetParent():GetChild(name)
		if s then s:play() end
	end
end

-- chosen: true when the player CHOSE a folder (START), false when the screen was left with BACK
local function Close(chosen)
	opened = false
	if FolderMenu.OnClose then FolderMenu.OnClose(chosen) end
end

-- Leaves the screen like BACK does (the menu timer ran out): the folder stays as it was.
function FolderMenu.Cancel()
	Close()
end

function FolderMenu.Open()
	-- opens on the folder that is on now
	index = N
	local now = Filter.GetFolder()
	for i, f in ipairs(FOLDERS) do
		if f.id == now then index = i end
	end
	opened = true
	for _, card in ipairs(refs.cards) do card.rel = nil end
	if refs.hint then refs.hint:setstate((GetCurrentLanguage and GetCurrentLanguage()) or 0) end   -- (the language may have changed)
	if rootActor then
		rootActor:stoptweening():visible(true):diffusealpha(0):sleep(0.1):linear(0.15):diffusealpha(1)
		-- (stopping the tweens of the menu also stopped the loops that move the stripes of the cards: they start again)
		MESSAGEMAN:Broadcast("FolderStripesRestart")
	end
	Refresh(false)
end

function FolderMenu.Hide()
	opened = false
	if rootActor then rootActor:visible(false) end
end

function FolderMenu.Input(event)
	if not event.GameButton or event.type == "InputEventType_Release" then return false end
	local b = event.GameButton

	if b == "MenuLeft" or b == "Left" then
		if index > 1 then   -- (it stops at FIRST STEP)
			index = index - 1
			Sound("folder_change")
			Refresh(true)
		end
	elseif b == "MenuRight" or b == "Right" then
		if index < N then   -- (and at ALL MUSIC)
			index = index + 1
			Sound("folder_change")
			Refresh(true)
		end
	elseif b == "Start" then
		local before = Filter.GetFolder()
		Filter.SetFolder(FOLDERS[index].id)
		if Filter.Active() and Filter.Count() == 0 then
			-- nothing would be listed: the folder stays as it was
			Filter.SetFolder(before)
			Sound("folder_change")
		else
			Sound("start_sound")
			Close(true)
		end
	elseif b == "Back" then
		Sound("start_sound")
		Close()
	end
	return true
end

-- ---------------------------------------------------------------- actors
local t = Def.ActorFrame{
	InitCommand = function(s)
		rootActor = s
		-- the layout is in a 1280 pixel wide screen; the theme's own coordinates are smaller (1.5x on this one)
		s:zoom(SCREEN_WIDTH / 1280)
		s:visible(false)
	end,
}

-- banner
do
	local path = TexturePath("folder_desc_bg")
	if path then
		t[#t + 1] = Def.Sprite{ Texture = path, InitCommand = function(s) s:xy(BANNER.x, BANNER.y) end }
	else
		t[#t + 1] = Def.Quad{ InitCommand = function(s) s:xy(BANNER.x, BANNER.y):zoomto(486, 84):diffuse(color("#262626F2")) end }
	end
	t[#t + 1] = Def.BitmapText{ Font = UI_FONT, Text = "",
		InitCommand = function(s) refs.title = s; s:xy(BANNER_TEXT_X, 163):halign(0):zoom(1.9):maxwidth(450 / 1.9):diffuse(color("#FFFFFF")) end }
	t[#t + 1] = Def.BitmapText{ Font = UI_FONT, Text = "",
		InitCommand = function(s) refs.desc1 = s; s:xy(BANNER_TEXT_X, 190):halign(0):zoom(0.7):maxwidth(450 / 0.7):diffuse(YELLOW) end }
	t[#t + 1] = Def.BitmapText{ Font = UI_FONT, Text = "",
		InitCommand = function(s) refs.desc2 = s; s:xy(BANNER_TEXT_X, 205):halign(0):zoom(0.7):maxwidth(450 / 0.7):diffuse(YELLOW) end }
end

-- the "Playable difficulty" panel
do
	local p3, p5 = TexturePath("folder_difficulty_limit_3diff"), TexturePath("folder_difficulty_limit_5diff")
	if p3 and p5 then
		t[#t + 1] = Def.Sprite{ Texture = p3, InitCommand = function(s) refs.panel3 = s; s:xy(PANEL.x, PANEL.y) end }
		t[#t + 1] = Def.Sprite{ Texture = p5, InitCommand = function(s) refs.panel5 = s; s:xy(PANEL.x, PANEL.y):visible(false) end }
	else
		t[#t + 1] = Def.Quad{ InitCommand = function(s) s:xy(PANEL.x, PANEL.y - 10):zoomto(239, 150):diffuse(color("#F2F2F2E6")) end }
	end
	-- the title of the panel: folder_text_playdiff.png when it exists (at its own size, its left edge on the ribbon),
	-- otherwise the text (the original writes it in italics: a skew does the same)
	local playdiff = TexturePath("folder_text_playdiff")
	if playdiff then
		t[#t + 1] = Def.Sprite{ Texture = playdiff, InitCommand = function(s) s:xy(PANEL.x - 138, 449):halign(0) end }
	else
		t[#t + 1] = Def.BitmapText{ Font = UI_FONT, Text = "Playable difficulty",
			InitCommand = function(s) s:xy(PANEL.x - 134, 449):halign(0):zoom(0.7):skewx(-0.2):diffuse(color("#FFFFFF")) end }
	end
	for i, d in ipairs(DIFFICULTIES) do
		local y = ROW.first + (i - 1) * ROW.step
		t[#t + 1] = Def.BitmapText{ Font = UI_FONT, Text = d.label,
			InitCommand = function(s) refs.rows[i] = refs.rows[i] or {}; refs.rows[i].label = s
				s:xy(ROW.labelX, y):halign(0):zoom(0.8):skewx(-0.25):diffuse(d.c) end }
		t[#t + 1] = Def.Quad{ InitCommand = function(s) refs.rows[i] = refs.rows[i] or {}; refs.rows[i].box = s
			s:xy(ROW.boxX, y):zoomto(115, 18):diffuse(d.c) end }
		t[#t + 1] = Def.BitmapText{ Font = UI_FONT, Text = "",
			InitCommand = function(s) refs.rows[i] = refs.rows[i] or {}; refs.rows[i].text = s
				s:xy(ROW.boxX, y):zoom(0.5):maxwidth(105 / 0.5):diffuse(color("#FFFFFF")) end }
	end
end

-- the cards (drawn after the banner and the panel; each one is a frame that slides). In a card frame x = 0 is the left
-- edge of the card and y = 0 its middle.
for i, f in ipairs(FOLDERS) do
	local size = (f.id == "ALL") and CARDS.all or CARDS.normal
	local card = { ons = {}, offs = {} }
	refs.cards[i] = card
	-- outer: where the card is; pop: turns around the middle of the card (the "hover" of the chosen card); frame: holds
	-- the parts, x = 0 at the left edge of the card
	local frame = Def.ActorFrame{
		InitCommand = function(s) s:x(-size.w / 2) end,
	}

	-- a layer with an _on and an _off texture, centered at x, y of the card
	local function Layer(onPath, offPath, x, y)
		frame[#frame + 1] = Def.Sprite{ Texture = offPath, InitCommand = function(s)
			card.offs[#card.offs + 1] = s; s:xy(x, y) end }
		frame[#frame + 1] = Def.Sprite{ Texture = onPath, InitCommand = function(s)
			card.ons[#card.ons + 1] = s; s:xy(x, y) end }
	end

	-- the card itself
	local base = (f.id == "ALL") and "folder_base_allmusic_" or "folder_base_"
	local baseOn, baseOff = TexturePath(base .. "on"), TexturePath(base .. "off")
	if baseOn and baseOff then
		Layer(baseOn, baseOff, size.baseW / 2 - SHADOW_LEFT, 0)
	else
		frame[#frame + 1] = Def.Quad{ InitCommand = function(s) card.back = s; s:xy(size.w / 2, 0):zoomto(size.w, 189) end }
	end

	-- the art and the logo: top of the card, centered
	local bgOn, bgOff = LayerPath("bg", f.id, "on"), LayerPath("bg", f.id, "off")
	if bgOn and bgOff then Layer(bgOn, bgOff, size.w / 2, BASE_TOP + 2 + size.bgH / 2) end
	local txOn, txOff = LayerPath("text", f.id, "on"), LayerPath("text", f.id, "off")
	if txOn and txOff then
		Layer(txOn, txOff, size.w / 2, BASE_TOP + size.textH / 2)
	else
		frame[#frame + 1] = Def.BitmapText{ Font = FONT, Text = f.name,
			InitCommand = function(s) card.name = s; s:xy(size.w / 2, -34):zoom(0.9):maxwidth((size.w - 24) / 0.9) end }
	end

	-- label (the name of the folder, under the art) and the bar at the bottom (positions and sizes of the original)
	frame[#frame + 1] = Def.Quad{ InitCommand = function(s) card.labelBack = s; s:xy(size.w / 2, 45):zoomto(size.w, 24) end }
	frame[#frame + 1] = Def.BitmapText{ Font = UI_FONT, Text = f.label,
		InitCommand = function(s) card.label = s; s:xy(size.w / 2, 45):zoom(0.92):maxwidth((size.w - 20) / 0.92) end }
	frame[#frame + 1] = Def.Quad{ InitCommand = function(s) card.barBack = s; s:xy(size.w / 2, 75):zoomto(size.w, 36) end }

	-- the diagonal stripes that run from left to right on what is selected all over the theme, made by code (like the
	-- ones of the options menu): black slanted stripes over the bar that move to the right in a loop, along its bottom edge
	frame[#frame + 1] = Def.ActorFrame{
		InitCommand = function(s) card.stripesActor = s; s:xy(0, STRIPES.y):visible(false) end,
		Def.ActorMultiVertex{
			InitCommand = function(s) s:SetDrawState{ Mode = "DrawMode_Quads" } end,
			OnCommand = function(s) s:playcommand("Tick") end,
			FolderStripesRestartMessageCommand = function(s) s:stoptweening():playcommand("Tick") end,
			TickCommand = function(s)
				-- only worked out while the card is the chosen one (its frame is visible)
				local p = s:GetParent()
				if p and p:GetVisible() then
					local off = (GetTimeSinceStart() * STRIPES.speed) % STRIPES.period
					local v = {}
					local black = color("0,0,0,1")
					local function cx(x) return math.max(0, math.min(size.w, x)) end   -- clipped to the card
					for k = -1, math.floor(size.w / STRIPES.period) + 1 do
						local x0 = k * STRIPES.period + off   -- + moves from left to right
						v[#v + 1] = { { cx(x0), STRIPES.h, 0 }, black }
						v[#v + 1] = { { cx(x0 + STRIPES.black), STRIPES.h, 0 }, black }
						v[#v + 1] = { { cx(x0 + STRIPES.black + STRIPES.slant), 0, 0 }, black }
						v[#v + 1] = { { cx(x0 + STRIPES.slant), 0, 0 }, black }
					end
					s:SetVertices(v)
				end
				s:sleep(1 / 60):queuecommand("Tick")
			end,
		},
	}

	-- "▼ SELECT MUSIC": the triangle is drawn (the font has no such character). Triangle and text are centered together
	-- on the card (the text is measured once it exists)
	frame[#frame + 1] = Def.ActorMultiVertex{
		InitCommand = function(s)
			card.arrow = s
			local c = { 1, 1, 1, 1 }
			s:SetDrawState{ Mode = "DrawMode_Triangles" }
			s:SetVertices{ { { -6, -5, 0 }, c }, { { 6, -5, 0 }, c }, { { 0, 5, 0 }, c } }
			s:xy(size.w / 2 - 70, 75)
		end,
	}
	frame[#frame + 1] = Def.BitmapText{ Font = UI_FONT, Text = "SELECT MUSIC",
		InitCommand = function(s)
			card.barText = s
			s:zoom(0.95):halign(0)
			local textW = s:GetZoomedWidth()
			local total = 12 + 8 + textW                    -- triangle, space, text
			local left = size.w / 2 - total / 2
			if card.arrow then card.arrow:x(left + 6) end
			s:xy(left + 20, 75)
		end }
	local button = TexturePath("folder_button")
	if button then
		frame[#frame + 1] = Def.Sprite{ Texture = button, InitCommand = function(s) card.check = s; s:xy(size.w - 22, 75) end }
	else
		frame[#frame + 1] = Def.Quad{ InitCommand = function(s) card.check = s; s:xy(size.w - 22, 75):zoomto(14, 14):diffuse(color("#FFFFFF")) end }
	end

	t[#t + 1] = Def.ActorFrame{
		InitCommand = function(s) card.frame = s; s:xy(LEFT, CARD_Y) end,
		Def.ActorFrame{
			InitCommand = function(s) card.pop = s; s:x(size.w / 2) end,
			frame,
		},
	}
end
	
return t
