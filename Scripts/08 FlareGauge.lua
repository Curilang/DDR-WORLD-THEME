-- ============================================================================
-- FLARE GAUGE (inspired by DDR)
-- Adds 11 options to "DANCE GAUGE": FLARE I..IX, FLARE EX and FLOATING FLARE.
--
-- Gauge model:
--   * The gauge starts at 100 % and NEVER recovers.
--   * Every judgment subtracts a FIXED amount that depends only on the judgment and on the
--     FLARE level. It does not depend on the number of steps of the chart.
--       MARVELOUS / O.K.      0
--       PERFECT               -1 % at FLARE EX only
--       GREAT                 -0.10 % (I..III) ... -2 % (IX, EX)
--       GOOD                  -0.50 % (I) ... -10 % (IX, EX)
--       MISS / N.G.           -1.50 % (I) ... -30 % (IX, EX)
--   * When the gauge reaches 0 the FLARE is lost and the song fails.
--   * FLOATING starts at EX. After every judgment the total is recomputed from the counters;
--     if it would be 0 or less, the level drops to the highest one that is still alive (down
--     to FLARE I) and the gauge becomes exactly what that level would have had. It does not
--     refill.
-- ("Flare Skill", the points system, is not implemented here.)
--
-- Related files:
--   Scripts/08 FlareGaugeClears.lua  best FLARE per chart (music wheel and difficulty list)
--   Scripts/08 PlayerOptionsRows.lua the DANCE GAUGE choices in the options menu
--   BGAnimations/ScreenGameplay overlay/default.lua  feeds the judgments and mirrors the gauge
-- ============================================================================

FlareGauge = {}

FlareGauge.Roman = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "EX", "FLOATING" }
FlareGauge.Names = {}
for i, r in ipairs(FlareGauge.Roman) do
	FlareGauge.Names[i] = (i == 11) and "FLOATING FLARE" or ("FLARE " .. r)
end

-- The gauge is kept in hundredths of a percent, like the arcade: 10000 = 100.00 %.
FlareGauge.Full = 10000

-- Level factor f(level) of the arcade formulas (levels 1..10).
FlareGauge.LevelFactor = { 0, 0, 0, 5, 30, 40, 60, 80, 100, 100 }

-- Judgment indices, same numbering as the arcade events:
--   0 MARVELOUS, 1 PERFECT, 2 GREAT, 3 GOOD, 4 miss with timing, 5 MISS, 6 O.K., 7 N.G.
FlareGauge.JudgeIndex = {
	TapNoteScore_W1 = 0, TapNoteScore_W2 = 1, TapNoteScore_W3 = 2, TapNoteScore_W4 = 3,
	TapNoteScore_W5 = 4, TapNoteScore_Miss = 5,
	TapNoteScore_AvoidMine = 6,  -- an avoided shock arrow is an O.K.
	TapNoteScore_HitMine = 7,    -- a stepped shock arrow is an N.G.
	HoldNoteScore_Held = 6, HoldNoteScore_LetGo = 7,
}

-- Penalty (<= 0, hundredths of a percent) of one judgment at one FLARE level (1..10).
function FlareGauge.Penalty(level, j)
	local f = FlareGauge.LevelFactor[level] or 100
	if j == 1 then
		return (level == 10) and -100 or 0
	elseif j == 2 then
		return -20 - math.floor(180 * f / 100) + ((level <= 3) and 10 or 0)
	elseif j == 3 then
		return -100 - math.floor(900 * f / 100) + (({ 50, 37, 25 })[level] or 0)
	elseif j == 4 or j == 5 or j == 7 then
		return -1000 - math.floor(2000 * f / 100) + (({ 850, 700, 550 })[level] or 0)
	end
	return 0   -- MARVELOUS and O.K.
end

-- Gauge a player would have at "level" after the judgments counted in "count" (hundredths of %).
local function TotalFor(count, level)
	local total = FlareGauge.Full
	for j = 0, 7 do
		local n = count[j] or 0
		if n > 0 then total = total + n * FlareGauge.Penalty(level, j) end
	end
	return total
end

-- Fallback tint per level, used when there is no flare_N texture yet.
FlareGauge.Colors = {
	"#6aa8ff", "#5a8cff", "#4d6df0", "#3fd0e0", "#4be08a",
	"#b6e04b", "#ffd23f", "#ff9a3f", "#ff6a3f", "#ffffff",
}

-- The bar switches to its danger texture below this value (0..1). In FLOATING only at FLARE I.
FlareGauge.DangerAt = 0.25

-- Effect layer (flare_N_ef), measured from arcade footage: it scrolls to the right at about 600 px/s,
-- roughly 1.45 texture widths per second (negative = right), while the base layer stays still.
-- Additive blending gives it the glow of the original; try "BlendMode_Normal" if it looks too white.
FlareGauge.EffectVelocity = -1.45
FlareGauge.EffectBlend = "BlendMode_Add"

-- The edge of the bar bounces when the gauge drops: amplitude (fraction of the bar width), seconds per
-- swing, and number of swings. count = 0 turns it off.
FlareGauge.Bounce = { amp = 0.03, period = 0.07, count = 3 }

