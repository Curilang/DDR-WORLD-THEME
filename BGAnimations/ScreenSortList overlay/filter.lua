-- The FILTER menu (see Scripts/08 Filter.lua), drawn inside the sort menu screen. default.lua opens it with
-- FilterMenu.Open() and sends it the buttons through FilterMenu.Input(event) while it is open.
-- FilterMenu.OnClose (set by default.lua) is called when the menu closes with the filter the player chose.
--
-- Layout and behavior measured from a video of the original (positions in a 1280 x 720 screen):
--   * it opens on the values of the category the player used last ("Filter Switch" state): the panel is gray and the
--     values are white. BACK goes to the category list (white panel); BACK there closes.
--   * SIMPLE (the default): START picks the value and closes at once ("Decide and Close"). NORMAL: START marks or
--     unmarks values, BACK closes. LEFT on the category list changes between the two.
--   * a cursor (cyan), the chosen values (black box), a small marker at the left of every value.
--
-- Textures (BGAnimations/ScreenSortList overlay/filter/), drawn at their own size; a plain colored rectangle is
-- drawn while a PNG is missing:
--   filter_bg.png (584x532)      the white panel with its shadow
--   filter_title.png (198x134)   the "Filter" logo
--   filter_switch.png (584x532)  shown while the cursor is in the values ("Filter Switch"): darkens the panel and
--                                leaves the values area open, with its border and banner
--   filter_fade.png (260x352)    covers the values area while the cursor is in the category list
--   count.png (120x82), back.png (194x32), deselect.png (226x32): optional
-- ============================================================================
FilterMenu = {}

-- ---------------------------------------------------------------- layout (screen pixels, 1280 x 720)
local PANEL = { x = 634, y = 357, w = 542, h = 509 }
local CAT_X, CAT_Y, CAT_STEP = 408, 208, 29               -- category list: left edge of the cursor, first row, step
local GRID = { x = 750, y = 360, w = 255, h = 347 }       -- area of the values (center)
local GRID_LEFT, GRID_TOP = 645, 232                      -- left marker of the first column, center of the first row
local ROW_H, ROWS = 26, 10
local COUNT = { x = 948, y = 269, w = 120, h = 82 }
local BACK = { x = 501, y = 572, w = 194, h = 32 }
local DESELECT = { x = 750, y = 572, w = 226, h = 32 }
local INNER_DESELECT = { x = 750, y = 507, w = 211, h = 27 }   -- the button inside the values area

local ACCENT = color("#00DDB0")
local ACCENT_DARK = color("#0B5C40")
local VALUE_TEAL = color("#0C9E86")
local TEXT_DARK = color("#101010")
local FONT = "_swis721 blk bt 28px"       -- the big texts (title, banner, count) and the small icons
-- TEST (2026-11-06): the sentences and the Simple / Normal / Back texts use the theme's vector-made font Avenir Next Bold
-- (smooth, even letters) instead of the pixel fonts made from textures. Set AVENIR_TEST = false to go back to the pixel fonts.
local AVENIR_TEST = false
local AV_FONT = "_avenirnext lt pro bold Bold 20px"
local AV_ZOOM = 0.78                        -- Avenir at zoom 1 is ~14 px tall in capitals; the pixel font's are 11
-- sets the font's zoom and the maximum final width (maxwidth is measured before the zoom)
local function FitText(s, maxw)
	if AVENIR_TEST then s:zoom(AV_ZOOM); if maxw then s:maxwidth(maxw / AV_ZOOM) end
	elseif maxw then s:maxwidth(maxw) end
