-- ============================================================================
-- CONSTANT arrow visibility (DDR WORLD "Constant" option)
-- ============================================================================
-- The arrows are only visible during the last N milliseconds before they reach the receptors,
-- whatever the scroll speed is. In other words the visible distance is   time * scroll speed.
--
-- Two ways to do it (ConstantVis.Native() decides):
--   * Engine with the "Constant Modifier" patch (PlayerOptions:Constant / ConstantTime): the theme only switches the
--     native modifier on and gives it the time.
--   * Stock ITGmania/StepMania (fallback): it is built from SUDDEN: every frame the SuddenOffset is moved to
--     the distance that matches the chosen time at the CURRENT speed (so BPM changes keep working).
--
-- Where it is used:
--   Scripts/08 PlayerOptionsRows.lua   "CONSTANT" in ARROW VISIBILITY and the ARROW DISPLAY TIME row
--   BGAnimations/ScreenGameplay overlay/default.lua   adds ConstantVis.Actor(pn)
--   BGAnimations/ScreenGameplay decorations/Speed-Appearance/default.lua   clears the other engine mods
-- ============================================================================

ConstantVis = {
	-- Same range and step as the native engine modifier (the engine accepts 100ms to 3000ms, any value in
	-- between; its own options row goes in steps of 10ms). Both ways (native and fallback) use these numbers.
	MinMs     = 100,
	MaxMs     = 3000,
	StepMs    = 10,
	DefaultMs = 1000,

	-- Calibration of the engine's Sudden line (arrow-space units, 64 = one beat at 1x):
	--   arrows are fully visible up to   Base + PerOffset * SuddenOffset   and then fade out.
	-- Measured in game: the fade started at ~195 units for SuddenOffset ~ 0 (so Base ~ 192), and at
	-- SPEED 274 (target 292) the arrows were still opaque beyond 350, so one offset step is more than
	-- 40 units. 64 (one arrow) is the working estimate.
	-- If the arrows still start to fade too close/far, change these two numbers.
	Base      = 192,
	PerOffset = 64,

	-- In the original the arrows are fully visible for the chosen time and then fade out slowly over about
	-- 190 more units (half visible ~95 units later). The engine's fade is much shorter (~55 units), so its
	-- start is moved out by this amount: both reach "half visible" at about the same distance. Without it,
	-- at slow speeds (SPEED 68: only 72 units) almost nothing is seen before the arrows reach the receptors.
	-- (A speed-dependent shift that copied the native modifier's 0.25 s fade was tried on 2026-11-09 and was too
	-- aggressive: too few arrows were visible. This fixed value is the one that worked well.)
	FadeShift = 65,

	-- EXACT GEOMETRY of the engine's Sudden (ArrowEffects.cpp, ArrowGetPercentVisible / GetSudden*Line), used when
	-- UseEngineGeometry is true (the Base / PerOffset / FadeShift estimate above is then not used):
	--   C = 160 (the center line; 160 / (1 - Mini/2) with Mini), O = SuddenOffset
	--   from C + 40 + C*O  : the white silhouette starts (glow grows, the arrow itself is still invisible)
	--   at   C + 20 + C*O  : the arrow appears (the alpha is all or nothing, cut at 50 %), white at its strongest
	--   at   C + C*O       : the white is gone, the arrow is normal
	-- So the "white effect" lasts 40 units: 20 as a silhouette and 20 over the arrow.
	-- The native modifier fades the arrows in over 0.2 s centered on the chosen time: invisible at T + 0.1 s, half at T,
	-- opaque at T - 0.1 s. Here the end of the white (arrow normal) is put at the native half point (T) plus EndShift,
	-- which compensates the white: the arrow is already clean where the native one is half visible, and the
	-- silhouette / arrow appear 40 / 20 units earlier, close to where the native fade starts (0.1 s = 20..50 units
	-- at usual speeds). EndShift (units) moves everything out (+) or in (-).
	UseEngineGeometry = true,
	EndShift          = 0,
}

local function ProfileUID(pn)
	local pf = PROFILEMAN:GetProfile(pn)
	if pf then return pf:GetGUID() end
	return "UnknownPlayerUID"
end

function ConstantVis.PrefName(pn)
	return "PO_ConstantTime_" .. ToEnumShortString(pn)
end

-- Chosen display time in milliseconds.
function ConstantVis.Time(pn)
	local name = ConstantVis.PrefName(pn)
	local path = "/Save/UserPrefs/" .. THEME:GetThemeDisplayName() .. "/" .. name .. ".cfg"
	local v
	if FILEMAN:DoesFileExist(path) then v = ReadPrefFromFile(name) end
	v = tonumber(v) or ConstantVis.DefaultMs
	return math.max(ConstantVis.MinMs, math.min(ConstantVis.MaxMs, v))