-- FLOATING level change (measured from arcade footage): the old bar empties in about 0.14 s, then the
-- new level's bar grows from zero to its value in about 0.14 s.
FlareGauge.Refill = { collapse = 0.14, fill = 0.14 }

-- Results screen: FLARE texture next to the Grade, offset from the Grade's center (screen pixels) and zoom.
FlareGauge.ResultOffset = { x = 65, y = -48 }
FlareGauge.ResultZoom = 0.667

-- [pn] = { level (1..10 in use), gauge (0..1), cp (hundredths of %), count[0..7], floating, failed, danger }
FlareGauge.State = {}

-- ---------------------------------------------------------------------------
-- Textures
-- ---------------------------------------------------------------------------

-- Absolute path of a file inside the theme, or nil if it does not exist.
-- Textures are loaded by exact path on purpose: GetPathG/GetPathB match by prefix, so asking for
-- "flare_1" would also match "flare_10.png" and ThemeManager raises "more than one theme element".
-- The answer is remembered: the music wheel asks for the same few files for every item at every move.
local themeFileCache = {}
function FlareGauge.ThemeFile(rel)
	local cached = themeFileCache[rel]
	if cached ~= nil then return cached or nil end
	local dir = THEME:GetCurrentThemeDirectory()
	if dir:sub(1, 1) ~= "/" then dir = "/" .. dir end
	local full = dir .. rel
	if FILEMAN:DoesFileExist(full) then
		themeFileCache[rel] = full
		return full
	end
	themeFileCache[rel] = false
	return nil
end

-- Life bar textures, in BGAnimations/ScreenGameplay decorations/lifeframe/stream/:
--   flare_N (stretch).png          base of level N (1..10)
--   flare_N_ef (stretch).png       effect layer of level N
--   flare_danger (stretch).png     danger base, shared by every level
--   flare_danger_ef (stretch).png  danger effect, shared by every level
-- A level can override the shared danger texture with flare_N_danger (stretch).png.
local function StreamFile(name)
	local rel = "BGAnimations/ScreenGameplay decorations/lifeframe/stream/" .. name
	return FlareGauge.ThemeFile(rel .. " (stretch).png") or FlareGauge.ThemeFile(rel .. ".png")
end

function FlareGauge.StreamTex(level, suffix)
	suffix = suffix or ""
	local f = StreamFile("flare_" .. level .. suffix)
	if not f and suffix:sub(1, 7) == "_danger" then f = StreamFile("flare" .. suffix) end
	return f
end

-- Icon for the OPTIONS grid in gameplay: Graphics/OptionIcon/Flare/flare_N.png.
-- Without the PNG a colored square with the roman numeral is drawn. It uses the same slot as
-- LIFE4 / RISKY, and in FLOATING it changes by itself when the level drops.
function FlareGauge.IconActor(pn)
	local function Apply(self, level)
		local square, label, sprite = self:GetChild("Q"), self:GetChild("T"), self:GetChild("S")
		self:visible(level ~= nil)
		if not level then return end
		local f = FlareGauge.ThemeFile("Graphics/OptionIcon/Flare/flare_" .. level .. ".png")
		square:visible(not f):diffuse(color(FlareGauge.Colors[level]))
		label:visible(not f):settext(FlareGauge.Roman[level])
		sprite:visible(f ~= nil)
		if f then sprite:Load(f) end
	end
	return Def.ActorFrame{
		InitCommand = function(s) s:xy(-15, -36); Apply(s, FlareGauge.StartLevel(pn)) end,
		PlayerJoinedMessageCommand = function(s, p) if p.Player == pn then Apply(s, FlareGauge.StartLevel(pn)) end end,
		FlareLevelChangedMessageCommand = function(s, p) if p.Player == pn then Apply(s, p.Level) end end,
		Def.Quad{ Name = "Q", InitCommand = function(s) s:setsize(24, 24):diffusealpha(0.9) end },
		Def.BitmapText{ Name = "T", Font = "_swis721 blk bt 28px",
			InitCommand = function(s) s:zoom(0.45):diffuse(color("#101010")):maxwidth(48) end },
		Def.Sprite{ Name = "S", InitCommand = function(s) s:visible(false) end },
	}
end

-- Results screen texture, drawn at the top right of the Grade: Graphics/Grade/Flare/flare_N.png.
function FlareGauge.ResultFile(level)
	return FlareGauge.ThemeFile("Graphics/Grade/Flare/flare_" .. level .. ".png")
end

-- ---------------------------------------------------------------------------
-- Options menu text
-- ---------------------------------------------------------------------------

-- Penalty of one judgment as a percentage string, e.g. "-1.5%".
local function Pct(level, j)
	local v = -FlareGauge.Penalty(level, j) / 100
	if v == math.floor(v) then return string.format("-%d%%", v) end
	local s = string.format("%.2f", v)
	s = s:gsub("0+$", "")   -- 0.50 -> 0.5, 1.45 stays
	return "-" .. s .. "%"
end