end
local SENT_FONT = AVENIR_TEST and AV_FONT or "Options Sentence Text"   -- Options Text narrowed to 82 % and re-spaced (Fonts/Options Sentence Text): for the sentences with lower case, so they are not squeezed by code
local TEXTURE_FONT = "Options Text"      -- the one made from the original's textures (capitals of the labels)
local UI_FONT = TEXTURE_FONT            -- the menu's own text (Fonts/Options Text): pixel font made from the original's textures, drawn at zoom 1
local KANA_FONT = "_dfghsw9 18px"         -- (the theme's Japanese font) for the kana of MUSIC TITLE and the genre with kana
local STRIPES = "_shared/line"            -- diagonal stripes that run along the bottom of what is selected

local function ThemeFile(rel)
	local dir = THEME:GetCurrentThemeDirectory()
	if string.sub(dir, 1, 1) ~= "/" then dir = "/" .. dir end
	if string.sub(dir, -1) ~= "/" then dir = dir .. "/" end
	return dir .. rel
end

-- A texture slot: the PNG when it exists, a colored rectangle when it does not.
local function Slot(name, x, y, w, h, c)
	local path = ThemeFile("BGAnimations/ScreenSortList overlay/filter/" .. name .. ".png")
	if FILEMAN:DoesFileExist(path) then
		return Def.Sprite{ Texture = path, InitCommand = function(s) s:xy(x, y):zoomto(w, h) end }
	end
	return Def.Quad{ InitCommand = function(s) s:xy(x, y):zoomto(w, h):diffuse(c) end }
end

-- true when the texture file exists
local function TexturePath(name)
	local path = ThemeFile("BGAnimations/ScreenSortList overlay/filter/" .. name .. ".png")
	if FILEMAN:DoesFileExist(path) then return path end
	return nil
end

-- The versions of the VERSION category have their own textures, in two sheets (white: they are colored here):
--   filter/version 1x9.png  WORLD, A3, A20 - A20 PLUS, A, 2013 - 2014, X - X3 VS 2ndMIX, SuperNOVA - SuperNOVA2, MAX - EXTREME,
--                           1st - 5thMIX (104 x 20 each, one above the other)
--   filter/group 1x3.png    GOLD, WHITE, CLASSIC (64 x 20 each)
-- Returns the path of the sheet and the frame (0 ...) of a value, or nil when it has no texture (it is drawn as text).
local VERSION_FRAMES = {
	WORLD = { "version 1x9", 0 }, A3 = { "version 1x9", 1 }, A20 = { "version 1x9", 2 }, A = { "version 1x9", 3 },
	["2013"] = { "version 1x9", 4 }, X = { "version 1x9", 5 }, SN = { "version 1x9", 6 }, MAX = { "version 1x9", 7 },
	["1ST"] = { "version 1x9", 8 },
	GOLD = { "group 1x3", 0 }, WHITE = { "group 1x3", 1 }, CLASSIC = { "group 1x3", 2 },
}
local sheetPaths = {}
local function VersionTexture(id)
	local entry = VERSION_FRAMES[id]
	if not entry then return nil end
	local path = sheetPaths[entry[1]]
	if path == nil then
		path = TexturePath(entry[1]) or false
		sheetPaths[entry[1]] = path
	end
	if not path then return nil end
	return path, entry[2]
end

-- The groups of MUSIC TITLE have their own textures (filter/filter_title_<name>.png, 44 x 20, white: they are colored here, like
-- the versions). Returns the path of the one of a value (a kana row or a group of letters) or nil when it has none.
local TITLE_FILES = {
	K_A = "line_a", K_KA = "line_ka", K_SA = "line_sa", K_TA = "line_ta", K_NA = "line_na",
	K_HA = "line_ha", K_MA = "line_ma", K_YA = "line_ya", K_RA = "line_ra", K_WA = "line_wa",
	ABC = "abc", DEF = "def", GHI = "ghi", JKL = "jkl", MNO = "mno", PQR = "pqr", STU = "stu", VWX = "vwx", YZ = "yz",
	OTHER = "other",
}
local titlePaths = {}
local function TitleTexture(id)
	local name = TITLE_FILES[id]
	if not name then return nil end
	local path = titlePaths[id]
	if path == nil then
		path = TexturePath("filter_title_" .. name) or false
		titlePaths[id] = path
	end
	return path or nil
end

-- A texture at its own size, centered on x, y; a w x h rectangle of color c when the file is missing.
local function Tex(name, x, y, w, h, c)
	local path = TexturePath(name)
	if path then
		return Def.Sprite{ Texture = path, InitCommand = function(s) s:xy(x, y) end }
	end
	return Def.Quad{ InitCommand = function(s) s:xy(x, y):zoomto(w, h):diffuse(c) end }
end

local function Box(x, y, w, h, c)
	return Def.Quad{ InitCommand = function(s) s:xy(x, y):zoomto(w, h):diffuse(c) end }
end

local function Text(x, y, zoom, align, c, text)
	return Def.BitmapText{
		Font = FONT, Text = text,
		InitCommand = function(s) s:xy(x, y):zoom(zoom):halign(align):diffuse(c) end,
	}
end

-- text in the menu's own font (zoom 1: it is drawn at its own size)
local function UText(x, y, align, c, text)
	return Def.BitmapText{
		Font = UI_FONT, Text = text,
		InitCommand = function(s) s:xy(x, y):halign(align):diffuse(c) end,
	}
end

-- The moving diagonal stripes of what is selected (made by code, like the ones of the folder screen and the options menu:
-- 13 px period, slanted, moving to the right in a loop). The frame keeps its size and color in .w .h .c (the caller
-- changes them); it only works while it is visible.
local STRIPE = { period = 13, black = 6, slant = 3, speed = 20 }
local stripeFrames = {}   -- every stripes frame: the root actor redraws the visible ones every frame (see InitCommand below)

-- draws the stripes of a frame for the width and color it has now
local function DrawStripes(p)
	local s = p.mv
	if not s then return end
	local w, h = p.w, p.h
	local off = (GetTimeSinceStart() * STRIPE.speed) % STRIPE.period
	local v = {}
	local function cx(x) return math.max(0, math.min(w, x)) - w / 2 end   -- clipped to the width
	for k = -1, math.floor(w / STRIPE.period) + 1 do
		local x0 = k * STRIPE.period + off
		v[#v + 1] = { { cx(x0), h / 2, 0 }, p.c }
		v[#v + 1] = { { cx(x0 + STRIPE.black), h / 2, 0 }, p.c }
		v[#v + 1] = { { cx(x0 + STRIPE.black + STRIPE.slant), -h / 2, 0 }, p.c }
		v[#v + 1] = { { cx(x0 + STRIPE.slant), -h / 2, 0 }, p.c }
	end
	-- (SetVertices only grows the list of vertices: the ones of an earlier, wider, drawing stayed and were drawn, still, past
	-- the end of the new stripes. The list is cut to the size of this drawing first.)
	if s.SetNumVertices then s:SetNumVertices(#v) end
	s:SetVertices(v)
end

-- (They are NOT animated with a tween loop: FilterMenu.Open stops the tweens of the whole menu, which killed the loops
-- and left the stripes still, at the width they had.)
local function Stripes(init)
	return Def.ActorFrame{
		InitCommand = function(s)
			s.w, s.h, s.c = 100, 5, color("0,0,0,1")
			stripeFrames[#stripeFrames + 1] = s
			init(s)
		end,
		Def.ActorMultiVertex{
			InitCommand = function(s) s:SetDrawState{ Mode = "DrawMode_Quads" }; s:GetParent().mv = s end,
		},
	}
end

local BLACK_STRIPES = color("0,0,0,1")

-- ---------------------------------------------------------------- state
local refs = { cats = {}, cells = {} }

-- The original's texts as textures (filter/filter_txt_*.png). Every sheet has one ROW per language (en, jp, kor: the same order as
-- GetCurrentLanguage()) and one COLUMN per state, so the frame is  language * columns + column. When a sheet is missing the
-- menu draws that text with the pixel font, as before.
local texts = {}          -- key -> { s = sprite, cols = columns, col = column now }
local function LangRow() return (GetCurrentLanguage and GetCurrentLanguage()) or 0 end
-- the sprite (centered on x, y) or nil when the sheet does not exist
local function TextSprite(key, sheet, cols, x, y)
	local path = TexturePath(sheet)
	if not path then return nil end
	return Def.Sprite{ Texture = path, InitCommand = function(s)
		local e = { s = s, cols = cols, col = 0 }
		texts[key] = e
		s:xy(x, y):animate(false):setstate(LangRow() * cols)
	end }
end
local function SetTextFrame(key, col)
	local e = texts[key]
	if e then e.col = col; e.s:setstate(LangRow() * e.cols + col) end
end
local HAS_SELMETHOD = TexturePath("filter_txt_selmethod 1x3") ~= nil          -- (Change Selection Method / Simple / Normal + key 0)
local HAS_EXPLAIN = TexturePath("filter_txt_selmethod_info 2x3") ~= nil      -- (the explanation box with its text)
local HAS_ONOFF = TexturePath("filter_txt_deselect_onoff 4x3") ~= nil        -- (the button inside the values area)
local HAS_HINT = TexturePath("filter_ope_category 1x3") ~= nil and TexturePath("filter_ope_items_simple 1x3") ~= nil
	and TexturePath("filter_ope_items_normal 1x3") ~= nil                     -- (the key help at the bottom)
-- The ひなビタ♪ & バンめし♪ genre is one texture for every language (white: it is colored like the texts, 220 x 20, the ink 2 px in).
local HINABITA_TEX = TexturePath("filter_genre_hinabita")
local HINT_X, HINT_Y = 338, 639   -- left edge of the key help textures (centered on the screen: x = 640) and the middle of their row (the ink is 2 px above it)
local function RefreshLanguage()
	for _, e in pairs(texts) do e.s:setstate(LangRow() * e.cols + e.col) end
end
-- The names of the categories as textures (filter/filter_cat_*.png, 160 x 16, black, the ink in rows 2..11). The ones that are the same in
-- every language are a single image; the others are sheets of 3 frames (en, jp, kor). ITG LEVEL / ITG VERSION have no texture:
-- they keep the pixel font.
local CAT_TEXTURES = {
	LEVEL = { "filter_cat_level" }, BPM = { "filter_cat_bpm" }, RANK = { "filter_cat_clear_rank" },
	CLEARTYPE = { "filter_cat_clear_type" }, FLARE = { "filter_cat_flare_rank" }, SKILL = { "filter_cat_flare_skill_target" },
	DIFFICULTY = { "filter_cat_difficulty 1x3", 1 }, VERSION = { "filter_cat_version 1x3", 1 },
	TITLE = { "filter_cat_music_title 1x3", 1 }, GENRE = { "filter_cat_genre 1x3", 1 }, EVENT = { "filter_cat_event 1x3", 1 },
}
local focus = "cat"        -- "cat" (category list) or "grid" (values)
-- the categories of this menu (LEVEL ITG only when there are ITG packs); fixed when the sort menu loads
local CATEGORIES = Filter.VisibleCategories()
local NCAT = #CATEGORIES
-- (the original's rows are 32 pixels apart; with the ITG categories there are more rows and they get closer)
CAT_STEP = math.min(32, math.floor(352 / NCAT))
local BACK_INDEX = NCAT + 1      -- the BACK button comes after the categories
local DESELECT_INDEX = NCAT + 2  -- and then DESELECT ALL AND CLOSE
local catIndex = 1
local cursor = 1           -- value under the cursor (n + 1 = the button inside the values area)
local scroll = 0           -- rows of values that are scrolled out at the top
local rootActor
local opened = false       -- the menu is open: scores are read in the background
local lastSimple           -- the method the Simple / Normal buttons showed the last time (nil = nothing drawn yet)

-- The explanation of the selection method ("One-push decision method." / "Multiple selection method.", on a dark box under
-- the Simple / Normal buttons). In the original it shows for two seconds when the menu opens and for two seconds after the
-- method is changed; moving between the category list and the values does not show it. When it shows, the header (icon, title and buttons) goes up 19 px and
-- the box appears (a fade, from its top edge down); when it hides, the box fades out quickly and the header comes down,
-- slowing at the end. It is moved by the update function of the menu, not by tweens (FilterMenu.Open stops the tweens).
local EXPLAIN = { drop = 19, hold = 2, head = 0, box = 0, untilTime = nil, last = nil }

local function ExplainWanted()
	return EXPLAIN.untilTime ~= nil and GetTimeSinceStart() < EXPLAIN.untilTime
end

local function ApplyExplain()
	if refs.header then refs.header:y(EXPLAIN.drop * (1 - EXPLAIN.head)) end
	if refs.explain then
		refs.explain:visible(EXPLAIN.box > 0):diffusealpha(EXPLAIN.box):zoomy(0.4 + 0.6 * EXPLAIN.box)
	end
end

local function StepExplain()
	local now = GetTimeSinceStart()
	local dt = EXPLAIN.last and math.min(now - EXPLAIN.last, 0.1) or 0
	EXPLAIN.last = now
	if ExplainWanted() then
		EXPLAIN.head = math.min(1, EXPLAIN.head + dt / 0.03)
		EXPLAIN.box = math.min(1, EXPLAIN.box + dt / 0.15)
	else
		EXPLAIN.box = math.max(0, EXPLAIN.box - dt / 0.07)
		EXPLAIN.head = EXPLAIN.head * math.exp(-dt * 18)
		if EXPLAIN.head < 0.005 then EXPLAIN.head = 0 end
	end
	ApplyExplain()
end

Filter.UI = Filter.UI or { cat = 1, cursor = 1 }   -- where the player was the last time (kept between visits)

local function Category()
	return CATEGORIES[catIndex]
end

local function Values()
	local c = Category()
	return c and Filter.Values(c.id) or {}
end

-- Position of every value: { row, x }. VERSION has a row of three small group buttons on top.
local function Layout(c, values)
	local pos = {}
	local cols = c.cols or 1
	local cellW = c.cellW or (233 / cols)
	local tagX = { 0, 71, 144 }   -- (measured on the original)
	local rest = 0
	for i, v in ipairs(values) do
		if c.id == "VERSION" and v.tag then
			local k = 0
			for j = 1, i do if values[j].tag then k = k + 1 end end
			pos[i] = { row = 0, x = GRID_LEFT + tagX[k], tag = true }
		elseif c.id == "VERSION" then
			rest = rest + 1
			pos[i] = { row = 1 + math.floor((rest - 1) / 2), x = GRID_LEFT + ((rest - 1) % 2) * 107 }
		elseif c.id == "FLARE" then
			-- NO RANK has a row of its own, then I ... EX in two rows of five
			if i == 1 then
				pos[i] = { row = 0, x = GRID_LEFT }
			else
				pos[i] = { row = 1 + math.floor((i - 2) / cols), x = GRID_LEFT + ((i - 2) % cols) * cellW }
			end
		else
			pos[i] = { row = math.floor((i - 1) / cols), x = GRID_LEFT + ((i - 1) % cols) * cellW }
		end
	end
	return pos
end

-- ---------------------------------------------------------------- drawing
local function Refresh()
	if not rootActor then return end
	local inGrid = (focus == "grid")

	-- category list
	for i, c in ipairs(CATEGORIES) do
		local row = refs.cats[i]
		if row then
			local on = (catIndex == i)
			row.hi:visible(on)
			row.arrow:visible(on)
			row.arrow:settext(inGrid and "<" or ">")
			-- (while the cursor is in the values the row is a plain bar: no square, no stripes; only the arrow turns around)
			row.box:visible(on and not inGrid)
			row.boxIn:visible(on and not inGrid)
			row.boxIn:diffuse(Filter.CountSelected(c.id) > 0 and ACCENT_DARK or ACCENT)
			row.mark:visible(Filter.CountSelected(c.id) > 0 and not on)
			row.bar:visible(on)   -- (the dark bar is one piece behind; only the row of the cursor lights up)
			row.stripes:visible(on and not inGrid)
		end
	end
	refs.back.hi:visible(catIndex == BACK_INDEX)
	refs.deselect.hi:visible(catIndex == DESELECT_INDEX)

	-- values
	local c = Category()
	local values = c and Values() or {}
	local pos = c and Layout(c, values) or {}
	local n = #values
	local used = 0
	-- the x of the next value in the row of each value (nil = the last one of its row)
	local nextX = {}
	do
		local byRow = {}
		for i, p in ipairs(pos) do
			byRow[p.row] = byRow[p.row] or {}
			table.insert(byRow[p.row], p.x)
		end
		for i, p in ipairs(pos) do
			local best
			for _, x in ipairs(byRow[p.row]) do
				if x > p.x and (not best or x < best) then best = x end
			end
			nextX[i] = best
		end
	end
	for i = 1, #refs.cells do
		local cell = refs.cells[i]
		local value = values[i]
		local p = pos[i]
		local row = p and (p.row - scroll) or -1
		if value and row >= 0 and row < ROWS then
			used = used + 1
			local selected
			if value.members then selected = Filter.GroupSelected(value) else selected = Filter.IsSelected(c.id, value.id) end
			local isCursor = inGrid and cursor == i
			cell.frame:visible(true)
			cell.frame:xy(p.x, GRID_TOP + row * ROW_H)

			-- chosen = black box, cursor = cyan box
			local width = p.tag and 66 or ((c.cellW or (233 / (c.cols or 1))) - 6)
				-- (the title textures are 44 x 20 with the letters from their left edge: the box is 48 wide, so that the widest label, 42 px, has 3 px at both sides)
				if c.id == "TITLE" and TitleTexture(value.id) then width = 48 end
			-- (a long label -- "NO PLAY", "NO RANK", "20+" -- takes the room up to the next value of its row, or up to the
			-- right edge of the values area, instead of being squeezed into its column)
			local room = (nextX[i] and (nextX[i] - 4) or (GRID.x + GRID.w / 2 - 5)) - p.x
			local plainText = not p.tag and not value.big and not value.jp
				and not (c.id == "VERSION" and VersionTexture(value.id))
				and not (c.id == "TITLE" and TitleTexture(value.id))
			if plainText then
				cell.text:settext(value.label):maxwidth(math.max(room - 14, 10))
				width = math.max(width, math.min(cell.text:GetZoomedWidth() + 14, room))
			end
			cell.back:zoomto(width, 22):x(width / 2 - 2)
			if isCursor then
				cell.back:visible(true):diffuse(ACCENT)
			elseif selected and inGrid then
				cell.back:visible(true):diffuse(color("#101010"))
			elseif selected then
				cell.back:visible(true):diffuse(color("#1A1A1A"))
			else
				cell.back:visible(false)
			end
			-- the stripes under the cursor and under the chosen values
			-- (black on the cursor, teal on a chosen value: that one has a black box)
			local stripesOn = isCursor or (selected and inGrid)
			cell.stripes:visible(stripesOn)
			cell.stripes.w, cell.stripes.h = width, 5
			cell.stripes.c = isCursor and BLACK_STRIPES or ACCENT
			cell.stripes:xy(width / 2 - 2, 8.5)
			if stripesOn then DrawStripes(cell.stripes) end

			local textColor
			if isCursor then
				textColor = TEXT_DARK
			elseif selected then
				textColor = color("#FFFFFF")
			elseif inGrid then
				textColor = VALUE_TEAL
			else
				textColor = color("#2D6F62")
			end

			-- the versions have their own textures (filter/version/<id>.png, white: they are colored here); the rest is text
			local tex, frameNumber
			if c.id == "VERSION" then tex, frameNumber = VersionTexture(value.id)
			elseif c.id == "TITLE" then tex = TitleTexture(value.id); frameNumber = 0
			elseif c.id == "GENRE" and value.id == "HINABITA" and HINABITA_TEX then tex = HINABITA_TEX; frameNumber = 0 end
			cell.big:visible(false)
			cell.small:visible(false)
			cell.jp:visible(false)
			if tex then
				if cell.texPath ~= tex then cell.tex:Load(tex); cell.texPath = tex end
				if cell.texFrame ~= frameNumber then cell.tex:pause():setstate(frameNumber); cell.texFrame = frameNumber end
				-- (the title textures start 3 px from the left edge of the box, which begins at x = -2; the versions too, 3 px from x = 0)
					if c.id == "TITLE" then cell.tex:xy(1, 0):halign(0)
					elseif c.id == "GENRE" then cell.tex:xy(6, 0):halign(0)   -- (its ink starts 2 px in: 8 px from the box, like the texts)
					else cell.tex:xy(3, 0):halign(0) end
					cell.tex:visible(true):diffuse(textColor)
				cell.text:visible(false)
			elseif value.big then
				-- a kana row of MUSIC TITLE: the first kana big, the others small next to it
				cell.tex:visible(false)
				cell.text:visible(false)
				cell.big:visible(true):settext(value.big):diffuse(textColor)
				cell.small:visible(true):settext(value.small):diffuse(textColor):x(8 + cell.big:GetZoomedWidth() + 1)
			elseif value.jp then
				-- a label with kana (the Options Text font has none)
				cell.tex:visible(false)
				cell.text:visible(false)
				cell.jp:visible(true):maxwidth((width - 14) / 0.9):settext(value.label):diffuse(textColor)
			else
				cell.tex:visible(false)
				if not plainText then cell.text:maxwidth(width - 14):settext(value.label) end
				cell.text:visible(true):diffuse(textColor)
			end
			cell.mark:diffuse(inGrid and ACCENT_DARK or color("#1F4A40"))
		else
			cell.frame:visible(false)
			cell.stripes:visible(false)
		end
	end

	-- the button inside the values area
	local onInner = inGrid and cursor == n + 1
	refs.innerDeselect.hi:visible(onInner)
	-- (the fade texture is what darkens the button in the category list; without it the button is dimmed here)
	refs.innerDeselect.frame:diffusealpha((inGrid or TexturePath("filter_fade")) and 1 or 0.45)

	-- states of the screen
	if refs.switchTex then
		refs.switchTex:visible(inGrid)
	else
		refs.dim:visible(inGrid)
		refs.white:visible(inGrid)
		refs.whiteBorder:visible(inGrid)
		refs.banner:visible(inGrid)
	end
	refs.fade:visible(not inGrid)
	refs.methodBox:visible(inGrid)
	if HAS_HINT then
		local simpleMethod = (Filter.Mode == "Simple")
		texts.hint_cat.s:visible(not inGrid)
		texts.hint_simple.s:visible(inGrid and simpleMethod)
		texts.hint_normal.s:visible(inGrid and not simpleMethod)
		refs.hint:visible(false)
	elseif inGrid then
		refs.hint:x(345):settext("Select Item        START: Decide and Close        START + LEFT / RIGHT: Select Range and Close")
	else
		refs.hint:x(415):settext("UP / DOWN: Category Select        START / RIGHT: Next")
	end

	-- header
	local simple = (Filter.Mode == "Simple")
	local white, gray = color("#FFFFFF"), color("#7C7C7C")
	if lastSimple == nil then
		refs.simpleBack:diffuse(simple and white or gray)
		refs.normalBack:diffuse(simple and gray or white)
	elseif lastSimple ~= simple then
		-- the buttons fade into each other (0.12 s in the original)
		refs.simpleBack:stoptweening():linear(0.12):diffuse(simple and white or gray)
		refs.normalBack:stoptweening():linear(0.12):diffuse(simple and gray or white)
	end
	lastSimple = simple
	refs.simpleText:diffuse(TEXT_DARK)
	refs.normalText:diffuse(TEXT_DARK)
	refs.methodText:settext(simple and "One-push decision method." or "Multiple selection method.")

	-- the buttons at the bottom: in NORMAL the outside one only clears (no "and close", no icon) and the inside one clears
	-- the items of the category
	if refs.deselectText then refs.deselectText:settext(simple and "Deselect all and close" or "Deselect all")
		:x(DESELECT.x + (simple and -10 or 0)) end
	if refs.deselectIcon then refs.deselectIcon:visible(simple) end
	refs.innerDeselectText:settext(simple and "Deselect all and close" or "Deselect items")
	-- the texts that are textures: the frame of the method and of the state of the button, and the row of the language
	SetTextFrame("explain", simple and 1 or 0)
	SetTextFrame("deselect", simple and 1 or 0)
	SetTextFrame("deselect_in", (simple and 2 or 0) + (onInner and 1 or 0))
	RefreshLanguage()
	refs.count:settext(tostring(Filter.Count()))
end

-- keeps the row of the cursor on screen
local function KeepCursorVisible(pos)
	local p = pos[cursor]
	if not p then return end
	if p.row < scroll then scroll = p.row end
	if p.row >= scroll + ROWS then scroll = p.row - ROWS + 1 end
end

-- ---------------------------------------------------------------- input
local function Sound(name)
	if rootActor then
		local s = rootActor:GetParent() and rootActor:GetParent():GetChild(name)
		if s then s:play() end
	end
end

-- switches between Simple and Normal (Simple: one value per category and START closes; Normal: several values)
local function ToggleMode()
	Filter.Mode = (Filter.Mode == "Normal") and "Simple" or "Normal"
	Sound("folder_change") -- sound: "Method"
	EXPLAIN.untilTime = GetTimeSinceStart() + EXPLAIN.hold   -- the explanation shows for a while
end

local function Close()
	if Filter.Active() and Filter.Count() == 0 then
		Sound("change_sound")   -- nothing would be listed: the menu stays open
		return
	end
	Filter.UI.cat, Filter.UI.cursor = catIndex, cursor
	opened = false
	if FilterMenu.OnClose then FilterMenu.OnClose() end
end

-- Closes the menu without the checks of Close() and without applying anything: the caller already put the filter back as it was
-- (the menu timer ran out, see ScreenSortList overlay/default.lua).
function FilterMenu.Cancel()
	Filter.UI.cat, Filter.UI.cursor = catIndex, cursor
	opened = false
	if FilterMenu.OnClose then FilterMenu.OnClose() end
end

function FilterMenu.Open()
	Filter.Refresh()
	-- the original opens on the values of the category used last
	catIndex = math.min(math.max(Filter.UI.cat or 1, 1), NCAT)
	cursor, scroll = 1, 0
	local c = Category()
	local n = #Values()
	focus = (c and n > 0) and "grid" or "cat"
	if focus == "grid" then
		cursor = math.min(math.max(Filter.UI.cursor or 1, 1), n)
		KeepCursorVisible(Layout(c, Values()))
	end
	opened = true
	-- (the menu opens with the explanation already there, for two seconds, without animation; after that it only shows
	-- when the selection method is changed)
	lastSimple = nil
	EXPLAIN.untilTime, EXPLAIN.last = GetTimeSinceStart() + 0.22 + EXPLAIN.hold, nil
	EXPLAIN.head, EXPLAIN.box = 1, 1
	ApplyExplain()
	if rootActor then
		-- the original: the select music screen is gone at once and the menu fades in over the dimmed background
		rootActor:stoptweening():visible(true):diffusealpha(0):sleep(0.1):linear(0.12):diffusealpha(1)
	end
	Refresh()
end

function FilterMenu.Hide()
	opened = false
	if rootActor then rootActor:visible(false) end
end

-- the value to move to from `from` in a direction, by position (nil = there is none that way)
local function Neighbor(pos, from, direction)
	local cur = pos[from]
	if not cur then return nil end
	local best, bestScore
	for i, p in ipairs(pos) do
		local ok, score
		if direction == "left" then
			ok = p.row == cur.row and p.x < cur.x
			score = cur.x - p.x
		elseif direction == "right" then
			ok = p.row == cur.row and p.x > cur.x
			score = p.x - cur.x
		elseif direction == "up" then
			ok = p.row < cur.row
			score = (cur.row - p.row) * 1000 + math.abs(p.x - cur.x)
		else
			ok = p.row > cur.row
			score = (p.row - cur.row) * 1000 + math.abs(p.x - cur.x)
		end
		if ok and (not bestScore or score < bestScore) then best, bestScore = i, score end
	end
	return best
end

function FilterMenu.Input(event)
	if not event.GameButton or event.type == "InputEventType_Release" then return false end
	local b = event.GameButton
	local c = Category()

	-- SELECT switches Simple / Normal in the category list and in the values (Filter Switch)
	if b == "Select" then
		if event.type == "InputEventType_FirstPress" then
			ToggleMode()
			Refresh()
		end
		return true
	end

	if focus == "cat" then
		if b == "MenuUp" or b == "Up" then
			if catIndex >= BACK_INDEX then catIndex = NCAT else catIndex = (catIndex == 1) and NCAT or catIndex - 1 end
			cursor, scroll = 1, 0
			Sound("change_sound") -- Outsite Filter Switch
		elseif b == "MenuDown" or b == "Down" then
			if catIndex >= BACK_INDEX then catIndex = 1
			elseif catIndex == NCAT then catIndex = BACK_INDEX
			else catIndex = catIndex + 1 end
			cursor, scroll = 1, 0
			Sound("change_sound") -- Outsite Filter Switch
		elseif b == "MenuLeft" or b == "Left" then
			if catIndex == DESELECT_INDEX then
				catIndex = BACK_INDEX
				Sound("change_sound") -- sound: "Method"
			elseif catIndex < BACK_INDEX then
				ToggleMode()
			end
		elseif b == "MenuRight" or b == "Right" or b == "Start" then
			if catIndex == BACK_INDEX then
				if b == "MenuRight" or b == "Right" then
					catIndex = DESELECT_INDEX
					Sound("change_sound")   -- mismo sonido que al volver con la izquierda
				else
					Sound("start_sound"); Close()
				end
			elseif catIndex == DESELECT_INDEX then
				if b == "Start" then
					Filter.ClearAll()
					Sound("start_sound")
					-- (NORMAL: "Deselect all" only clears and the menu stays open)
					if Filter.Mode == "Simple" then Close() end
				end
			elseif #Values() > 0 then
				focus = "grid"
				cursor, scroll = 1, 0
				Sound("change_sound") -- start to go to Filter Switch
			end
		elseif b == "Back" then
			Sound("start_sound")
			Close()
		end
	else
		local values = Values()
		local pos = Layout(c, values)
		local n = #values
		if b == "MenuLeft" or b == "Left" then
			if cursor > n then
				-- on the inner button: left goes back to the category list
				focus = "cat"
				Sound("change_sound")
			else
				local to = Neighbor(pos, cursor, "left")
				if to then cursor = to else focus = "cat" end
				Sound("move_sound")
			end
		elseif b == "MenuRight" or b == "Right" then
			if cursor <= n then
				local to = Neighbor(pos, cursor, "right")
				if to then cursor = to end
			end
			Sound("move_sound")
		elseif b == "MenuUp" or b == "Up" then
			if cursor > n then
				-- from the inner button to the last row
				local last = 1
				for i, p in ipairs(pos) do
					if p.row > pos[last].row or (p.row == pos[last].row and p.x > pos[last].x) then last = i end
				end
				cursor = last
			else
				local to = Neighbor(pos, cursor, "up")
				if to then cursor = to end
			end
			Sound("move_sound")
		elseif b == "MenuDown" or b == "Down" then
			if cursor <= n then
				local to = Neighbor(pos, cursor, "down")
				if to then cursor = to else cursor = n + 1 end
			end
			Sound("move_sound")
		elseif b == "Start" then
			if cursor > n then
				-- The inner button only works on the values of THIS category (the bottom "Deselect all" button is the one
				-- that clears every category). NORMAL: "Deselect items" clears them and the cursor stays here.
				-- SIMPLE: "Deselect all and close" clears them and goes back to the category list (the menu stays open).
				Sound("start_sound")
				Filter.ClearCategory(c.id)
				if Filter.Mode == "Simple" then
					focus = "cat"
				end
			elseif Filter.Mode == "Simple" then
				-- one-push decision: this value is the filter of the category and the menu closes
				Filter.ClearCategory(c.id)
				Filter.Toggle(c.id, values[cursor])
				Sound("start_sound")
				Close()
			else
				Filter.Toggle(c.id, values[cursor])
				Sound("start_sound")
			end
		elseif b == "Back" then
			focus = "cat"
			Sound("change_sound")
		end
		KeepCursorVisible(pos)
	end

	Refresh()
	return true
end

-- ---------------------------------------------------------------- actors
local t = Def.ActorFrame{
	InitCommand = function(s)
		rootActor = s
		-- the layout is in a 1280 pixel wide screen; the theme's own coordinates are smaller (1.5x on this one)
		s:zoom(SCREEN_WIDTH / 1280)
		s:visible(false)
		s:SetUpdateFunction(function()
			if opened then
				Filter.WarmScores(0.006)
				StepExplain()
				for _, p in ipairs(stripeFrames) do
					if p:GetVisible() then DrawStripes(p) end
				end
			end
		end)
	end,

	-- (the texture has a shadow around the panel: its center is a few pixels from the center of the panel)
	(Tex("filter_bg", PANEL.x + 8, PANEL.y + 3, PANEL.w, PANEL.h, color("#F2F2F2"))),

	-- (the lighter patch behind the title: part of the panel in the original, so it darkens with it in the switch state)
	Box(465, 143, 168, 35, color("#F8F8F8")),
	-- (the title texture is 172 x 36, its letters start 34 px from the left: centered on the lighter patch)
	TextSprite("title", "filter_txt_title 1x3", 1, 465, 143) or Text(413, 143, 0.8, 0, TEXT_DARK, "FILTER"),
	-- (the width the original's text has: the font is wider than the original's textures, so the text shrinks to fit)
	-- (the sentence texture is 448 x 32 with the text at its top left corner: its left edge on x = 428, its text row on y = 166)
	TextSprite("info", "filter_txt_info 1x3", 1, 652, 174) or Def.BitmapText{ Font = SENT_FONT, Text = "Choose from various filter conditions.",
		InitCommand = function(s) s:xy(428, 166):halign(0):diffuse(color("#8C8C8C")); FitText(s, 233) end },
	-- black background of the key help (same size as the textures: 604 x 52)
	Box(HINT_X + 297, HINT_Y - 3, 555, 50, color("#000000")),
	-- hint at the bottom: the key help, as textures (filter_ope_*, 604 x 52, one row per language, centered on x = 640 and the
	-- ink already placed inside: the category list, and the values in the SIMPLE and the NORMAL method). Without them, text.
	TextSprite("hint_cat", "filter_ope_category 1x3", 1, HINT_X + 302, HINT_Y) or Def.Actor{},
	TextSprite("hint_simple", "filter_ope_items_simple 1x3", 1, HINT_X + 302, HINT_Y) or Def.Actor{},
	TextSprite("hint_normal", "filter_ope_items_normal 1x3", 1, HINT_X + 302, HINT_Y) or Def.Actor{},
	Def.BitmapText{ Font = FONT, Text = "",
		InitCommand = function(s) refs.hint = s; s:xy(415, 637):halign(0):zoom(0.45):diffuse(color("#12C9A4")) end },
}

-- the dark bar at the left of the categories is one piece (the original's); the row of the cursor lights up on it
t[#t + 1] = Box(CAT_X - 16, CAT_Y + (NCAT - 1) * CAT_STEP / 2, 12, NCAT * CAT_STEP - 1, ACCENT_DARK)

-- the name of a category: its texture (left edge of the texture 4 px inside the cursor, the ink centred 2 px above the row centre like
-- the old text) or, without it, the pixel font
local function CategoryText(c, i, y)
	local def = CAT_TEXTURES[c.id]
	local sprite = def and TextSprite("cat" .. i, def[1], def[2] or 0, CAT_X + 4, y - 1)
	if sprite then
		local base = sprite.InitCommand
		sprite.InitCommand = function(s) base(s); s:halign(0):diffuse(TEXT_DARK) end
		return sprite
	end
	return Def.BitmapText{ Font = UI_FONT, Text = c.name,
		InitCommand = function(s) refs.cats[i] = refs.cats[i] or {}; refs.cats[i].text = s
			s:xy(CAT_X + 4, y - 2):halign(0):maxwidth(170):diffuse(TEXT_DARK) end }
end

-- the category list
for i, c in ipairs(CATEGORIES) do
	local y = CAT_Y + (i - 1) * CAT_STEP
	t[#t + 1] = Def.ActorFrame{
		Def.Quad{ InitCommand = function(s) refs.cats[i] = refs.cats[i] or {}; refs.cats[i].bar = s
			s:xy(CAT_X - 16, y):zoomto(12, CAT_STEP - 1):diffuse(ACCENT):visible(false) end },
		Def.Quad{ InitCommand = function(s) refs.cats[i] = refs.cats[i] or {}; refs.cats[i].hi = s
			s:xy(CAT_X + 93, y):zoomto(186, CAT_STEP - 1):diffuse(ACCENT):visible(false) end },
		-- (along the very bottom of the bar: the text of the original does not touch it)
		Stripes(function(s) refs.cats[i] = refs.cats[i] or {}; refs.cats[i].stripes = s
			s.w, s.h = 186, 5
			s:xy(CAT_X + 93, y + (CAT_STEP - 1) / 2 - 2.5):visible(false) end),
		CategoryText(c, i, y),
		-- the square at the right of the active row (filled when the category has values chosen)
		Def.Quad{ InitCommand = function(s) refs.cats[i] = refs.cats[i] or {}; refs.cats[i].box = s
			s:xy(CAT_X + 173, y):zoomto(14, 14):diffuse(TEXT_DARK):visible(false) end },
		Def.Quad{ InitCommand = function(s) refs.cats[i] = refs.cats[i] or {}; refs.cats[i].boxIn = s
			s:xy(CAT_X + 173, y):zoomto(10, 10):diffuse(ACCENT):visible(false) end },
		-- a category that has values chosen but is not the active one
		Def.Quad{ InitCommand = function(s) refs.cats[i] = refs.cats[i] or {}; refs.cats[i].mark = s
			s:xy(CAT_X + 173, y):zoomto(8, 8):diffuse(ACCENT_DARK):visible(false) end },
		-- the arrow outside of the cursor: points to the values, or back to the list while choosing values
		Def.BitmapText{ Font = UI_FONT, Text = ">",
			InitCommand = function(s) refs.cats[i] = refs.cats[i] or {}; refs.cats[i].arrow = s
				s:xy(CAT_X + 199, y):diffuse(ACCENT):visible(false) end },
	}
end

-- the text of a bottom button: its texture (Back + key 7 / Deselect all, or Deselect all and close + key 00: frame by method)
-- or, without the texture, the pixel font and the key drawn by code
local function BottomLabel(def)
	local sprite
	if def.key == "back" then
		sprite = TextSprite("back", "filter_txt_back 1x3", 1, def.rect.x, def.rect.y)
	else
		sprite = TextSprite("deselect", "filter_txt_deselectall 2x3", 2, def.rect.x, def.rect.y)
	end
	if sprite then return sprite end
	return Def.ActorFrame{
		Def.BitmapText{ Font = (def.key == "deselect" and SENT_FONT) or (AVENIR_TEST and AV_FONT) or UI_FONT, Text = def.text,
			InitCommand = function(s)
				if def.key == "deselect" then refs.deselectText = s end
				s:xy(def.rect.x - 10, def.rect.y - 1):diffuse(TEXT_DARK); FitText(s, 160)
			end },
		Def.ActorFrame{
			InitCommand = function(s) if def.key == "deselect" then refs.deselectIcon = s end end,
			Box(def.rect.x + def.rect.w / 2 - 18, def.rect.y, 14, 12, color("#3A3A3A")),
			Text(def.rect.x + def.rect.w / 2 - 18, def.rect.y, 0.3, 0.5, color("#FFFFFF"), def.icon),
		},
	}
end

-- BACK and DESELECT ALL AND CLOSE (bottom of the panel)
for _, def in ipairs({ { key = "back", rect = BACK, text = "Back", icon = "7" },
		{ key = "deselect", rect = DESELECT, text = "Deselect all and close", icon = "00" } }) do
	t[#t + 1] = Def.ActorFrame{
		Slot(def.key, def.rect.x, def.rect.y, def.rect.w, def.rect.h, color("#FFFFFF")),
		Box(def.rect.x, def.rect.y - def.rect.h / 2 + 0.5, def.rect.w, 1, ACCENT),
		Box(def.rect.x, def.rect.y + def.rect.h / 2 - 0.5, def.rect.w, 1, ACCENT),
		Box(def.rect.x - def.rect.w / 2 + 0.5, def.rect.y, 1, def.rect.h, ACCENT),
		Box(def.rect.x + def.rect.w / 2 - 0.5, def.rect.y, 1, def.rect.h, ACCENT),
		Def.Quad{ InitCommand = function(s) refs[def.key] = refs[def.key] or {}; refs[def.key].hi = s
			s:xy(def.rect.x, def.rect.y):zoomto(def.rect.w - 2, def.rect.h - 2):diffuse(ACCENT):visible(false) end },
		(BottomLabel(def)),
	}
end

-- While the cursor is in the values ("Filter Switch"): the rest of the panel is darkened and the values area stays
-- open (white, with its border and banner).
if TexturePath("filter_switch") then
	local overlay = Tex("filter_switch", PANEL.x + 8, PANEL.y + 3, PANEL.w, PANEL.h, color("#00000000"))
	local init = overlay.InitCommand
	overlay.InitCommand = function(s) init(s); refs.switchTex = s; s:visible(false) end
	t[#t + 1] = overlay
else
	t[#t + 1] = Def.Quad{
		InitCommand = function(s) refs.dim = s
			s:xy(PANEL.x, PANEL.y):zoomto(PANEL.w, PANEL.h):diffuse(color("#303030A6")):visible(false) end }
	t[#t + 1] = Def.Quad{
		InitCommand = function(s) refs.white = s
			s:xy(GRID.x, GRID.y):zoomto(GRID.w, GRID.h):diffuse(color("#F4F4F4")):visible(false) end }
	t[#t + 1] = Def.ActorFrame{
		InitCommand = function(s) refs.whiteBorder = s; s:visible(false) end,
		Box(GRID.x, GRID.y - GRID.h / 2 + 1, GRID.w, 2, ACCENT),
		Box(GRID.x, GRID.y + GRID.h / 2 - 1, GRID.w, 2, ACCENT),
		Box(GRID.x - GRID.w / 2 + 1, GRID.y, 2, GRID.h, ACCENT),
		Box(GRID.x + GRID.w / 2 - 1, GRID.y, 2, GRID.h, ACCENT),
	}
	t[#t + 1] = Def.BitmapText{ Font = FONT, Text = "Filter Switch",
		InitCommand = function(s) refs.banner = s
			s:xy(690, 187):zoom(0.5):diffuse(color("#FFFFFF")):visible(false) end }
end

-- The selection method (positions measured on the original, with the explanation box showing; without it the whole header
-- is 19 px lower: see EXPLAIN). It is above the darkening of the switch state: the original keeps this block bright, on a
-- white box (drawn here, only while the cursor is in the values; in the category list it is the panel itself).
t[#t + 1] = Def.ActorFrame{
	InitCommand = function(s) refs.header = s end,
	Def.Quad{ InitCommand = function(s) refs.methodBox = s; s:xy(780, 133.5):zoomto(196, 44):diffuse(color("#F6F6F6")):visible(false) end },
	(not HAS_SELMETHOD) and Box(694, 125, 14, 14, color("#3A3A3A")) or Def.Actor{},
	(not HAS_SELMETHOD) and Text(691, 125, 0.32, 0, color("#FFFFFF"), "0") or Def.Actor{},
	Def.BitmapText{ Font = SENT_FONT, Text = "Change Selection Method",
		InitCommand = function(s) s:xy(706, 124):halign(0):diffuse(TEXT_DARK); FitText(s, 172); if HAS_SELMETHOD then s:visible(false) end end },
	Def.Quad{ InitCommand = function(s) refs.simpleBack = s; s:xy(732, 145):zoomto(96, 21) end },
	Def.Quad{ InitCommand = function(s) refs.normalBack = s; s:xy(828, 145):zoomto(96, 21) end },
	Def.BitmapText{ Font = AVENIR_TEST and AV_FONT or UI_FONT, Text = "Simple",
		InitCommand = function(s) refs.simpleText = s; s:xy(732, 144); FitText(s); if HAS_SELMETHOD then s:visible(false) end end },
	Def.BitmapText{ Font = AVENIR_TEST and AV_FONT or UI_FONT, Text = "Normal",
		InitCommand = function(s) refs.normalText = s; s:xy(828, 144); FitText(s); if HAS_SELMETHOD then s:visible(false) end end },
	-- (the texture is 200 x 48: its key 0 is on the old icon (694, 125), "Simple" and "Normal" on the buttons (732 / 828, 144))
	TextSprite("selmethod", "filter_txt_selmethod 1x3", 1, 779, 135),   -- (was 139: moved 4 px up, 2026-11-07)
}

-- the explanation box (filter_explain.png, ~172 x 20, when the texture exists; a dark bar until then). The frame sits on
-- the top edge of the box, so that it opens downward.
t[#t + 1] = Def.ActorFrame{
	InitCommand = function(s) refs.explain = s; s:xy(779, 155):visible(false) end,
	-- (the texture is 206 x 22 with the dark box in rows 2 - 19: its center falls where the old box was)
	TextSprite("explain", "filter_txt_selmethod_info 2x3", 2, 0, 10) or (Tex("filter_explain", 0, 10, 172, 18, color("#2A2A2AF0"))),
	Def.BitmapText{ Font = SENT_FONT, Text = "One-push decision method.",
		InitCommand = function(s) refs.methodText = s; s:xy(0, 9):diffuse(color("#FFFFFF")); FitText(s, 168); if HAS_EXPLAIN then s:visible(false) end end },
}

-- "Filtering Results" box: above the darkening of the switch state too (it overlaps the edge of the panel).
-- filter_results.png has a shadow around the box and filter_results_title.png has margins: both are centered so that
-- the box lands on COUNT and the title text on its top line.
t[#t + 1] = Tex("filter_results", COUNT.x + 3.5, COUNT.y + 4, COUNT.w, COUNT.h, color("#F7F7F7"))
if TexturePath("filter_results_title") then
	t[#t + 1] = Tex("filter_results_title", COUNT.x - 1, COUNT.y, 104, 68, color("#00000000"))
else
	t[#t + 1] = UText(COUNT.x, COUNT.y - 17, 0.5, TEXT_DARK, "Filtering Results")
end
t[#t + 1] = Def.BitmapText{ Font = FONT, Text = "0",
	InitCommand = function(s) refs.count = s; s:xy(COUNT.x, COUNT.y + 9):zoom(0.78):diffuse(ACCENT_DARK) end }

-- the logo is above the darkening of the switch state (it stays bright in the original)
t[#t + 1] = Tex("filter_title", 415, 122, 198, 134, color("#00000000"))

-- the button inside the values area
t[#t + 1] = Def.ActorFrame{
	InitCommand = function(s) refs.innerDeselect = refs.innerDeselect or {}; refs.innerDeselect.frame = s end,
	Box(INNER_DESELECT.x, INNER_DESELECT.y, INNER_DESELECT.w, INNER_DESELECT.h, color("#FFFFFF")),
	Box(INNER_DESELECT.x, INNER_DESELECT.y - INNER_DESELECT.h / 2 + 0.5, INNER_DESELECT.w, 1, ACCENT),
	Box(INNER_DESELECT.x, INNER_DESELECT.y + INNER_DESELECT.h / 2 - 0.5, INNER_DESELECT.w, 1, ACCENT),
	Box(INNER_DESELECT.x - INNER_DESELECT.w / 2 + 0.5, INNER_DESELECT.y, 1, INNER_DESELECT.h, ACCENT),
	Box(INNER_DESELECT.x + INNER_DESELECT.w / 2 - 0.5, INNER_DESELECT.y, 1, INNER_DESELECT.h, ACCENT),
	Def.Quad{ InitCommand = function(s) refs.innerDeselect = refs.innerDeselect or {}; refs.innerDeselect.hi = s
		s:xy(INNER_DESELECT.x, INNER_DESELECT.y):zoomto(INNER_DESELECT.w - 2, INNER_DESELECT.h - 2):diffuse(ACCENT):visible(false) end },
	Def.BitmapText{ Font = SENT_FONT, Text = "Deselect all and close",
		InitCommand = function(s) refs.innerDeselectText = s
			s:xy(INNER_DESELECT.x - 10, INNER_DESELECT.y - 1):diffuse(ACCENT_DARK); FitText(s, 160); if HAS_ONOFF then s:visible(false) end end },
	(not HAS_ONOFF) and Box(INNER_DESELECT.x + INNER_DESELECT.w / 2 - 16, INNER_DESELECT.y, 14, 12, color("#3A3A3A")) or Def.Actor{},
	(not HAS_ONOFF) and Text(INNER_DESELECT.x + INNER_DESELECT.w / 2 - 16, INNER_DESELECT.y, 0.3, 0.5, color("#FFFFFF"), "00") or Def.Actor{},
	-- (frames: Deselect items off / on, Deselect all and close off / on; "on" while the cursor is on the button)
	TextSprite("deselect_in", "filter_txt_deselect_onoff 4x3", 4, INNER_DESELECT.x, INNER_DESELECT.y),
}

-- covers the values area while the cursor is in the category list (the values are drawn above it)
do
	local fade = Tex("filter_fade", GRID.x, GRID.y, GRID.w, GRID.h, color("#4B4B4BFF"))
	local init = fade.InitCommand
	fade.InitCommand = function(s) init(s); refs.fade = s end
	t[#t + 1] = fade
end

-- the cells of the values grid: back box (cursor / chosen), marker at the left, text
-- (one cell for every value that can be on screen at once: the packs lists have more than 50 values)
for i = 1, ROWS * 8 do
	t[#t + 1] = Def.ActorFrame{
		InitCommand = function(s) refs.cells[i] = refs.cells[i] or {}; refs.cells[i].frame = s; s:visible(false) end,
		Def.Quad{ InitCommand = function(s) refs.cells[i] = refs.cells[i] or {}; refs.cells[i].back = s
			s:halign(0.5):visible(false) end },
		Stripes(function(s) refs.cells[i] = refs.cells[i] or {}; refs.cells[i].stripes = s; s:visible(false) end),
		Def.Quad{ InitCommand = function(s) refs.cells[i] = refs.cells[i] or {}; refs.cells[i].mark = s
			s:xy(0, 0):zoomto(4, 14):diffuse(ACCENT_DARK) end },
		Def.Sprite{ InitCommand = function(s) refs.cells[i] = refs.cells[i] or {}; refs.cells[i].tex = s
			s:xy(3, 0):halign(0):visible(false) end },
		Def.BitmapText{ Font = UI_FONT,
			InitCommand = function(s) refs.cells[i] = refs.cells[i] or {}; refs.cells[i].text = s
				s:xy(8, -2):halign(0) end },
		-- kana (MUSIC TITLE rows, the ひなビタ genre): drawn with the theme's Japanese font
		Def.BitmapText{ Font = KANA_FONT,
			InitCommand = function(s) refs.cells[i] = refs.cells[i] or {}; refs.cells[i].big = s
				s:xy(8, -1):halign(0):zoom(0.9):visible(false) end },
		Def.BitmapText{ Font = KANA_FONT,
			InitCommand = function(s) refs.cells[i] = refs.cells[i] or {}; refs.cells[i].small = s
				s:xy(24, 2):halign(0):zoom(0.55):visible(false) end },
		Def.BitmapText{ Font = KANA_FONT,
			InitCommand = function(s) refs.cells[i] = refs.cells[i] or {}; refs.cells[i].jp = s
				s:xy(8, -1):halign(0):zoom(0.9):visible(false) end },
	}
end

return t
