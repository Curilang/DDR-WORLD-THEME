-- ============================================================================
-- WHEEL BUTTONS: the two buttons at the start of the list ("Change folder" and "MUSIC FILTER")
-- ============================================================================
-- The original has two big buttons between the last row of songs and the first one: the first opens the folder screen,
-- the second the filter menu. They are not choices of a menu: the player gets to them with the cursor, like to a song.
--
-- The engine's list has ONE item there (the header of the list, the only section), so the two buttons are drawn inside that
-- item, one on top of the other, and the theme keeps which one has the cursor (WheelButtons.Sel):
--   * LEFT from the first song arrives at the FILTER button (the one next to it), RIGHT from the last song arrives at the
--     FOLDER one. UP / DOWN and LEFT / RIGHT go from one button to the other; at the edge they go on to the songs (the
--     normal move). LEFT / RIGHT are done by SideStep (see below): the engine's step is cancelled in the same event.
--   * START on the header opens the folder screen or the filter menu (BGAnimations/ScreenSelectMusic overlay/default.lua).
--
-- Textures (Graphics/MusicWheelItem/buttons/): textures/ has the backgrounds (wheel_folder_base /
-- _selected, wheel_filter_base / _selected) and the logo of each folder (wheel_folder_<name>.png, the one chosen in the folder
-- screen); text/ has the texts, each one with the three languages one below the other. They are placed in the pixels of the
-- original (see Layout below) and scaled to the size of the button. While a PNG is missing the button is a colored rectangle
-- with text. The numbers (songs in the folder, what the filter has chosen) are always text on top.
--
-- Used from: Graphics/MusicWheelItem SectionCollapsed NormalPart.lua (drawing), Scripts/08 WheelLayout.lua (room for the
-- buttons), BGAnimations/ScreenSelectMusic decorations/InputHandler.lua (UP / DOWN).
-- ============================================================================

WheelButtons = {}

-- size of the buttons in wheel units (the original's are about 402 x 77 and 402 x 72 pixels: the wheel is drawn at 0.6)
WheelButtons.SIZE = { w = 676, folder = 130, filter = 122, gap = 6 }

WheelButtons.FOLDER = 1
WheelButtons.FILTER = 2
WheelButtons.Sel = 1   -- the button that has the cursor when the header has it

-- true when the header of the wheel is drawn as the two buttons: the theme's main list (one list with the folder and the
-- filter), not an extra stage or a course
function WheelButtons.Enabled()
	if not (Filter and Filter.FlatByDefault and Filter.Folders and LevelSort and LevelSort.Loaded and Filter.SectionName) then
		return false
	end
	return not GAMESTATE:IsCourseMode()
end

-- the section name of the main list is "<folder or FILTER> (205 SONGS)"
function WheelButtons.IsHeader(text)
	return text ~= nil and WheelButtons.Enabled() and string.find(text, "%(%d+ %u+%)") ~= nil
end

-- true when the wheel item numbered `index` (the numbering of the Set messages) is the header of the list
function WheelButtons.IsHeaderIndex(index)
	local block = WheelCache and WheelCache.Block()
	if not block then return index == 0 end   -- (a closed list: the header is the only item)
	return (index - (block.first - 1)) % block.total == 0
end
local function Changed()
	MESSAGEMAN:Broadcast("WheelButtonsChanged")
end

-- UP (dir -1) / DOWN (dir 1) with the cursor on the header: from one button to the other. Returns true when it was
-- used (the wheel must not move); false at the edge or when the cursor is not on the header.
function WheelButtons.Step(wheel, dir)
	if not WheelButtons.Enabled() or not wheel then return false end
	if ToEnumShortString(wheel:GetSelectedType()) ~= "Section" then return false end
	local target = WheelButtons.Sel + dir
	if target < 1 or target > 2 then return false end
	WheelButtons.Sel = target
	pcall(function() SOUND:PlayOnce(THEME:GetPathS("WORLD/Wheel", "change")) end)
	Changed()
	return true
end

