-- ============================================================================
-- DDR WORLD STYLE OPTIONS MENU (one panel per player)
-- ============================================================================
-- This file only DRAWS the menu and handles the buttons.
--   * Which options exist and how they work:  Scripts/08 PlayerOptionsRows.lua
--   * Where each texture goes:                Scripts/08 PlayerOptionsTextures.lua
--
-- All measurements are in pixels of a 1920x1080 screen (the ones taken from screenshots of the original
-- DDR WORLD). The panel scales itself (variable S).
-- Origin (0,0) of each panel = top-left corner of the white box.
-- ============================================================================

local args = {...}
local pn = args[1]
local pName = ToEnumShortString(pn)

local S = SCREEN_HEIGHT / 1080

local PANEL_X_P1 = 225
local PANEL_W    = 645
local PANEL_Y    = 240

local FONT = "_avenirnext lt pro bold Bold 20px"

local CYAN  = color("#2de8c3")
local BLACK = color("#000000")
local WHITE = color("#ffffff")
local AMBER = color("#ffb347")   -- value of an option that is not connected to gameplay yet

-- Positions inside the panel.
-- Tabs (reference sizes): 81 wide (Back 116), 87 apart. The backgrounds (56x24 / 80x24 PNGs times 1.446)
-- measure 81x34.7 and 116x34.7. The bottom edge of a tab rests on the top edge of the cyan frame (y=118).
local TAB_X      = { 54, 141, 228, 315, 402, 489 }
local TAB_W      = 81
local TAB_BACK_W = 116
local TAB_H      = 34.7
local TAB_Y      = 118 - TAB_H
local ROW_Y0     = 124
local ROW_STEP   = 45
local LABEL_X    = 67      -- where the label text starts
-- Label size, measured from 720p screenshots of the reference: the width matches the original but the letters
-- are about 15% shorter, because the original font is wider and lower. The same zoom is used horizontally and
-- vertically so the letters do not look squashed.
local LABEL_ZOOM = 1.2
local LABEL_MAXW = 257          -- maximum label width; longer labels are compressed
local INFO_NUM_ZOOM = 0.76                  -- size of the min ~ core ~ max numbers
local INFO_NUM_ON   = color("#48e6b9")      -- their color on the green (lit) box
local VALUE_X   = 345
local VALUE_W   = 249

local Tabs = POMenu.Tabs
local Rows = POMenu.Rows

local state = { tab = 1, row = 0 }   -- row 0 = the tab bar

-- References to the actors (filled in by their InitCommands)
local ui = { tabOn = {}, tabOff = {}, headerIcon = {}, rows = {}, bands = {} }