end

-- True when the player chose CONSTANT in ARROW VISIBILITY.
function ConstantVis.Active(pn)
	return ReadOrCreateAppearancePlusValueForPlayer(ProfileUID(pn), "Visible") == "Constant"
end

-- Scroll speed in BPM as the player sees it (the same number the SPEED box shows).
local function SpeedBpm(ps, po)
	local pos = ps:GetSongPosition()
	if pos:GetFreeze() or pos:GetDelay() then return nil end
	return pos:GetCurBPS() * 60 * po:ScrollSpeed()
end

local function ApplyOffset(ps, off)
	for _, level in ipairs({ "ModsLevel_Song", "ModsLevel_Current" }) do
		local po = ps:GetPlayerOptions(level)
		po:Sudden(1, 1000)
		po:SuddenOffset(off, 1000)
	end
end

-- True when the engine has the native "Constant" appearance modifier (PlayerOptions:Constant() and
-- PlayerOptions:ConstantTime(), from the "Constant Modifier" engine patch). Stock ITGmania/StepMania do not have it.
-- Only a positive answer is cached: the player states may not exist yet when the scripts load.
function ConstantVis.Native()
	if ConstantVis.NativeCache ~= nil then return ConstantVis.NativeCache end
	local ok, res = pcall(function()
		local pn = GAMESTATE:GetMasterPlayerNumber()
		local ps = pn and GAMESTATE:GetPlayerState(pn)
		if not ps then return nil end
		local po = ps:GetPlayerOptions("ModsLevel_Preferred")
		return type(po.Constant) == "function" and type(po.ConstantTime) == "function"
	end)
	if not ok or res == nil then return false end
	if res then ConstantVis.NativeCache = true end
	return res
end

-- Native version: the engine decides the visibility of every note by itself (per note, from the real time left until it
-- must be hit, with a plain transparency fade), so the theme only has to switch it on and give it the chosen time.
local function NativeActor(ps, ms)
	local function Apply()
		for _, level in ipairs({ "ModsLevel_Song", "ModsLevel_Current" }) do
			local po = ps:GetPlayerOptions(level)
			po:Constant(1, 1000)
			po:ConstantTime(ms / 1000, 1000)
		end
	end

	-- Checked every frame (a single comparison) because a new stage or a mods reset would switch it off.
	local function Update()
		local po = ps:GetPlayerOptions("ModsLevel_Current")
		if po:Constant() < 1 then Apply() end
	end

	return Def.ActorFrame{
		InitCommand=function(self) Apply(); self:SetUpdateFunction(Update) end,
		OnCommand=function(self) Apply() end,
	}
end

-- Actor that makes CONSTANT work. Returns nil when the player did not choose CONSTANT.
-- With the native engine modifier it just turns it on; without it (stock ITGmania) it falls back to the Sudden-based
-- version below, which keeps the Sudden line in place.
function ConstantVis.Actor(pn)
	if not ConstantVis.Active(pn) then return nil end
	local ps = GAMESTATE:GetPlayerState(pn)
	local ms = ConstantVis.Time(pn)
	if ConstantVis.Native() then return NativeActor(ps, ms) end
	local last

	local function Update()
		local po = ps:GetPlayerOptions("ModsLevel_Current")
		local bpm = SpeedBpm(ps, po)
		if not bpm or bpm <= 0 then return end   -- stops/delays: the arrows are not moving, keep the line
		-- The speed is per song-second; with a music rate the arrows cover that distance faster.
		local so = GAMESTATE:GetSongOptionsObject("ModsLevel_Current")
		local rate = so and so:MusicRate() or 1
		local off
		if ConstantVis.UseEngineGeometry then
			-- end of the white = the native half point (see EndShift above)
			local mini = 0
			pcall(function() mini = po:Mini() or 0 end)
			local center = 160 / math.max(0.1, 1 - mini * 0.5)
			local endLine = ms / 1000 * bpm / 60 * 64 * rate + ConstantVis.EndShift
			off = endLine / center - 1
		else
			local dist = ms / 1000 * bpm / 60 * 64 * rate + ConstantVis.FadeShift
			off = (dist - ConstantVis.Base) / ConstantVis.PerOffset
		end
		if not last or math.abs(off - last) > 0.01 then
			ApplyOffset(ps, off)
			last = off
		end
	end

	return Def.ActorFrame{
		InitCommand=function(self) self:SetUpdateFunction(Update) end,
	}
end