-- LEFT (dir -1) / RIGHT (dir 1) with the cursor on the buttons: from one button to the other, like UP / DOWN.
-- The engine handles LEFT / RIGHT BEFORE the theme's input callback sees the event (PreviousSongButton / NextSongButton; measured in
-- Logs/log.txt: the index seen by the callback is already the one AFTER the step), so SideStep works on the result:
--   * the cursor has just landed on the header: it came from a side, so LEFT = the filter button (next to the first song) and
--     RIGHT = the folder button (next to the last one);
--   * the cursor has just left the header (it was on it): if the other button is next in that direction, the wheel is moved back
--     (Move(-dir)) so the cursor stays on the header and only the button changes; at the edge (LEFT on the folder button, RIGHT on
--     the filter one) nothing is done and the engine's step stands: out to the last / first song.
-- (A first version assumed the step had not happened yet: it pushed the cursor off the header the moment it arrived.)
WheelButtons.Hold = nil   -- { sel, untilTime }: the button chosen by the last LEFT / RIGHT while the wheel goes out and back in

-- TEMPORARY (to find out what the engine does on LEFT / RIGHT): one line in the log (Logs/log.txt, "SIDE ...") per event
function WheelButtons.TraceSide(what, wheel)
	local idx, kind = "?", "?"
	pcall(function() idx = tostring(wheel:GetCurrentIndex()) end)
	pcall(function() kind = ToEnumShortString(wheel:GetSelectedType()) end)
	Trace(string.format("SIDE %.3f %s | index=%s type=%s Sel=%d focus=%s", GetTimeSinceStart(), what, idx, kind, WheelButtons.Sel,
		tostring(WheelLayout and WheelLayout.Focus and WheelLayout.Focus())))
end

function WheelButtons.SideStep(wheel, dir)
	if not WheelButtons.Enabled() or not wheel then return false end
	local block = WheelCache and WheelCache.Block()
	local idx
	pcall(function() idx = wheel:GetCurrentIndex() end)
	if not block or not idx or block.total < 2 then return false end
	local total = block.total
	local j = (idx - (block.first - 1)) % total   -- where the cursor is NOW (0 = the header, 1 .. songs)
	local before = (j - dir) % total               -- where it was before the engine's step

	if j == 0 then
		-- landed on the header from the first song (LEFT: the filter button) or from the last one (RIGHT: the folder button)
		WheelButtons.Sel = dir < 0 and WheelButtons.FILTER or WheelButtons.FOLDER
		WheelButtons.Hold = nil
		Changed()
		WheelButtons.TraceSide("landed on the header", wheel)
		return true
	end

	if before == 0 then
		-- the cursor was on the header and the engine has just taken it to a song
		local target = WheelButtons.Sel + dir
		if target >= WheelButtons.FOLDER and target <= WheelButtons.FILTER then
			WheelButtons.Sel = target
			WheelButtons.Hold = { sel = target, untilTime = GetTimeSinceStart() + 0.3 }
			pcall(function() wheel:Move(-dir); wheel:Move(0) end)   -- back to the header
			pcall(function() SOUND:PlayOnce(THEME:GetPathS("WORLD/Wheel", "change")) end)
			Changed()
			WheelButtons.TraceSide("button step " .. dir .. " -> Sel " .. target .. ", wheel moved back", wheel)
			return true
		end
		WheelButtons.Hold = nil
		WheelButtons.TraceSide("left the header (edge)", wheel)
	end
	return false
end

-- The cursor went to the item `index` (the numbering of the Set messages; `previous` is where it was): when that is the
-- header, the button it lands on depends on the side it came from (called by WheelLayout.NoteFocus).
function WheelButtons.Arrived(previous, index)
	if not WheelButtons.Enabled() then return end
	local block = WheelCache and WheelCache.Block()
	if not block or block.total < 2 then return end
	local head = block.first - 1
	if (index - head) % block.total ~= 0 then return end   -- not the header
	-- the wheel is going out and back in the same moment (SideStep): the button was chosen there, not by the side it came from
	local hold = WheelButtons.Hold
	Trace(string.format("SIDE %.3f Arrived at the header: previous=%s index=%s Sel=%d hold=%s", GetTimeSinceStart(), tostring(previous),
		tostring(index), WheelButtons.Sel, tostring(hold and GetTimeSinceStart() < hold.untilTime)))
	if hold and GetTimeSinceStart() < hold.untilTime then
		if hold.sel ~= WheelButtons.Sel then
			WheelButtons.Sel = hold.sel
			Changed()
		end
		return
	end
	local sel = 1
	if previous ~= nil then
		-- from the first row of songs (below the buttons): the filter button, the one next to it
		local j = (previous - head) % block.total
		if j >= 1 and j <= 3 then sel = 2 end
	end
	if sel ~= WheelButtons.Sel then
		WheelButtons.Sel = sel
		Changed()
	end
