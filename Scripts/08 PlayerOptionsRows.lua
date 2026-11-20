-- ============================================================================
-- ROW LOGIC OF THE PLAYER OPTIONS MENU (DDR WORLD style)
-- ============================================================================
-- This file defines WHICH options exist, which tab each one belongs to, and how it is read and saved.
-- Drawing (colors, positions) is in:   BGAnimations/ScreenPlayerOptions overlay/options.lua
-- Textures are declared in:            Scripts/08 PlayerOptionsTextures.lua
--
-- Every row (POMenu.Rows[id]) has:
--   title    text of the label (left side); can also be a function(pn)
--   count    function(pn)      -> how many choices it has
--   text     function(pn,idx)  -> text shown for choice idx
--   get      function(pn)      -> current choice (1..count)
--   set      function(pn,idx)  -> applies and saves choice idx
--   explain  text (or function(pn,idx)) shown in the box at the bottom
--   wired    false = the option does not affect gameplay yet (its value is only stored)
--   kind     "info" = read-only line (cannot be selected)
-- ============================================================================

POMenu = {}
POMenu.Done = {}
POMenu.NeedsReload = false

-- ---------- helpers ----------
local cache = {}

function POMenu.ResetCache()
	cache = {}
	POMenu.Done = {}
	POMenu.NeedsReload = false
end

local function PrefGet(name, default)
	if cache[name] == nil then
		local v = nil
		-- Check that the file exists first so the log is not filled with "Error reading ...cfg"
		-- the first time (which is normal).
		local path = "Save/UserPrefs/" .. THEME:GetThemeDisplayName() .. "/" .. name .. ".cfg"
		if FILEMAN:DoesFileExist("/" .. path) then v = ReadPrefFromFile(name) end
		if v == nil then v = default end
		cache[name] = v
	end
	return cache[name]
end

local function PrefSet(name, value)
	cache[name] = tostring(value)
	SetUserPref(name, value)
end

local function PName(pn) return ToEnumShortString(pn) end

local function PO(pn)
	return GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")
end

-- On/off mods (Mirror, Little, NoHolds...) and numeric mods (Reverse, Dark, Boost...)
local function SetBool(pn, mod, v)
	local po = PO(pn)
	pcall(function() po[mod](po, v and true or false) end)
end

local function SetFloat(pn, mod, v)
	local po = PO(pn)
	pcall(function() po[mod](po, v) end)
end

local function GetMod(pn, mod)
	local po = PO(pn)
	local ok, v = pcall(function() return po[mod](po) end)
	if ok then return v end
	return nil
end

-- Opciones de CANCIÓN (SongOptions): se aplican a ambos jugadores.
-- Se escribe en Preferred y en Song para que valga en el preview y en gameplay.
local function SetSongOpt(method, value)
	for _, lvl in ipairs({ "ModsLevel_Preferred", "ModsLevel_Song" }) do
		local so = GAMESTATE:GetSongOptionsObject(lvl)
		if so then pcall(function() so[method](so, value) end) end
	end
end

local function GetSongOpt(method)
	local so = GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred")
	if not so then return nil end
	local ok, v = pcall(function() return so[method](so) end)
	if ok then return v end
	return nil
end

local function RangeCount(min, max, step)
	return math.floor((max - min) / step + 0.5) + 1
end

local function RangeValue(min, step, idx)
	return min + (idx - 1) * step
end

local function RangeIndex(min, max, step, val)
	local i = math.floor((val - min) / step + 0.5) + 1
	return math.max(1, math.min(RangeCount(min, max, step), i))
end

local function Signed(v, suffix)
	if v == 0 then return "±0" .. suffix end
	return string.format("%+d", v) .. suffix
end

-- Simple row with a fixed list of texts.
local function ChoiceRow(def)
	def.count = function() return #def.choices end
	def.text = function(pn, idx) return def.choices[idx] or "" end
	return def
end

-- Pending row: it stores the value per player but does not affect gameplay yet.
local function StubRow(def)
	def.wired = false
	local key = "PO_" .. def.id
	def.get = function(pn)
		return tonumber(PrefGet(key .. "_" .. PName(pn), "1")) or 1
	end
	def.set = function(pn, idx)
		PrefSet(key .. "_" .. PName(pn), idx)
	end
	return ChoiceRow(def)
end

-- Row backed by a global preference file (the old OptionRow* settings).
local function BoolPrefRow(def)
	-- def.pref = preference file name; def.trueIdx = the choice that means "true"
	def.get = function(pn)
		local v = PrefGet(def.pref, def.default)
		if v == "true" or v == "On" then return def.trueIdx end
		return 3 - def.trueIdx
	end
	return ChoiceRow(def)
end

-- ============================================================================
-- SCROLL SPEED (Real Speed / X-Mod "Speed Rate")
-- ============================================================================
local function SpeedType(pn) return GetSpeedMode(pn) end

local function RealSpeedValue(pn)
	return GetRealSpeed(pn)
end

local SPEED = {
	Xmod      = { min = 0.25, max = 10,   step = 0.05 },
	RealSpeed = { min = 10,   max = 2000, step = 10 },
}