-- Text for the explanation box of the options menu.
function FlareGauge.Explain(level)
	if level == 11 then
		return "Starts at FLARE EX. When the gauge runs out, it drops to the next lower FLARE rank, down to FLARE I. Your final rank is the one you finish with."
	end
	local s = "This option prevents recovery of the dance gauge. Every mistake takes a fixed amount off the gauge."
	if level == 10 then
		s = "This option for very advanced players prevents recovery of the dance gauge and causes the dance gauge to decrease with a rating of PERFECT or lower."
	end
	local parts = {}
	if level == 10 then parts[#parts + 1] = "PERFECT " .. Pct(level, 1) end
	parts[#parts + 1] = "GREAT " .. Pct(level, 2)
	parts[#parts + 1] = "GOOD " .. Pct(level, 3)
	parts[#parts + 1] = "MISS " .. Pct(level, 5)
	local misses = math.ceil(FlareGauge.Full / -FlareGauge.Penalty(level, 5))
	return s .. "\n\n" .. table.concat(parts, "   ") .. "\nThe gauge runs out on MISS #" .. misses .. "."
end

-- ---------------------------------------------------------------------------
-- Gameplay logic
-- ---------------------------------------------------------------------------

-- Returns the chosen FLARE (1..11) if this player is using one right now, false otherwise.
-- Not used in courses or with battery lives.
function FlareGauge.Active(pn)
	if GAMESTATE:IsCourseMode() then return false end
	-- the demonstration is not played by anyone: it must not show the FLARE the player has chosen
	if GAMESTATE:IsDemonstration() then return false end
	if not (POMenu and POMenu.FlareLevel) then return false end
	local lv = POMenu.FlareLevel(pn)
	if lv <= 0 then return false end
	local life = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred"):LifeSetting()
	if life == "LifeType_Battery" then return false end
	return lv
end

-- Level (1..10) the song starts with, or nil if the player is not using FLARE.
-- Handy for drawing before FlareGauge.State exists.
function FlareGauge.StartLevel(pn)
	local lv = FlareGauge.Active(pn)
	if not lv then return nil end
	return (lv == 11) and 10 or lv
end

-- Starts tracking at the beginning of a song. Returns the new state, or nil without FLARE.
function FlareGauge.Init(pn)
	local lv = FlareGauge.Active(pn)
	if not lv then
		FlareGauge.State[pn] = nil
		return nil
	end
	FlareGauge.State[pn] = {
		level    = (lv == 11) and 10 or lv,   -- level in use (FLOATING starts at EX)
		floating = (lv == 11),
		count    = { [0] = 0, 0, 0, 0, 0, 0, 0, 0 },   -- judgments seen, by index 0..7
		cp       = FlareGauge.Full,            -- gauge in hundredths of a percent
		gauge    = 1.0,
		danger   = false,
		failed   = false,
	}
	return FlareGauge.State[pn]
end

-- The FLARE earned in the song (1..10), or nil if the player did not use FLARE or lost it.
function FlareGauge.AchievedLevel(pn)
	local st = FlareGauge.State[pn]
	if not st or st.failed then return nil end
	return st.level
end

-- Applies one judgment. Returns true if the gauge or the level changed.
function FlareGauge.Judge(pn, tns, hns)
	local st = FlareGauge.State[pn]
	if not st or st.failed then return false end
	-- A hold judgment carries HoldNoteScore (its TapNoteScore is the head's); taps only carry TapNoteScore.
	local j = FlareGauge.JudgeIndex[hns]
	if j == nil then j = FlareGauge.JudgeIndex[tns] end
	if j == nil then return false end
	st.count[j] = st.count[j] + 1

	local cp
	if st.floating then
		-- FLOATING: the gauge is always "what this level would have had with every judgment so far".
		cp = TotalFor(st.count, st.level)
		if cp <= 0 and st.level > 1 then
			local newLevel = 1   -- the arcade ends at FLARE I even when not even that level survives
			for n = st.level - 1, 1, -1 do
				local t = TotalFor(st.count, n)
				if t > 0 then
					newLevel = n
					cp = t
					break
				end
			end
			st.level = newLevel
			MESSAGEMAN:Broadcast("FlareLevelChanged", { Player = pn, Level = st.level })
		end
	else
		cp = st.cp + FlareGauge.Penalty(st.level, j)
	end
	if cp == st.cp then return false end   -- MARVELOUS, O.K., PERFECT below EX

	if cp <= 0 then
		cp = 0
		st.failed = true
	elseif cp > FlareGauge.Full then
		cp = FlareGauge.Full
	end
	st.cp = cp
	st.gauge = cp / FlareGauge.Full
	MESSAGEMAN:Broadcast("FlareGaugeChanged", { Player = pn, Gauge = st.gauge })

	-- Danger: the bar is about to run out. In FLOATING it only counts at FLARE I, like the arcade.
	local danger = st.gauge <= FlareGauge.DangerAt and (not st.floating or st.level == 1)
	if danger ~= st.danger then
		st.danger = danger
		MESSAGEMAN:Broadcast("FlareDangerChanged", { Player = pn, Danger = danger })
	end
	return true
end