end

-- UP (dir -1) from the first row of songs, DOWN (dir 1) from the last row: how many items the wheel has to move to reach
-- the header (the two buttons). nil when it is not that case (the normal move of a row is used).
function WheelButtons.ToHeader(dir)
	if not WheelButtons.Enabled() or not WheelLayout or not WheelLayout.Focus then return nil end
	local block = WheelCache and WheelCache.Block()
	local focus = WheelLayout.Focus()
	if not block or focus == nil or block.total < 2 then return nil end
	local songs = block.last - block.first + 1
	local j = (focus - (block.first - 1)) % block.total   -- place in the list: 1 .. songs
	if j < 1 then return nil end
	if dir < 0 and j <= 3 then return -j end
	if dir > 0 and j > 3 * (math.ceil(songs / 3) - 1) then return block.total - j end
	return nil
end

-- ---------------------------------------------------------------------------
-- Textures and texts of the buttons
-- ---------------------------------------------------------------------------

-- The PNG `name` (relative to Graphics/MusicWheelItem/buttons/, without ".png"), or nil (the answer is kept: the files do
-- not change while the game runs)
local textures = {}
function WheelButtons.Tex(name)
	local path = textures[name]
	if path == nil then
		local dir = THEME:GetCurrentThemeDirectory()
		if string.sub(dir, 1, 1) ~= "/" then dir = "/" .. dir end
		if string.sub(dir, -1) ~= "/" then dir = dir .. "/" end
		path = dir .. "Graphics/MusicWheelItem/buttons/" .. name .. ".png"
		if not FILEMAN:DoesFileExist(path) then path = false end
		textures[name] = path
	end
	return path or nil
end

-- the first PNG of a list of names that exists (the texts can be called with or without " 1x3")
function WheelButtons.TexAny(names)
	for _, name in ipairs(names) do
		local path = WheelButtons.Tex(name)
		if path then return path end
	end
	return nil
end

-- The logo of the folder chosen in the folder screen (textures/wheel_folder_<name>.png, 220 x 60)
local LOGO = { FIRST = "firststep", POP = "popmusic", VIRTUAL = "wirtualpop", ANIME = "animegames", TOUHOU = "touhouproject",
	GAMERS = "musicgamers", ALL = "allmusic" }
function WheelButtons.LogoPath()
	local id = Filter and Filter.GetFolder and Filter.GetFolder() or "ALL"
	return WheelButtons.Tex("textures/wheel_folder_" .. (LOGO[id] or LOGO.ALL))
end

-- What the buttons say, from the name of the header ("ALL MUSIC (205 SONGS)"). Kept while nothing changes.
local infoKey, infoValue
function WheelButtons.Info(text)
	local key = tostring(text) .. "|" .. (Filter.Signature and Filter.Signature() or "")
	if infoKey == key then return infoValue end
	local count, unit = string.match(text or "", "%((%d+) (%u+)%)")
	count = tonumber(count) or 0
	local charts = unit == "CHARTS"
	local total = count
	pcall(function() total = Filter.FolderStats("ALL") or count end)
	local summary = Filter.Summary and Filter.Summary() or ""
	if summary == "" then summary = "NO FILTER" end
	infoValue = {
		name = Filter.FolderName(),
		count = string.format("%d %s (out of %d total)", count, charts and "Chart(s)" or "Song(s)", total),
		filter = string.format("%s ( %d %s )", summary, count, charts and "Charts" or "Songs"),
	}
	infoKey = key
	return infoValue
end