local function SpeedCurrent(pn)
	local t = SpeedType(pn)
	if t == "RealSpeed" then return RealSpeedValue(pn) end
	return GetMod(pn, "XMod") or 1
end

-- ============================================================================
-- APPEARANCE (Hidden / Sudden / Stealth) -> same file the gameplay reads
-- ============================================================================
-- HIDDEN / SUDDEN / HIDDEN+ / SUDDEN+ are not offered here (the lane cover will take them over in the
-- LANE tab). The gameplay side still understands them.
local AppearanceValues = { "Visible", "Constant", "Stealth" }

local function ProfileUID(pn)
	local pf = PROFILEMAN:GetProfile(pn)
	if pf then return pf:GetGUID() end
	return "UnknownPlayerUID"
end

-- ============================================================================
-- ROWS
-- ============================================================================
local R = {}
POMenu.Rows = R

-- ---------------------------------------------------------------- BASIC ----
-- Names and order as in the original DDR WORLD: "Real Speed" first, "Speed Rate" second.
-- Internally they are the theme's RealSpeed / Xmod modes.
R.SpeedType = ChoiceRow{
	title = "SCROLL SPEED",
	choices = { "Real Speed", "Speed Rate" },
	get = function(pn)
		local t = SpeedType(pn)
		if t == "Xmod" then return 2 end
		return 1   -- RealSpeed
	end,
	set = function(pn, idx)
		SetSpeedMode(pn, ({ "RealSpeed", "Xmod" })[idx])
	end,
	explain = function(pn, idx)
		return ({
			"Sets the scroll speed as a fixed value. The multiplier is set based on the Max BPM.",
			"Sets the scroll speed as a multiplier. The song BPM multiplied by this number is set as the speed.",
		})[idx]
	end,
}

R.SpeedValue = {
	-- With "Speed Rate" (X-Mod) the line is labelled MULTIPLIER; with the other types the label is empty.
	title = function(pn)
		if SpeedType(pn) == "Xmod" then return "MULTIPLIER" end
		return ""
	end,
	count = function(pn)
		local s = SPEED[SpeedType(pn)]
		return RangeCount(s.min, s.max, s.step)
	end,
	text = function(pn, idx)
		local t = SpeedType(pn)
		local s = SPEED[t]
		local v = RangeValue(s.min, s.step, idx)
		if t == "Xmod" then return string.format("x%.2f", v) end
		return tostring(math.floor(v + 0.5))
	end,
	get = function(pn)
		local s = SPEED[SpeedType(pn)]
		return RangeIndex(s.min, s.max, s.step, SpeedCurrent(pn))
	end,
	set = function(pn, idx)
		local t = SpeedType(pn)
		local s = SPEED[t]
		local v = RangeValue(s.min, s.step, idx)
		if t == "Xmod" then
			PO(pn):XMod(v)
		else
			v = math.floor(v + 0.5)
			SetRealSpeed(pn, v)
		end
	end,
	explain = function(pn, idx)
		if SpeedType(pn) == "Xmod" then return "Changes the scroll speed in increments of x0.05." end
		return "Changes the scroll speed in increments of 10."
	end,
}

-- Read-only line: the actual speed at the minimum / core / maximum BPM.
R.SpeedInfo = {
	kind = "info",
	follows = "SpeedValue",   -- the box lights up when that row is selected
	info = function(pn)
		local song = GAMESTATE:GetCurrentSong()
		local steps = GAMESTATE:GetCurrentSteps(pn)
		if not song or not steps then return nil end
		local b = GetChartBPMInfo(song, steps)
		if not b or not b.max or b.max <= 0 then return nil end

		local t = SpeedType(pn)
		local factor
		if t == "RealSpeed" then factor = SpeedCurrent(pn) / b.max else factor = SpeedCurrent(pn) end
		return {
			min  = math.floor(b.min * factor + 0.5),
			core = math.floor(b.max * factor + 0.5),
			max  = math.floor(b.max * factor + 0.5),
		}
	end,
}

-- FLARE level saved per player: 0 = none, 1..9 = I..IX, 10 = EX, 11 = FLOATING.
function POMenu.FlareLevel(pn)
	return tonumber(PrefGet("PO_FlareLevel_" .. PName(pn), "0")) or 0
end