-- ---------- navigation helpers ----------
-- Rows of a tab that are currently shown (a row can hide itself with row.visible(pn)).
local function VisibleRows(tab)
	local list = {}
	for _, id in ipairs(tab.rows) do
		local r = Rows[id]
		if r and (r.visible == nil or r.visible(pn)) then list[#list + 1] = id end
	end
	return list
end

local function CurrentRows()
	return VisibleRows(Tabs[state.tab])
end

local function IsFocusable(slot)
	local id = CurrentRows()[slot]
	return id ~= nil and Rows[id] ~= nil and Rows[id].kind ~= "info"
end

local function FirstFocusable()
	for i = 1, #CurrentRows() do
		if IsFocusable(i) then return i end
	end
	return 0
end

local function NextFocusable(from, dir)
	local i = from + dir
	while i >= 1 and i <= #CurrentRows() do
		if IsFocusable(i) then return i end
		i = i + dir
	end
	return nil
end

-- ---------- drawing ----------
local function Refresh()
	local tab = { id = Tabs[state.tab].id, title = Tabs[state.tab].title, rows = CurrentRows() }

	for i = 1, #Tabs do
		if ui.tabOn[i] then ui.tabOn[i]:visible(i == state.tab) end
		if ui.tabOff[i] then ui.tabOff[i]:visible(i ~= state.tab) end
	end
	for id, a in pairs(ui.headerIcon) do a:visible(id == tab.id) end
	-- The tab name is only written when there is no icon PNG (the PNG already contains the name).
	if ui.headerText then
		local show = tab.id ~= "back" and not POTexExists("header_icon_" .. tab.id)
		ui.headerText:settext(show and tab.title or "")
	end

	-- The white/gray bands only show on rows that exist in this tab (none on Back).
	for i, q in pairs(ui.bands) do q:visible(i <= #tab.rows) end

	-- The explanation box is only filled while a row is selected. With the cursor on the tab bar it stays
	-- empty, like the original.
	local explain = ""
	local explainImage = nil   -- PNG of the selected value (see Scripts/08 PlayerOptionsRows.lua, 'image')

	for slot = 1, POMenu.MaxRows do
		local a = ui.rows[slot]
		local id = tab.rows[slot]
		local row = id and Rows[id]

		if not a then
			-- the actor has not been created yet
		elseif not row then
			a.frame:visible(false)
		else
			a.frame:visible(true)
			local focused = (state.row == slot)

			if row.kind == "info" then
				a.label:visible(false); a.valueFrame:visible(false); a.bgFocus:visible(false)
				a.titleImage:visible(false)
				a.infoFrame:visible(true)
				-- the box is lit only while the row it "follows" (SpeedValue) is selected
				local on = row.follows ~= nil and tab.rows[state.row] == row.follows
				a.infoBgOn:visible(on)
				a.infoBgOff:visible(not on)
				-- numbers: teal on the green box, white on the gray box (like the original)
				local nc = on and INFO_NUM_ON or WHITE
				a.infoMin:diffuse(nc); a.infoCore:diffuse(nc); a.infoMax:diffuse(nc)
				a.infoBand:visible(on)
				local info = row.info(pn)
				if info then
					a.infoMin:settext(tostring(info.min) .. " ~")
					a.infoCore:settext(tostring(info.core) .. " ~")
					a.infoMax:settext(tostring(info.max))
				else
					a.infoMin:settext("-"); a.infoCore:settext("-"); a.infoMax:settext("-")
				end
			else
				a.infoFrame:visible(false)
				a.label:visible(true); a.valueFrame:visible(true)
				-- The white/gray background comes from the alternating bands (RowBand1..7); here only the
				-- cyan strip of the selected row is switched on.
				a.bgFocus:visible(focused)
				a.valueBg:visible(not focused)
				a.valueBgFocus:visible(focused)

				local count = row.count(pn)
				local idx = math.max(1, math.min(count, row.get(pn)))
				local title = row.title
				if type(title) == "function" then title = title(pn) end   -- e.g. MULTIPLIER only with Speed Rate
				-- The name of the option is a PNG (3 languages stacked); its text is only used while there is none.
				local timg = row.titleImage
				if type(timg) == "function" then timg = timg(pn) end
				if timg and POExplanationExists(timg) then
					if a.titlePath ~= timg then
						a.titlePath = timg
						a.titleImage:Load(POExplanationPath(timg))
						a.titleImage:animate(false):setstate(GetCurrentLanguage())
					end
					a.titleImage:visible(true)
					a.label:settext("")
				else
					a.titleImage:visible(false)
					a.label:settext(title or "")
				end
				a.value:settext(row.text(pn, idx))
				-- Selected row: WHITE value, stripes below and triangles toward the directions it can change.
				-- Normal row: cyan value and a progress bar.
				if focused then
					a.value:diffuse(row.wired == false and AMBER or WHITE)
				else
					a.value:diffuse(row.wired == false and AMBER or CYAN)
				end
				-- Progress bar = a SEGMENT that marks where the choice is (like the original): with 2 choices it
				-- covers the left or right half, with 4 a quarter, and with many values (speed) a short segment
				-- (at least 20% of the width) that slides. Always visible; the stripes of the selected row sit
				-- below and do not cover it.
				local seg = math.min(1, math.max(1 / count, 0.2))
				-- The position runs from 0 (first choice) to 1 - seg (LAST choice), evenly spread, so only the last
				-- choice (for example 100%) reaches the end.
				local startf = 0
				if count > 1 then startf = (idx - 1) / (count - 1) * (1 - seg) end
				a.bar:visible(true)
				a.bar:x(startf * VALUE_W)
				a.bar:zoomx(seg)
				a.stripes:visible(focused)
				a.arrowL:visible(focused and idx > 1)
				a.arrowR:visible(focused and idx < count)

				if focused then
					local e = row.explain
					if type(e) == "function" then e = e(pn, idx) end
					explain = e or ""
					local img = row.image
					if type(img) == "function" then img = img(pn, idx) end
					explainImage = img
				end
			end
		end
	end

	-- The box shows the PNG of the value (it already has the text, the drawing and the dotted line). Only when
	-- there is none, or the file does not exist, the text of the row is written instead.
	local showImage = explainImage ~= nil and POExplanationExists(explainImage)
	if ui.explainImage then
		if showImage then
			if ui.explainPath ~= explainImage then
				ui.explainPath = explainImage
				ui.explainImage:Load(POExplanationPath(explainImage))
				-- the 3 languages are stacked (EN, JP, KR): the frame of the theme's language is shown
				ui.explainImage:animate(false):setstate(GetCurrentLanguage())
				-- the PNG (172 high) is 1 px taller than the dark box
				ui.explainImage:cropbottom(1 / math.max(1, ui.explainImage:GetHeight()))
			end
			ui.explainImage:visible(true)
		else
			ui.explainImage:visible(false)
		end
	end
	if ui.explainText then ui.explainText:settext(showImage and "" or explain) end
end

-- ---------- value changes / navigation ----------
local function Play(name)
	local ok, path = pcall(function() return THEME:GetPathS("WORLD/PlayerOptions", name) end)
	if ok and path then SOUND:PlayOnce(path) end
end

local function ChangeValue(dir)
	local id = CurrentRows()[state.row]
	local row = id and Rows[id]
	if not row or row.kind == "info" then return end
	local count = row.count(pn)
	local cur = math.max(1, math.min(count, row.get(pn)))
	local new = math.max(1, math.min(count, cur + dir))
	if new == cur then return end
	row.set(pn, new)
	Play("Change")
	Refresh()
end

-- Closes the menu using the same "cancel" as ESC (see "ScreenPlayerOptions cancel.lua"), so both ways out
-- look the same. force = true closes even if the other player has not finished (ESC); without force
-- (Enter on Back) it waits for every player to finish.
local function CloseMenu(force)
	POMenu.Done[pn] = true
	local all = true
	for _, p in ipairs(GAMESTATE:GetEnabledPlayers()) do
		if not POMenu.Done[p] then all = false end
	end
	if force then all = true end
	if all then
		if POMenu.NeedsReload then THEME:ReloadMetrics() end
		local screen = SCREENMAN:GetTopScreen()
		if screen then
			if screen.Cancel then
				screen:Cancel()
			elseif screen.StartTransitioningScreen then
				screen:StartTransitioningScreen("SM_GoToPrevScreen")
			else
				screen:PostScreenMessage("SM_GoToPrevScreen", 0)
			end
		end
	end
end

local function Move(dir)
	-- dir: -1 up, +1 down
	if state.row == 0 then
		if dir > 0 then
			local f = FirstFocusable()
			if f > 0 then state.row = f; Play("Move") end
		end
	else
		local nxt = NextFocusable(state.row, dir)
		if nxt then
			state.row = nxt
			Play("Move")
		elseif dir < 0 then
			state.row = 0
			Play("Move")
		end
	end
	Refresh()
end

local function Horizontal(dir)
	if state.row == 0 then
		local new = math.max(1, math.min(#Tabs, state.tab + dir))
		if new ~= state.tab then
			state.tab = new
			Play("Move")
		end
		Refresh()
	else
		ChangeValue(dir)
	end
end

-- ENTER / START (like the original game): on any tab except "Back" it moves to the NEXT tab; on "Back"
-- the next Enter closes the menu.
local function PressStart()
	Play("Move")
	if Tabs[state.tab].id == "back" then
		CloseMenu()
		return
	end
	state.tab = math.min(#Tabs, state.tab + 1)
	state.row = 0          -- the cursor goes back to the tab bar
	Refresh()
end

-- ---------- button input ----------
local ButtonMap = {
	MenuLeft = "left",  Left = "left",
	MenuRight = "right", Right = "right",
	MenuUp = "up",      Up = "up",
	MenuDown = "down",  Down = "down",
	Start = "start",    Center = "start",
	Back = "back",
}

local function IsEnabled(p)
	local ok, v = pcall(function() return GAMESTATE:IsPlayerEnabled(p) end)
	return ok and v
end

local function Input(event)
	if not event or not event.type then return false end

	-- Player the button belongs to. A button without a player, or from a player who is not playing (for
	-- example keys mapped to P2 while only P1 plays), counts as the master player's.
	local who = event.PlayerNumber
	if who == nil or not IsEnabled(who) then who = GAMESTATE:GetMasterPlayerNumber() end
	if who ~= pn then return false end   -- belongs to the other player: the other panel handles it

	local btn = ButtonMap[event.GameButton or event.button or ""]
	local first = event.type == "InputEventType_FirstPress"
	local repeating = event.type == "InputEventType_Repeat"

	if not btn or not (first or repeating) then return true end

	-- If the player had already closed and presses something again, the menu is "reopened".
	if POMenu.Done[pn] and first then POMenu.Done[pn] = nil end

	if btn == "left" then Horizontal(-1)
	elseif btn == "right" then Horizontal(1)
	elseif btn == "up" then Move(-1)
	elseif btn == "down" then Move(1)
	elseif first and btn == "start" then PressStart()
	elseif first and btn == "back" then CloseMenu(true)
	end
	return true
end

-- ============================================================================
-- ACTORS
-- ============================================================================
local t = Def.ActorFrame{
	InitCommand = function(self)
		local x = PANEL_X_P1 * S
		if pn == PLAYER_2 then x = SCREEN_WIDTH - (PANEL_X_P1 + PANEL_W) * S end
		self:xy(x, PANEL_Y * S):zoom(S)
	end,
	OnCommand = function(self)
		local screen = SCREENMAN:GetTopScreen()
		if screen and screen.AddInputCallback then screen:AddInputCallback(Input) end
		Refresh()
	end,
	OffCommand = function(self) self:diffusealpha(0) end,   -- the original closes in one frame
}

-- ---------- panel + OPENING animation (measured from the original's video) ----------
-- The panel starts as a thin white bar in the middle and stretches vertically to its full size; the content
-- (title, tabs, rows...) fades in when the panel is almost open. Times in seconds after the menu opens
-- (the original takes about 0.25 s in total):
--   0.00  thin bar (5% high)   0.05  20%   0.10  29%   0.15  70%   0.20  100%
-- To change how fast it opens, edit OPEN_STEP (duration of each step).
local PANEL_H = 727
local OPEN_STEP = 0.05
local OPEN_ZOOMY = { 0.05, 0.20, 0.29, 0.70, 1.0 }

-- Content: everything drawn over the panel. Invisible until the panel is almost open.
local C = Def.ActorFrame{
	Name = "Content",
	InitCommand = function(self) self:diffusealpha(0) end,
	OnCommand = function(self) self:sleep(OPEN_STEP * 3):linear(OPEN_STEP * 1.6):diffusealpha(1) end,
}

-- The panel scales around its vertical center, so it is wrapped in a frame placed at the center.
t[#t + 1] = Def.ActorFrame{
	Name = "PanelOpen",
	InitCommand = function(self) self:y(PANEL_H / 2):zoomy(OPEN_ZOOMY[1]) end,
	OnCommand = function(self)
		for i = 2, #OPEN_ZOOMY do self:linear(OPEN_STEP):zoomy(OPEN_ZOOMY[i]) end
	end,
	POTex("panel_base", { InitCommand = function(self) self:y(-PANEL_H / 2) end }),
}
t[#t + 1] = C

-- ---------- white header strip (behind "OPTION" and the icon; no texture) ----------
-- Size and color: POSettings.header_bg in Scripts/08 PlayerOptionsTextures.lua
C[#C + 1] = Def.Quad{
	Name = "HeaderBg",
	InitCommand = function(self)
		local h = POSettings.header_bg
		self:xy(h.x, h.y):halign(0):valign(0):setsize(h.w, h.h):diffuse(color(h.color))
	end,
}

-- ---------- "P1 Option" / "P2 Option" logo (drawn IN FRONT of the panel, like the original) ----------
-- Slots: title_option_logo_p1 and title_option_logo_p2
local logoSlot = "title_option_logo_" .. string.lower(pName)
C[#C + 1] = POTex(logoSlot, {
	InitCommand = function(self) self:xy(-60, -100) end,
	OnCommand = function(self)
		-- P2: the logo sticks out of the RIGHT edge of the panel (60 px outside)
		if pn == PLAYER_2 then
			local tex = self:GetChild("Tex")
			if tex then self:x(PANEL_W + 60 - tex:GetWidth() * tex:GetZoomX()) end
		end
	end,
})
C[#C + 1] = LoadFont(FONT)..{
	Text = pName .. " Option",
	InitCommand = function(self)
		self:xy(0, -40):halign(0):zoom(2):diffuse(color("#ff5aa0"))
		if POTexExists(logoSlot) then self:visible(false) end
	end,
}

-- The PNG has about 3 px of margin (x1.5 = 4.5): it is subtracted so the "O" starts at x=60, y=35
C[#C + 1] = POTex("title_option_text", { InitCommand = function(self) self:xy(55.5, 30.5) end })
C[#C + 1] = LoadFont(FONT)..{
	Text = "OPTION",
	InitCommand = function(self)
		self:xy(60, 48):halign(0):zoom(1.7):diffuse(BLACK)
		if POTexExists("title_option_text") then self:visible(false) end
	end,
}

-- icon + name of the active tab (next to "OPTION")
for _, tab in ipairs(Tabs) do
	if tab.id ~= "back" then
		C[#C + 1] = POTex("header_icon_" .. tab.id, {
			InitCommand = function(self)
				self:xy(227, 28)
				ui.headerIcon[tab.id] = self
			end,
		})
	end
end
C[#C + 1] = LoadFont(FONT)..{
	InitCommand = function(self)
		self:xy(262, 58):halign(0):zoom(0.85):diffuse(CYAN)
		ui.headerText = self
	end,
}

-- ---------- tabs ----------
-- Each tab = BACKGROUND (active/inactive, changes color) + ICON (always the same, centered).
-- NOTE: this function is CALLED further down, after the cyan frame, so the tabs and their icons end up ON
-- TOP of the frame (otherwise the frame's border would cover whatever sticks out of the icons).
local function AddTabs()
	for i, tab in ipairs(Tabs) do
		local isBack = tab.id == "back"
		local w = isBack and TAB_BACK_W or TAB_W   -- width of this tab

		-- off / on background
		C[#C + 1] = POTex(isBack and "tab_back_bg_off" or "tab_bg_off", {
			Name = "TabBgOff" .. i,
			InitCommand = function(self) self:xy(TAB_X[i], TAB_Y); ui.tabOff[i] = self end,
		})
		C[#C + 1] = POTex(isBack and "tab_back_bg_on" or "tab_bg_on", {
			Name = "TabBgOn" .. i,
			InitCommand = function(self) self:xy(TAB_X[i], TAB_Y); ui.tabOn[i] = self end,
		})

		-- icon centered over the background
		C[#C + 1] = POTex("tab_" .. tab.id, {
			Name = "TabIcon" .. i,
			InitCommand = function(self) self:xy(TAB_X[i], TAB_Y) end,
			OnCommand = function(self)
				local tex = self:GetChild("Tex")
				if not tex then return end
				local spec = POTextures["tab_" .. tab.id]
				local cx, cy = TAB_X[i] + w / 2, TAB_Y + TAB_H / 2   -- center of the tab
				if spec and spec.center then
					-- the PNG's 'center' point (center of the visible drawing) goes to the center of the tab
					local sc = spec.scale or 1
					self:xy(cx - spec.center.x * sc, cy - spec.center.y * sc)
				else
					-- no data: center the whole PNG
					local tw = tex:GetWidth() * tex:GetZoomX()
					local th = tex:GetHeight() * tex:GetZoomY()
					self:xy(cx - tw / 2, cy - th / 2)
				end
			end,
		})

		-- placeholder text: only while the icon PNG does not exist yet
		C[#C + 1] = LoadFont(FONT)..{
			Text = tab.title,
			InitCommand = function(self)
				self:xy(TAB_X[i] + w / 2, TAB_Y + TAB_H / 2):zoom(0.8):diffuse(BLACK)
				if POTexExists("tab_" .. tab.id) then self:visible(false) end
			end,
		}
	end
end

-- ---------- row area ----------
-- (The cyan frame is drawn AFTER the rows, further down, so it ends up on top.)
-- Gray fill: only while panel_section.png does not exist (the texture has a transparent interior that
-- lets panel_base show through, like the original).
C[#C + 1] = POTex("content_bg", {
	InitCommand = function(self)
		self:xy(57, 121)
		if POTexExists("section_box") then self:visible(false) end
	end,
})

-- Stripe bar of the selected row: a cyan strip with slanted black stripes that MOVE to the right in a
-- loop. It sits right BELOW the value box (it does not cover the progress bar). 'onInit' receives the
-- ActorFrame (to position it and keep a reference).
-- Measured from the original's video: the pattern repeats every 13 px at 720p (6 cyan + 7 black) =
-- 19.5 period and 10.5 black stripe in menu units.
local STRIPE_PERIOD = 19.5  -- distance between stripes
local STRIPE_BLACK  = 10.5  -- width of each black stripe
local STRIPE_H      = 4.5   -- height of the strip (3 px at 720p)
local STRIPE_SLANT  = 4.5   -- how much each stripe leans (the top shifts to the right)
local STRIPE_SPEED  = 30    -- speed: units per second
local function MakeStripes(onInit)
	local n = math.floor(VALUE_W / STRIPE_PERIOD) + 2
	local function cx(x) return math.max(0, math.min(VALUE_W, x)) end   -- clip to the box
	return Def.ActorFrame{
		InitCommand = onInit,
		Def.Quad{
			InitCommand = function(self)
				self:halign(0):valign(0):setsize(VALUE_W, STRIPE_H):diffuse(CYAN)
			end,
		},
		-- The black stripes. This engine has no SetUpdateFunction on this kind of actor, so the animation is a
		-- command loop: every ~1/60 s the vertices are recalculated from the current time.
		Def.ActorMultiVertex{
			InitCommand = function(self)
				self:SetDrawState{ Mode = "DrawMode_Quads" }
			end,
			OnCommand = function(self) self:playcommand("Tick") end,
			TickCommand = function(self)
				local p = self:GetParent()
				-- only recalculated while the row is selected (the stripes frame is visible)
				if (not p) or p:GetVisible() then
					local off = (GetTimeSinceStart() * STRIPE_SPEED) % STRIPE_PERIOD
					local v = {}
					for i = -1, n do
						local x0 = i * STRIPE_PERIOD + off   -- + = moves left to right
						local bl, br = x0, x0 + STRIPE_BLACK
						local tl, tr = x0 + STRIPE_SLANT, x0 + STRIPE_BLACK + STRIPE_SLANT
						v[#v + 1] = { { cx(bl), STRIPE_H, 0 }, BLACK }
						v[#v + 1] = { { cx(br), STRIPE_H, 0 }, BLACK }
						v[#v + 1] = { { cx(tr), 0, 0 }, BLACK }
						v[#v + 1] = { { cx(tl), 0, 0 }, BLACK }
					end
					self:SetVertices(v)
				end
				self:sleep(1 / 60):queuecommand("Tick")
			end,
		},
	}
end

-- Background of the options area: alternating BANDS with no gaps, like the original (no texture).
-- Odd rows (1, 3, 5, 7) = white with opacity; even rows (2, 4, 6) = dark gray with opacity. Each band is
-- 45 high (the whole row). They are also drawn over empty rows, up to the edge of the frame.
-- Colors and opacity: POSettings.row_band_odd / row_band_even.
for i = 1, 7 do
	local band = (i % 2 == 1) and POSettings.row_band_odd or POSettings.row_band_even
	C[#C + 1] = Def.Quad{
		Name = "RowBand" .. i,
		InitCommand = function(self)
			-- the first one starts 2 higher and the last reaches the edge of the frame (the cyan frame covers the edges)
			local y = ROW_Y0 + (i - 1) * ROW_STEP
			local h = ROW_STEP
			if i == 1 then y = y - 2; h = h + 2 end
			self:xy(57, y):halign(0):valign(0):setsize(546, h)
				:diffuse(color(band.color)):diffusealpha(band.alpha)
			ui.bands[i] = self   -- Refresh shows only the bands for rows that exist
		end,
	}
end

for slot = 1, POMenu.MaxRows do
	local a = {}
	ui.rows[slot] = a

	local row = Def.ActorFrame{
		InitCommand = function(self)
			self:xy(0, ROW_Y0 + (slot - 1) * ROW_STEP)
			a.frame = self
		end,

		-- cyan strip of the selected row (the whole row: 45 high, touching its neighbors)
		POTex("row_bg_focus", { InitCommand = function(self) self:x(57); a.bgFocus = self end }),

		-- label. Size measured from the reference: "SCROLL SPEED" is about 190 wide and long labels are
		-- compressed horizontally down to about 257 (like "ARROW START LANE PREVIEW").
		LoadFont(FONT)..{
			InitCommand = function(self)
				self:xy(LABEL_X, 18):halign(0):zoom(LABEL_ZOOM):maxwidth(LABEL_MAXW / LABEL_ZOOM):diffuse(BLACK)
				a.label = self
			end,
		},

		-- name of the option as a PNG (176x16 per language at 720p, scale 1.5); centered on the line of the label
		Def.Sprite{
			InitCommand = function(self)
				self:xy(LABEL_X, 6):halign(0):valign(0):zoom(1.5):visible(false)
				a.titleImage = self
			end,
		},

		-- value box
		Def.ActorFrame{
			InitCommand = function(self) self:x(VALUE_X); a.valueFrame = self end,
			POTex("value_bg",       { InitCommand = function(self) a.valueBg = self end }),
			POTex("value_bg_focus", { InitCommand = function(self) a.valueBgFocus = self end }),
			POTex("value_bar",      { InitCommand = function(self) self:y(31); a.bar = self end }),

			-- Diagonal (cyan / black) STRIPE bar that replaces the progress bar while the row is selected.
			-- y = 36: right below the value box (which is 36 high)
			MakeStripes(function(self) self:y(36); a.stripes = self end),

			-- triangles at the sides (selected row only): left / right
			Def.ActorMultiVertex{
				InitCommand = function(self)
					self:SetDrawState{ Mode = "DrawMode_Triangles" }
					self:SetVertices{
						{ { 8, 15, 0 },  CYAN },   -- tip (left)
						{ { 22, 6, 0 },  CYAN },
						{ { 22, 24, 0 }, CYAN },
					}
					a.arrowL = self
				end,
			},
			Def.ActorMultiVertex{
				InitCommand = function(self)
					self:SetDrawState{ Mode = "DrawMode_Triangles" }
					self:SetVertices{
						{ { VALUE_W - 8, 15, 0 },  CYAN },   -- tip (right)
						{ { VALUE_W - 22, 6, 0 },  CYAN },
						{ { VALUE_W - 22, 24, 0 }, CYAN },
					}
					a.arrowR = self
				end,
			},

			LoadFont(FONT)..{
				InitCommand = function(self)
					self:xy(VALUE_W / 2, 17):zoom(1.15):maxwidth((VALUE_W - 12) / 1.2):diffuse(CYAN)
					a.value = self
				end,
			},
		},

		-- info line (min ~ core ~ max)
		Def.ActorFrame{
			InitCommand = function(self) self:x(204); a.infoFrame = self end,
			-- cyan strip of the whole row: only while the speed value is selected (in the original the strip
			-- also covers this line).
			Def.Quad{
				InitCommand = function(self)
					self:xy(57 - 204, 0):halign(0):valign(0):setsize(546, ROW_STEP):diffuse(color(POSettings.frame_color))
					a.infoBand = self
				end,
			},
			-- off / on box. Measured from the reference: 390 x 36 (260 x 24 px at 720p), its right edge lined up
			-- with the value box and 1 px below the top edge of the row. The textures have a spare border (4 px
			-- left, 2 top, 2 bottom; see 'crop' in Scripts/08 PlayerOptionsTextures.lua) that is trimmed so
			-- they match the original's size.
			POTex("info_bg_off", {
				InitCommand = function(self) self:xy(0, 1.5); a.infoBgOff = self end,
			}),
			POTex("info_bg_on", {
				InitCommand = function(self) self:xy(0, 1.5); a.infoBgOn = self end,
			}),
			-- Placeholder texts: "scroll speed", MIN, CORE, MAX. The info_bg_on/off textures already have them
			-- drawn, so these only show while those images do not exist yet.
			-- (The numbers below, infoMin/infoCore/infoMax, are always drawn.)
			LoadFont(FONT)..{
				Text = "scroll speed",
				InitCommand = function(self)
					self:xy(60, 18):halign(0):zoom(0.9):diffuse(WHITE)
					if POTexExists("info_bg_on") and POTexExists("info_bg_off") then self:visible(false) end
				end,
			},
			LoadFont(FONT)..{ Text = "MIN",  InitCommand = function(self)
				self:xy(226, 6):zoom(0.45):diffuse(WHITE)
				if POTexExists("info_bg_on") and POTexExists("info_bg_off") then self:visible(false) end
			end },
			LoadFont(FONT)..{ Text = "CORE", InitCommand = function(self)
				self:xy(280, 6):zoom(0.45):diffuse(WHITE)
				if POTexExists("info_bg_on") and POTexExists("info_bg_off") then self:visible(false) end
			end },
			LoadFont(FONT)..{ Text = "MAX",  InitCommand = function(self)
				self:xy(344, 6):zoom(0.45):diffuse(WHITE)
				if POTexExists("info_bg_on") and POTexExists("info_bg_off") then self:visible(false) end
			end },
			-- min ~ core ~ max numbers. Positions measured from the reference: RIGHT aligned (the right edge of
			-- each group, "~" included, lands at x = 262.5, 327 and 370.5) and centered 18 below the top edge
			-- of the row. Their color depends on the box (see Refresh).
			LoadFont(FONT)..{ InitCommand = function(self) self:xy(262.5, 18):halign(1):zoom(INFO_NUM_ZOOM):diffuse(WHITE); a.infoMin = self end },
			LoadFont(FONT)..{ InitCommand = function(self) self:xy(327, 18):halign(1):zoom(INFO_NUM_ZOOM):diffuse(WHITE); a.infoCore = self end },
			LoadFont(FONT)..{ InitCommand = function(self) self:xy(370.5, 18):halign(1):zoom(INFO_NUM_ZOOM):diffuse(WHITE); a.infoMax = self end },
		},
	}
	C[#C + 1] = row
end

-- ---------- cyan frame of the options (over the rows) ----------
-- Drawn in code with 4 equal sides (see POSettings in Scripts/08 PlayerOptionsTextures.lua), because the
-- PNG's borders are uneven.
C[#C + 1] = POFrameQuads(54, 118, 552, 321)

-- ---------- tabs (over the frame) ----------
AddTabs()

-- ---------- explanation box ----------
-- Dark box: slot section_box (bottom part of panel_section.png).
C[#C + 1] = POTex("section_box", { InitCommand = function(self) self:xy(54, 456) end })
-- Image of the selected value (explanation/<tab>/<option>/explanation_<value> 1x3.png). 368x172 per language at 720p;
-- the dark box is the 372x171 part of panel_section.png at scale 1.485, so the image is drawn at the same scale with
-- 2 px of margin. The dotted line that separates text and drawing is part of the PNG.
C[#C + 1] = Def.Sprite{
	Name = "ExplanationImage",
	InitCommand = function(self)
		self:xy(54 + 2 * 1.485, 456):halign(0):valign(0):zoom(1.485):visible(false)
		ui.explainImage = self
	end,
}
-- Explanation text: only when the value has no image (for example the plain noteskin list)
C[#C + 1] = LoadFont(FONT)..{
	InitCommand = function(self)
		self:xy(54 + 17, 456 + 18):halign(0):valign(0):zoom(1.0):wrapwidthpixels(222):diffuse(WHITE)
		ui.explainText = self
	end,
}

return t