-- ---------------------------------------------------------------------------
-- Layout: the textures are the original's pixels (a button is 404 x 76 / 404 x 72); everything is placed in those pixels,
-- from the top left corner of the button, and scaled to the size of the button in wheel units
-- ---------------------------------------------------------------------------
local TEX_W, FOLDER_H, FILTER_H = 404, 76, 72
local function KX() return WheelButtons.SIZE.w / TEX_W end
local function KY(button) return WheelButtons.SIZE[button] / (button == "folder" and FOLDER_H or FILTER_H) end
-- x / y of the point (tx, ty) of the texture, in the frame of the button (centered)
local function PX(tx) return (tx - TEX_W / 2) * KX() end
local function PY(button, ty) return (ty - (button == "folder" and FOLDER_H or FILTER_H) / 2) * KY(button) end

-- the small logo of the folder button when it has the cursor
local SMALL = { x = 4, y = 8.5, zoom = 0.47 }

-- ---------------------------------------------------------------------------
-- The actors
-- ---------------------------------------------------------------------------


-- NOTE: the wheel makes its items by COPYING one, and the copies share the variables of this file's functions: nothing that
-- belongs to one item (the cursor, the actors) can be kept in a variable. Each item keeps it on its own actors, and finds
-- its parts by name (the first version kept the actors in a table and the copies used actors that no longer existed).
local function Part(root, button, name)
	local frame = root:GetChild(button)
	return frame and frame:GetChild(name)
end

local function Show(actor, value)
	if actor then actor:visible(value) end
end

local function Refresh(root)
	local focus = root.focus and true or false
	local function Folder(name) return Part(root, "Folder", name) end
	local function Filter_(name) return Part(root, "Filter", name) end

	local on = focus and WheelButtons.Sel == WheelButtons.FOLDER
	Show(Folder("Off"), not on); Show(Folder("On"), on); Show(Folder("Stripes"), on)
	Show(Folder("Count"), not on); Show(Folder("TxtChange"), not on); Show(Folder("TxtGuide"), not on)
	Show(Folder("TxtSelected"), on)
	Show(Folder("Hint"), not on); Show(Folder("StaticOff"), not on); Show(Folder("StaticOn"), on)
	local logo = Folder("Logo")
	if logo then
		if on then
			-- with the cursor: a small logo at the top left, drawn ADDED to the turquoise (the red of its shadow turns
			-- cream and the letters white-turquoise, like the original)
			logo:xy(PX(SMALL.x), PY("folder", SMALL.y)):zoomx(KX() * SMALL.zoom):zoomy(KY("folder") * SMALL.zoom)
				:blend("BlendMode_Add")
		else
			logo:xy(PX(3), PY("folder", 0)):zoomx(KX()):zoomy(KY("folder")):blend("BlendMode_Normal")
		end
	end
	local name = Folder("Name")
	if name then
		if on then name:y(0):zoom(0.8) else name:y(-22):zoom(1.1) end
	end

	on = focus and WheelButtons.Sel == WheelButtons.FILTER
	Show(Filter_("Off"), not on); Show(Filter_("On"), on); Show(Filter_("Stripes"), on)
	Show(Filter_("TxtFilter"), not on); Show(Filter_("TxtGuide"), not on); Show(Filter_("TxtSelected"), on)
	Show(Filter_("Hint"), not on); Show(Filter_("StaticOff"), not on); Show(Filter_("StaticOn"), on)
	local summary = Filter_("Summary")
	if summary then
		summary:y(PY("filter", on and 58 or 59)):diffuse(on and color("#000000") or color("#19D3B0"))
	end
end

local function SetText(actor, text)
	if actor and actor.shown ~= text then
		actor:settext(text)
		actor.shown = text
	end
end