-- Choice order, like the game: 1 NORMAL, 2 FLOATING FLARE, 3..12 FLARE I..EX, 13 LIFE4, 14 RISKY.
-- The FLARE level itself is stored as 0 = none, 1..10 = I..EX, 11 = FLOATING (see Scripts/08 FlareGauge.lua).
local GaugeChoices = { "NORMAL", "FLOATING FLARE" }
for i = 1, 10 do GaugeChoices[#GaugeChoices + 1] = FlareGauge.Names[i] end
GaugeChoices[#GaugeChoices + 1] = "LIFE4"
GaugeChoices[#GaugeChoices + 1] = "RISKY"

local function GaugeLevelFromIndex(idx)
	if idx == 2 then return 11 end
	if idx >= 3 and idx <= 12 then return idx - 2 end
	return 0
end

R.Gauge = ChoiceRow{
	title = "DANCE GAUGE",
	choices = GaugeChoices,
	get = function(pn)
		-- A saved FLARE wins (the engine may keep listing "1Lives" for a moment after a change).
		local fl = POMenu.FlareLevel(pn)
		if fl == 11 then return 2 end
		if fl > 0 then return 2 + fl end
		local arr = GAMESTATE:GetPlayerState(pn):GetPlayerOptionsArray("ModsLevel_Preferred")
		if table.search(arr, "4Lives") then return 13 end
		if table.search(arr, "1Lives") then return 14 end
		return 1
	end,
	set = function(pn, idx)
		-- In the extra stage NORMAL is not allowed: it becomes LIFE4 (RISKY in the second extra stage)
		if idx == 1 and (GAMESTATE:IsExtraStage() or GAMESTATE:IsExtraStage2()) then
			idx = GAMESTATE:IsExtraStage2() and 14 or 13
		end
		-- FLARE uses the engine's normal bar; FlareGauge controls how it drains.
		local mod = "bar,failimmediate"
		if idx == 13 then mod = "4 lives,battery,failimmediate"
		elseif idx == 14 then mod = "1 lives,battery,failimmediate" end
		GAMESTATE:ApplyPreferredModifiers(pn, mod)
		PrefSet("PO_FlareLevel_" .. PName(pn), GaugeLevelFromIndex(idx))
	end,
	explain = function(pn, idx)
		local lv = GaugeLevelFromIndex(idx)
		if lv > 0 then return FlareGauge.Explain(lv) end
		if idx == 13 then return "Battery gauge with 4 lives. Each miss costs a life." end
		if idx == 14 then return "Battery gauge with 1 life. A single miss ends the song." end
		return "Standard life bar. It drains when you miss and refills when you hit."
	end,
}

local TurnMods = { "Mirror", "Left", "Right", "Shuffle" }
R.Placement = ChoiceRow{
	title = "ARROW PLACEMENT",
	choices = { "NORMAL", "MIRROR", "LEFT", "RIGHT", "SHUFFLE" },
	get = function(pn)
		for i, m in ipairs(TurnMods) do
			if GetMod(pn, m) == true then return i + 1 end
		end
		return 1
	end,
	set = function(pn, idx)
		for i, m in ipairs(TurnMods) do SetBool(pn, m, (i + 1) == idx) end
	end,
	explain = "Rearranges where the arrows appear. SHUFFLE gives a random layout.",
}

-- --------------------------------------------------------------- ARROWS ----
R.Visibility = ChoiceRow{
	title = "ARROW VISIBILITY",
	choices = { "NORMAL", "CONSTANT", "STEALTH" },
	get = function(pn)
		local key = "AppearancePlusMenu_" .. PName(pn)
		local val = cache[key]
		if val == nil then
			val = ReadOrCreateAppearancePlusValueForPlayer(ProfileUID(pn), "Visible")
			cache[key] = val
		end
		for i, v in ipairs(AppearanceValues) do
			if v == val then return i end
		end
		-- A value saved earlier that this row no longer offers: back to NORMAL, so the menu does not show NORMAL
		-- while the game still applies the old option. A lane cover (HIDDEN+...) moves to LANE COVER SETTING.
		for i = 2, 4 do
			if val == ({ "", "Hidden+", "Sudden+", "Hidden+&Sudden+" })[i] then
				PrefSet("PO_LaneCoverMode_" .. PName(pn), i)
			end
		end
		cache[key] = "Visible"
		setenv("AppearancePlus" .. PName(pn), "Visible")
		SaveAppearancePlusValueForPlayer(ProfileUID(pn), "Visible")
		return 1
	end,
	set = function(pn, idx)
		local val = AppearanceValues[idx] or "Visible"
		cache["AppearancePlusMenu_" .. PName(pn)] = val
		setenv("AppearancePlus" .. PName(pn), val)
		SaveAppearancePlusValueForPlayer(ProfileUID(pn), val)
	end,
	explain = function(pn, idx)
		if AppearanceValues[idx] == "Constant" then
			return "Arrows only appear during the time set in ARROW DISPLAY TIME, whatever the scroll speed."
		end
		if AppearanceValues[idx] == "Stealth" then
			return "The arrows are not displayed."
		end
		return "The arrows are displayed normally."
	end,
}

-- Only shown while ARROW VISIBILITY is CONSTANT (see "visible" in options.lua).
R.DisplayTime = {
	title = "ARROW DISPLAY TIME",
	visible = function(pn) return AppearanceValues[R.Visibility.get(pn)] == "Constant" end,
	count = function() return RangeCount(ConstantVis.MinMs, ConstantVis.MaxMs, ConstantVis.StepMs) end,
	text = function(pn, idx) return string.format("%dms", RangeValue(ConstantVis.MinMs, ConstantVis.StepMs, idx)) end,
	get = function(pn)
		local ms = tonumber(PrefGet(ConstantVis.PrefName(pn), tostring(ConstantVis.DefaultMs))) or ConstantVis.DefaultMs
		return RangeIndex(ConstantVis.MinMs, ConstantVis.MaxMs, ConstantVis.StepMs, ms)
	end,
	set = function(pn, idx)
		PrefSet(ConstantVis.PrefName(pn), RangeValue(ConstantVis.MinMs, ConstantVis.StepMs, idx))
	end,
	explain = "How long the arrows stay visible before reaching the receptors. A shorter time hides more of the lane.",
}

-- ARROW DESIGN + ARROW COLORING
-- With the theme option NTOption = On both rows work on the SchneiderAFX noteskins, which are named
-- SCH-<DESIGN>-<COLORING> (e.g. SCH-CLASSIC-NOTE): DESIGN picks the shape, COLORING the colors, and
-- together they choose the noteskin. With NTOption = Off, ARROW DESIGN lists every installed noteskin
-- and the ARROW COLORING row is hidden.
local SchDesigns   = { "NORMAL", "X", "CLASSIC", "CYBER", "MEDIUM", "SMALL", "DOT" }
local SchColorings = { "NOTE", "RAINBOW", "VIVID", "FLAT" }   -- the SMNOTE noteskins are not offered
local SchColoringExplain = {
	RAINBOW = "Normal arrow. The arrows are colored according to the timing.",
	NOTE    = "The arrows are colored according to the timing. The color pattern is different from RAINBOW.",
	VIVID   = "The colors of the arrows change.",
	FLAT    = "The arrows are not separated by different colors.",
}

local function SchName(design, coloring) return "SCH-" .. design .. "-" .. coloring end

-- Only the designs and colorings that are really installed are offered.
local schList
local function Sch()
	if schList then return schList end
	schList = { designs = {}, colorings = {} }
	local hasColoring = {}
	for _, d in ipairs(SchDesigns) do
		local any = false
		for _, c in ipairs(SchColorings) do
			if NOTESKIN:DoesNoteSkinExist(SchName(d, c)) then any = true; hasColoring[c] = true end
		end
		if any then schList.designs[#schList.designs + 1] = d end
	end
	for _, c in ipairs(SchColorings) do
		if hasColoring[c] then schList.colorings[#schList.colorings + 1] = c end
	end
	return schList
end

local function UseSch()
	return ThemePrefs.Get("NTOption") == "On" and #Sch().designs > 0
end

-- Design and coloring of the noteskin the player has now (nil, nil if it is not a SCH one).
local function CurrentSch(pn)
	local cur = string.upper(tostring(GetMod(pn, "NoteSkin") or ""))
	return string.match(cur, "^SCH%-(%w+)%-(%w+)$")
end

local function IndexOf(list, value)
	for i, v in ipairs(list) do
		if v == value then return i end
	end
	return nil
end

local function ApplySch(pn, design, coloring)
	local name = SchName(design, coloring)
	if not NOTESKIN:DoesNoteSkinExist(name) then
		-- that combination is not installed: keep the design and take the first coloring it has
		for _, c in ipairs(Sch().colorings) do
			if NOTESKIN:DoesNoteSkinExist(SchName(design, c)) then name = SchName(design, c); break end
		end
	end
	pcall(function() PO(pn):NoteSkin(name) end)
end

R.Coloring = {
	title = "ARROW COLORING",
	visible = function(pn) return UseSch() end,
	count = function() return #Sch().colorings end,
	text = function(pn, idx) return Sch().colorings[idx] or "" end,
	get = function(pn)
		local _, c = CurrentSch(pn)
		return IndexOf(Sch().colorings, c) or IndexOf(Sch().colorings, "NOTE") or 1
	end,
	set = function(pn, idx)
		local d = CurrentSch(pn)
		ApplySch(pn, IndexOf(Sch().designs, d) and d or Sch().designs[1], Sch().colorings[idx])
	end,
	explain = function(pn, idx)
		return SchColoringExplain[Sch().colorings[idx] or ""] or ""
	end,
}

local function NoteSkinNames()
	local names = NOTESKIN:GetNoteSkinNames()
	if not names or #names == 0 then return { "default" } end
	return names
end

R.Design = {
	title = "ARROW DESIGN",
	count = function()
		if UseSch() then return #Sch().designs end
		return #NoteSkinNames()
	end,
	text = function(pn, idx)
		if UseSch() then return Sch().designs[idx] or "" end
		return string.upper(NoteSkinNames()[idx] or "")
	end,
	get = function(pn)
		if UseSch() then
			local d = CurrentSch(pn)
			return IndexOf(Sch().designs, d) or 1
		end
		local cur = string.lower(tostring(GetMod(pn, "NoteSkin") or ""))
		for i, n in ipairs(NoteSkinNames()) do
			if string.lower(n) == cur then return i end
		end
		return 1
	end,
	set = function(pn, idx)
		if UseSch() then
			local _, c = CurrentSch(pn)
			ApplySch(pn, Sch().designs[idx], IndexOf(Sch().colorings, c) and c or "NOTE")
			return
		end
		local n = NoteSkinNames()[idx]
		if n then pcall(function() PO(pn):NoteSkin(n) end) end
	end,
	explain = "Changes the look of the arrows (noteskin).",
}

R.ScrollDir = ChoiceRow{
	title = "SCROLL DIRECTION",
	choices = { "NORMAL", "REVERSE" },
	get = function(pn)
		if (GetMod(pn, "Reverse") or 0) > 0.5 then return 2 end
		return 1
	end,
	set = function(pn, idx) SetFloat(pn, "Reverse", idx == 2 and 1 or 0) end,
	explain = "NORMAL: arrows come from the bottom. REVERSE: arrows come from the top.",
}

local ActionMods = { "Boost", "Brake", "Wave" }
R.ScrollAction = ChoiceRow{
	title = "SCROLL ACTION",
	choices = { "NORMAL", "BOOST", "BRAKE", "WAVE" },
	get = function(pn)
		for i, m in ipairs(ActionMods) do
			if (GetMod(pn, m) or 0) > 0.5 then return i + 1 end
		end
		return 1
	end,
	set = function(pn, idx)
		for i, m in ipairs(ActionMods) do SetFloat(pn, m, (i + 1) == idx and 1 or 0) end
	end,
	explain = "BOOST: arrows start fast. BRAKE: arrows slow down near the receptors. WAVE: speed oscillates.",
}

-- ----------------------------------------------------------------- LANE ----
-- Shows (ON, the default) or hides the marker that tells in which lane the first arrow of the song will
-- appear. The marker itself is BGAnimations/ScreenGameplay decorations/FirstStep, which asks this function.
function POMenu.LanePreviewOn(pn)
	return POProfile.Get(pn, "LanePreview", "On") ~= "Off"
end

R.LanePreview = ChoiceRow{
	title = "ARROW START LANE PREVIEW",
	choices = { "ON", "OFF" },
	get = function(pn) return POMenu.LanePreviewOn(pn) and 1 or 2 end,
	set = function(pn, idx) POProfile.Set(pn, "LanePreview", idx == 1 and "On" or "Off") end,
	explain = "Shows in which lane the first arrow of the song will appear, before the song starts.",
}

-- Lane cover: a picture that covers part of the lane. It is independent of ARROW VISIBILITY. The gameplay side
-- (BGAnimations/ScreenGameplay decorations/Speed-Appearance) asks POMenu.LaneCoverMode.
local CoverModes = { false, "Hidden+", "Sudden+", "Hidden+&Sudden+" }   -- index = saved value; 1 = OFF

local function LaneCoverIndex(pn)
	local v = tonumber(PrefGet("PO_LaneCoverMode_" .. PName(pn), "1")) or 1
	return math.max(1, math.min(#CoverModes, v))
end

-- "Hidden+", "Sudden+", "Hidden+&Sudden+", or nil when there is no lane cover.
function POMenu.LaneCoverMode(pn)
	return CoverModes[LaneCoverIndex(pn)] or nil
end

R.LaneCover = ChoiceRow{
	title = "LANE COVER SETTING",
	choices = { "OFF", "HIDDEN+", "SUDDEN+", "HIDSUD+" },
	get = LaneCoverIndex,
	set = function(pn, idx) PrefSet("PO_LaneCoverMode_" .. PName(pn), idx) end,
	explain = function(pn, idx)
		return ({
			"No lane cover.",
			"A lane cover hides the arrows from the top of the screen.",
			"A lane cover hides the arrows from the bottom of the screen.",
			"Lane covers hide the arrows from both the top and the bottom of the screen.",
		})[idx]
	end,
}

R.LaneVisibility = {
	title = "LANE VISIBILITY",
	count = function() return 11 end,
	text = function(pn, idx) return string.format("%d%%", (idx - 1) * 10) end,
	get = function(pn)
		local v = tonumber(PrefGet("OptionRowScreenFilter" .. PName(pn), "0.3")) or 0.3
		return math.max(1, math.min(11, math.floor(v * 10 + 0.5) + 1))
	end,
	set = function(pn, idx)
		PrefSet("OptionRowScreenFilter" .. PName(pn), string.format("%.1f", (idx - 1) / 10))
	end,
	explain = "Darkens the area behind the lane so the arrows are easier to see.",
}

-- Por perfil. Sin valor guardado (perfil nuevo o invitado): Center.
function GuideLinesMode(pn)
	if GAMESTATE:IsDemonstration() then return "Center" end
	local v = POProfile.Get(pn, "GuideLines", "Center")
	if v == "Off" then return "Off" end
	if v == "Border" then return "Border" end
	return "Center"
end

function GuideLines(pn)
    return GuideLinesMode(pn) ~= "Off"
end

R.Guideline = ChoiceRow{
	title = "GUIDELINE SETTING",
	choices = { "CENTER", "BORDER", "OFF" },
	get = function(pn)
		local m = GuideLinesMode(pn)
		if m == "Border" then return 2 end
		if m == "Off" then return 3 end
		return 1
	end,
	set = function(pn, idx)
		POProfile.Set(pn, "GuideLines", ({ "Center", "Border", "Off" })[idx])
		POMenu.NeedsReload = true
	end,
	explain = function(pn, idx)
		return ({
			"Draws guide lines through the center of the steps to help you read the beats.",
			"Draws guide lines on the top edge of the steps to help you read the beats.",
			"No guide lines.",
		})[idx]
	end,
}

R.StepZone = ChoiceRow{
	title = "STEP ZONE",
	choices = { "ON", "OFF" },
	get = function(pn)
		if (GetMod(pn, "Dark") or 0) > 0.5 then return 2 end
		return 1
	end,
	set = function(pn, idx) SetFloat(pn, "Dark", idx == 2 and 1 or 0) end,
	explain = "Shows or hides the step zone (the receptors at the top or bottom).",
}

-- ---------------------------------------------------------------- JUDGE ----
function POMenu.FastSlowOn(pn)
	return POProfile.Get(pn, "FastSlow", "On") ~= "Off"
end

R.FastSlow = ChoiceRow{
	title = "FAST/SLOW DISPLAY",
	choices = { "OFF", "ON" },
	get = function(pn) return POMenu.FastSlowOn(pn) and 2 or 1 end,
	set = function(pn, idx) POProfile.Set(pn, "FastSlow", idx == 2 and "On" or "Off") end,
	explain = "Shows FAST or SLOW next to the judgment when you hit early or late.",
}

local function MsRow(def)
	-- def.pref = PREFSMAN preference name; def.min / def.max in milliseconds
	def.count = function() return def.max - def.min + 1 end
	def.text = function(pn, idx) return Signed(def.min + idx - 1, "ms") end
	def.get = function(pn)
		local ms = math.floor(PREFSMAN:GetPreference(def.pref) * 1000 + 0.5)
		return math.max(1, math.min(def.max - def.min + 1, ms - def.min + 1))
	end
	def.set = function(pn, idx)
		PREFSMAN:SetPreference(def.pref, (def.min + idx - 1) / 1000)
	end
	return def
end

R.DisplayTiming = MsRow{
	title = "DISPLAY TIMING", pref = "VisualDelaySeconds", min = -50, max = 50,
	explain = "Adjusts when the arrows are drawn. If the screen lags behind, decrease the value.",
}

R.JudgmentTiming = MsRow{
	title = "JUDGMENT TIMING", pref = "GlobalOffsetSeconds", min = -100, max = 100,
	explain = "Shifts when your steps are judged (machine-wide offset). Change it only if your hits feel early or late.",
}

-- LOW (por defecto): combo/juicio detrás de las flechas. HIGH: delante. Por perfil.
-- Las leen Graphics/Player combo, Graphics/Player judgment y BGAnimations/ScreenGameplay underlay.
function POMenu.ComboHigh(pn)
	return POProfile.Get(pn, "ComboPriority", "Low") == "High"
end

function POMenu.JudgmentHigh(pn)
	return POProfile.Get(pn, "JudgmentPriority", "Low") == "High"
end

R.ComboPriority = ChoiceRow{
	title = "COMBO DISPLAY PRIORITY",
	choices = { "LOW", "HIGH" },
	get = function(pn) return POMenu.ComboHigh(pn) and 2 or 1 end,
	set = function(pn, idx) POProfile.Set(pn, "ComboPriority", idx == 2 and "High" or "Low") end,
	explain = "LOW draws the combo behind the arrows. HIGH draws it in front.",
}

R.JudgmentPriority = ChoiceRow{
	title = "JUDGMENT DISPLAY PRIORITY",
	choices = { "LOW", "HIGH" },
	get = function(pn) return POMenu.JudgmentHigh(pn) and 2 or 1 end,
	set = function(pn, idx) POProfile.Set(pn, "JudgmentPriority", idx == 2 and "High" or "Low") end,
	explain = "LOW draws the judgment behind the arrows. HIGH draws it in front.",
}

-- Where the judgment (Marvelous!!!, Perfect!!...) is drawn: NEAR is the default layout (close to the receptors,
-- above the combo), FAR puts it farther from the receptors, under the combo. Graphics/Player judgment/default.lua
-- moves the judgment (and its FAST/SLOW) when this returns true (the key still says "Below").
function POMenu.JudgmentBelow(pn)
	return PrefGet("PO_JudgmentPos_" .. PName(pn), "1") == "2"
end

R.JudgmentPosition = ChoiceRow{
	title = "JUDGMENT DISPLAY POSITION",
	choices = { "NEAR", "FAR" },
	get = function(pn) return POMenu.JudgmentBelow(pn) and 2 or 1 end,
	set = function(pn, idx) PrefSet("PO_JudgmentPos_" .. PName(pn), idx) end,
	explain = function(pn, idx)
		if idx == 2 then return "The judgment is shown far from the receptors, below the combo." end
		return "The judgment is shown near the receptors, above the combo."
	end,
}

-- --------------------------------------------------------------- ASSIST ----
R.TimingCut = ChoiceRow{
	title = "TIMING CUT",
	choices = { "OFF", "ON" },
	get = function(pn) return GetMod(pn, "Little") == true and 2 or 1 end,
	set = function(pn, idx) SetBool(pn, "Little", idx == 2) end,
	explain = "Removes the off-beat arrows (only quarter-note beats remain).",
}

R.FreezeCut = ChoiceRow{
	title = "FREEZE ARROW CUT",
	choices = { "OFF", "ON" },
	get = function(pn) return GetMod(pn, "NoHolds") == true and 2 or 1 end,
	set = function(pn, idx) SetBool(pn, "NoHolds", idx == 2) end,
	explain = "Removes all freeze arrows.",
}

R.JumpCut = ChoiceRow{
	title = "JUMP CUT",
	choices = { "OFF", "ON" },
	get = function(pn) return GetMod(pn, "NoJumps") == true and 2 or 1 end,
	set = function(pn, idx) SetBool(pn, "NoJumps", idx == 2) end,
	explain = "Removes all jumps (steps that need two panels at once).",
}

R.AssistTick = ChoiceRow{
	title = "ASSIST TICK",
	choices = { "OFF", "CLAP", "METRONOME" },
	get = function(pn)
		if GetSongOpt("AssistClap") == true then return 2 end
		if GetSongOpt("AssistMetronome") == true then return 3 end
		return 1
	end,
	set = function(pn, idx)
		SetSongOpt("AssistClap", idx == 2)
		SetSongOpt("AssistMetronome", idx == 3)
	end,
	explain = function(pn, idx)
		return ({
			"No assist sound.",
			"Plays a clap sound each time a step arrives.",
			"Plays a metronome tick on every beat.",
		})[idx]
	end,
}

local RATE = { min = 0.5, max = 2.0, step = 0.05 }
R.Rate = {
	title = "MUSIC RATE",
	count = function() return RangeCount(RATE.min, RATE.max, RATE.step) end,
	text = function(pn, idx)
		return string.format("%.2fx", RangeValue(RATE.min, RATE.step, idx))
	end,
	get = function(pn)
		return RangeIndex(RATE.min, RATE.max, RATE.step, GetSongOpt("MusicRate") or 1)
	end,
	set = function(pn, idx)
		local v = math.floor(RangeValue(RATE.min, RATE.step, idx) * 100 + 0.5) / 100
		SetSongOpt("MusicRate", v)
	end,
	explain = "Changes the speed of the song. 1.00x is the normal speed.",
}

R.SaveScores = ChoiceRow{
	title = "SAVE SCORES",
	choices = { "ON", "OFF" },
	get = function(pn) return GetSongOpt("SaveScore") == false and 2 or 1 end,
	set = function(pn, idx) SetSongOpt("SaveScore", idx == 1) end,
	explain = "ON saves your score. OFF plays without saving the score.",
}

-- ============================================================================
-- EXPLANATION IMAGES: which PNG each option value shows in the box at the bottom of the menu
-- ============================================================================
-- row.image(pn, idx) returns the path of the PNG under BGAnimations/ScreenPlayerOptions overlay/textures/explanation/
-- without the " 1x3.png" end (the 3 languages are stacked in each PNG). When it returns nil, or the PNG does not exist,
-- the box shows the row's 'explain' text instead.
local function Img(folder, names)
	return function(pn, idx)
		local n = names[idx]
		return n and (folder .. "/explanation_" .. n) or nil
	end
end
local function ImgOne(folder, name)
	return function() return folder .. "/explanation_" .. name end
end

-- BASIC

R.SpeedType.image = Img("Basic/Scroll Speed", { "real_speed", "speed_rate" })
-- second line: MULTIPLIER (Speed Rate) uses "highspeed"; the line of Real Speed uses "scroll_speed"
R.SpeedValue.image = function(pn, idx)
	local t = SpeedType(pn)
	if t == "Xmod" then return "Basic/Scroll Speed/explanation_highspeed" end
	if t == "RealSpeed" then return "Basic/Scroll Speed/explanation_scroll_speed" end
	return nil
end
R.Gauge.image = function(pn, idx)
	local f = "Basic/Dance Gauge/explanation_gauge_"
	if idx == 1 then return f .. "normal" end
	if idx == 2 then return f .. "flare_floating" end
	if idx >= 3 and idx <= 11 then return f .. "flare_" .. (idx - 2) end   -- FLARE I..IX
	if idx == 12 then return f .. "flare_ex" end
	if idx == 13 then return f .. "life4" end
	if idx == 14 then return f .. "risky" end
	return nil
end
R.Placement.image = Img("Basic/Arrow Placement",
	{ "arrangement_normal", "arrangement_mirror", "arrangement_left", "arrangement_right", "arrangement_shuffle" })

-- ARROWS
R.Visibility.image = Img("Arrows/Arrow Visibility", { "appearance_normal", "appearance_constant", "appearance_stealth" })
R.DisplayTime.image = ImgOne("Arrows/Arrow Visibility", "appearance_constant")
R.Coloring.image = function(pn, idx)
	local c = Sch().colorings[idx]
	return c and ("Arrows/Arrow Coloring/explanation_color_" .. string.lower(c)) or nil
end
R.Design.image = function(pn, idx)
	if not UseSch() then return nil end   -- the plain noteskin list has no image
	local d = Sch().designs[idx]
	return d and ("Arrows/Arrow Design/explanation_design_" .. string.lower(d)) or nil
end
R.ScrollDir.image = Img("Arrows/Scroll Direction", { "direction_normal", "direction_reverse" })
R.ScrollAction.image = Img("Arrows/Scroll Action", { "move_normal", "move_boost", "move_brake", "move_wave" })

-- LANE
R.LanePreview.image = Img("Lane/Arrow start lane preview", { "arrow_notice_on", "arrow_notice_off" })
R.LaneCover.image = Img("Lane/Lane cover setting",
	{ "lanecover_off", "lanecover_hidden", "lanecover_sudden", "lanecover_hidden_sudden" })
R.LaneVisibility.image = ImgOne("Lane/Lane visibility", "lane_visibility")
R.Guideline.image = Img("Lane/Guideline Setting", { "guideline_center", "guideline_border", "guideline_off" })
R.StepZone.image = Img("Lane/Step zone", { "stepzone_on", "stepzone_off" })

-- JUDGE
R.FastSlow.image = Img("Judge/Fast-slow display", { "fasl_off", "fasl_on" })
R.DisplayTiming.image = ImgOne("Judge/Display timing", "display")
R.JudgmentTiming.image = ImgOne("Judge/Judgment timing", "judge_timing")
R.ComboPriority.image = Img("Judge/Combo display priority", { "combo_priority_low", "combo_priority_high" })
R.JudgmentPriority.image = Img("Judge/Judgment display priority", { "judge_priority_low", "judge_priority_high" })
R.JudgmentPosition.image = Img("Judge/Judgment display position", { "judge_position_near", "judge_position_far" })

-- ASSIST
R.TimingCut.image = Img("Assist/Timing cut", { "timing_off", "timing_on1" })
R.FreezeCut.image = Img("Assist/Freeze arrow cut", { "freeze_off", "freeze_on" })
R.JumpCut.image = Img("Assist/Jump cut", { "jump_off", "jump_on" })
-- ============================================================================
-- TITLE IMAGES: the name of each option (left column of the menu) is a PNG with the 3 languages stacked (1x3), in
-- textures/explanation/<tab>/<name> 1x3.png. 'titleImage' is the path without the " 1x3.png" end (or a function
-- returning it, or nil). Without a PNG the row's 'title' text is written instead.
-- ============================================================================
R.SpeedType.titleImage      = "Basic/scroll_speed_title"
-- the second line is labelled MULTIPLIER only with Speed Rate; with the other speed types it has no label
R.SpeedValue.titleImage     = function(pn) if SpeedType(pn) == "Xmod" then return "Basic/multiplier_title" end return nil end
R.Gauge.titleImage          = "Basic/dance_gauge_title"
R.Placement.titleImage      = "Basic/arrow_placement_title"

R.Visibility.titleImage     = "Arrows/arrow_visibility_title"
R.DisplayTime.titleImage    = "Arrows/arrow_display_time_title"
R.Coloring.titleImage       = "Arrows/arrow_coloring_title"
R.Design.titleImage         = "Arrows/arrow_design_title"
R.ScrollDir.titleImage      = "Arrows/scroll_direction_title"
R.ScrollAction.titleImage   = "Arrows/scroll_action_title"

R.LanePreview.titleImage    = "Lane/arrow_start_lane_preview_title"
R.LaneCover.titleImage      = "Lane/lane_cover_setting_title"
R.LaneVisibility.titleImage = "Lane/lane_visibility_title"
R.Guideline.titleImage      = "Lane/guideline_setting_title"
R.StepZone.titleImage       = "Lane/step_zone_title"

R.FastSlow.titleImage         = "Judge/fast_slow_display_title"
R.DisplayTiming.titleImage    = "Judge/display_timing_title"
R.JudgmentTiming.titleImage   = "Judge/judgment_timing_title"
R.ComboPriority.titleImage    = "Judge/combo_display_priority_title"
R.JudgmentPriority.titleImage = "Judge/judgment_display_priority_title"
R.JudgmentPosition.titleImage = "Judge/judgment_display_position_title"

R.TimingCut.titleImage  = "Assist/timing_cut_title"
R.FreezeCut.titleImage  = "Assist/freeze_arrow_cut_title"
R.JumpCut.titleImage    = "Assist/jump_cut_title"
-- ============================================================================
-- TABS: order and rows of each one
-- ============================================================================
POMenu.Tabs = {
	{ id = "basic",  title = "Basic",  rows = { "SpeedType", "SpeedValue", "SpeedInfo", "Gauge", "Placement" } },
	{ id = "arrows", title = "Arrows", rows = { "Visibility", "DisplayTime", "Coloring", "Design", "ScrollDir", "ScrollAction" } },
	{ id = "lane",   title = "Lane",   rows = { "LanePreview", "LaneCover", "LaneVisibility", "Guideline", "StepZone" } },
	{ id = "judge",  title = "Judge",  rows = { "FastSlow", "DisplayTiming", "JudgmentTiming", "ComboPriority", "JudgmentPriority", "JudgmentPosition" } },
	{ id = "assist", title = "Assist", rows = { "TimingCut", "FreezeCut", "JumpCut", "AssistTick", "Rate", "SaveScores" } },
	{ id = "back",   title = "Back",   rows = {} },
}

POMenu.MaxRows = 6

-- ============================================================================
-- Placeholder row for the engine: ScreenPlayerOptions needs at least one line, but the real menu is
-- drawn and driven by options.lua. This line does nothing.
-- ============================================================================
function OptionRowPOMenuDummy()
	local t = {
		Name = "POMenuDummy",
		LayoutType = "ShowAllInRow",
		SelectType = "SelectOne",
		OneChoiceForAllPlayers = false,
		ExportOnChange = false,
		Choices = { "-" },
		LoadSelections = function(self, list, pn) list[1] = true end,
		SaveSelections = function(self, list, pn) end,
	}
	setmetatable(t, t)
	return t
end