-- Returns the ActorFrame with both buttons (it hides itself unless the item is the header of the main list).
function WheelButtons.Make()
	local S = WheelButtons.SIZE
	local ACCENT, BLACK, WHITE = color("#19D3B0"), color("#000000"), color("#FFFFFF")
	local UI_FONT = "_avenirnext lt pro bold Bold 20px"
	local BIG_FONT = "MusicWheelItem GroupNames"

	local function Label(name, font, x, y, zoom, align, maxwidth, c, text)
		return Def.BitmapText{
			Name = name, Font = font, Text = text or "",
			InitCommand = function(s)
				s:xy(x, y):zoom(zoom):halign(align):diffuse(c)
				if maxwidth then s:maxwidth(maxwidth / zoom) end
			end,
		}
	end

	-- A text of the buttons: a PNG with the three languages one below the other (English, Japanese, Korean: the order of
	-- GetCurrentLanguage). It can be a "... 1x3.png" (the engine cuts it) or a plain PNG three times as tall (cut here).
	-- (tx, ty) = the center of the text in the pixels of the button. Nil when the PNG does not exist.
	local function TextTex(name, button, files, tx, ty)
		local path = WheelButtons.TexAny(files)
		if not path then return nil end
		return Def.Sprite{
			Name = name, Texture = path,
			InitCommand = function(s)
				local lang = GetCurrentLanguage and GetCurrentLanguage() or 0
				local frames = 1
				pcall(function() frames = s:GetNumStates() end)
				local w, h = s:GetWidth(), s:GetHeight()
				if frames >= 3 then
					s:animate(false):setstate(math.min(lang, frames - 1))
				else
					-- (a plain PNG three times as tall: the whole image is drawn and cropped to the third of the language,
					-- moved so that the third lands on the center; names with " 1x3" are cut by the engine and do not come here)
					h = h / 3
					s:setsize(w * KX(), h * 3 * KY(button)):xy(PX(tx), PY(button, ty) - (lang - 1) * h * KY(button))
						:croptop(lang / 3):cropbottom((2 - lang) / 3)
					return
				end
				s:setsize(w * KX(), h * KY(button)):xy(PX(tx), PY(button, ty))
			end,
		}
	end

	-- The two states of the background (a PNG or a colored rectangle) and the moving stripes of the one with the cursor.
	local function Background(button, h, files, offColor)
		local out = {}
		for i, state in ipairs({ "off", "on" }) do
			local path = WheelButtons.Tex(files[i])
			local name = state == "on" and "On" or "Off"
			if path then
				out[#out + 1] = Def.Sprite{ Name = name, Texture = path, InitCommand = function(s) s:setsize(S.w, h) end }
			else
				out[#out + 1] = Def.Quad{
					Name = name,
					InitCommand = function(s) s:setsize(S.w, h):diffuse(state == "on" and ACCENT or offColor) end,
				}
			end
		end
		out[#out + 1] = StripeLine{
			Name = "Stripes",
			w = S.w, h = 14, y = h / 2 - 4 - 2, visible = false,
			period = 26, band = 13, slant = 13,
			speed = 42,
		}
		return out
	end

	local top = -(S.folder + S.gap + S.filter) / 2

	-- ---- FOLDER ----
	local folder = Def.ActorFrame{ Name = "Folder", InitCommand = function(s) s:y(top + S.folder / 2) end }
	for _, a in ipairs(Background("folder", S.folder, { "textures/wheel_folder_base", "textures/wheel_folder_selected" },
			color("#E9E9E9"))) do
		folder[#folder + 1] = a
	end
	local firstLogo = WheelButtons.LogoPath()
	if firstLogo then
		-- (the texture is changed in SetCommand when the folder changes; the position / size / color in Refresh)
		folder[#folder + 1] = Def.Sprite{ Name = "Logo", Texture = firstLogo, InitCommand = function(s) s:halign(0):valign(0) end }
	else
		folder[#folder + 1] = Label("Name", BIG_FONT, PX(27), PY("folder", 22), 1.1, 0, 300, BLACK, "")
	end
	-- "205 Song(s) (out of 1387 total)" under the logo
	folder[#folder + 1] = Label("Count", UI_FONT, PX(27), PY("folder", 56), 0.9, 0, 305, WHITE, "")
	local tChange = TextTex("TxtChange", "folder", { "text/wheel_folder_txt_change 1x3", "text/wheel_folder_txt_change" }, 318, 43)
	local tGuide = TextTex("TxtGuide", "folder", { "text/wheel_folder_text_buttons 1x3", "text/wheel_folder_text_buttons" }, 316, 57)
	local tSelected = TextTex("TxtSelected", "folder", { "text/wheel_folder_txt_selected 1x3", "text/wheel_folder_txt_selected" }, 210, 41)
	if tChange then folder[#folder + 1] = tChange end
	if tGuide then folder[#folder + 1] = tGuide end
	if tSelected then folder[#folder + 1] = tSelected end
	if not tChange then
		folder[#folder + 1] = Label("StaticOff", UI_FONT, 215, -14, 0.8, 0.5, nil, BLACK, "Change folder")
		folder[#folder + 1] = Label("Hint", UI_FONT, 215, 14, 0.5, 0.5, nil, color("#555555"), "UP + DOWN")
	end
	if not tSelected then
		folder[#folder + 1] = Label("StaticOn", UI_FONT, 40, -2, 1.0, 0.5, nil, BLACK, "Change folder")
	end

	-- ---- FILTER ----
	local filter = Def.ActorFrame{ Name = "Filter", InitCommand = function(s) s:y(top + S.folder + S.gap + S.filter / 2) end }
	for _, a in ipairs(Background("filter", S.filter, { "textures/wheel_filter_base", "textures/wheel_filter_selected" },
			color("#202020"))) do
		filter[#filter + 1] = a
	end
	local fText = TextTex("TxtFilter", "filter", { "text/muca_filter_text 1x3", "text/wheel_filter_txt 1x3", "text/wheel_filter_txt", "text/muca_filter_text" }, 202, 14)
	local fGuide = TextTex("TxtGuide", "filter", { "text/wheel_filter_buttons 1x3", "text/wheel_filter_buttons" }, 202, 41)
	local fSelected = TextTex("TxtSelected", "filter", { "text/wheel_filter_txt_selected 1x3", "text/wheel_filter_txt_selected" }, 210, 34)
	if fText then filter[#filter + 1] = fText end
	if fGuide then filter[#filter + 1] = fGuide end
	if fSelected then filter[#filter + 1] = fSelected end
	if not fText then
		filter[#filter + 1] = Label("StaticOff", BIG_FONT, 0, -30, 1.0, 0.5, 300, WHITE, "MUSIC FILTER")
		filter[#filter + 1] = Label("Hint", UI_FONT, 0, -2, 0.5, 0.5, nil, color("#BBBBBB"), "LEFT + RIGHT")
	end
	if not fSelected then
		filter[#filter + 1] = Label("StaticOn", BIG_FONT, 0, -18, 1.0, 0.5, 300, BLACK, "MUSIC FILTER")
	end
	-- "DDR A3 ( 205 Songs )": turquoise on the dark button, black on the turquoise one (Refresh)
	filter[#filter + 1] = Label("Summary", UI_FONT, 0, PY("filter", 59), 0.65, 0.5, 600, ACCENT, "")

	return Def.ActorFrame{
		InitCommand = function(s) s:visible(false) end,   -- (shown by WheelLayout.Update while the item is the header)
		SetCommand = function(self, p)
			if p.Index == nil then return end
			-- the wheel item that holds this part: the layout shows / hides the buttons with it, every frame (a visible()
			-- set from here showed them for a moment and hid them again while the wheel moved)
			local part = self:GetParent()
			local item = part and part:GetParent()
			-- (an item has one copy of this part for each kind of header, expanded and collapsed: all of them are kept)
			if item then
				item.buttons = item.buttons or {}
				if not item.buttons[self] then
					item.buttons[self] = true
					item.buttonsShown = nil
				end
			end
			-- (the songs of the list also get this message, with the name of the list as their text)
			local header = WheelButtons.IsHeader(p.Text) and WheelButtons.IsHeaderIndex(p.Index)
			self.focus = header and p.HasFocus and true or false
			if not header then return end
			if not (WheelLayout and WheelLayout.Active()) then self:visible(true) end   -- (no layout: the engine's column)
			local info = WheelButtons.Info(p.Text)
			SetText(Part(self, "Folder", "Name"), info.name)
			SetText(Part(self, "Folder", "Count"), info.count)
			SetText(Part(self, "Filter", "Summary"), info.filter)
			-- the logo of the folder chosen in the folder screen
			local logo = Part(self, "Folder", "Logo")
			local path = logo and WheelButtons.LogoPath()
			if path and logo.shownPath ~= path then
				logo:Load(path)
				logo.shownPath = path
			end
			Refresh(self)
		end,
		WheelButtonsChangedMessageCommand = function(self) Refresh(self) end,
		folder,
		filter,
	}
end