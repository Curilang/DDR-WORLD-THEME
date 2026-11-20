-- ============================================================================
-- TIMING: the judgment windows of the game (Arcade timing, inspired by DDR)
-- ============================================================================
-- Two versions, chosen automatically (ArcadeTiming.Native()):
--   ArcadeNative  engines that have the independent Miss window and the shock arrow judging (preferences
--                 TimingWindowSecondsMiss / ShockEarly / ShockLate, turned on by the [Player] metrics
--                 IndependentMissWindow and ShockArrowJudgment in metrics.ini)
--   Arcade        fallback for every other StepMania / ITGmania build (the timing used before)
-- The StepMania profile is only kept as the reference of the stock values.
-- They are engine preferences: they are set when a song starts (BGAnimations/ScreenGameplay overlay) and stay in
-- Preferences.ini, so other themes will use the last ones set until they are changed again.
-- ============================================================================

ArcadeTiming = {}

local PROFILES = {
	-- Every window is checked with |offset| <= window (both ends included).
	ArcadeNative = {
		TimingWindowSecondsW1   = 0.017,  -- +-17 ms  Marvelous
		TimingWindowSecondsW2   = 0.034,  -- +-34 ms  Perfect
		TimingWindowSecondsW3   = 0.084,  -- +-84 ms  Great
		TimingWindowSecondsW4   = 0.124,  -- +-124 ms Good
		-- 125..160 ms: the step is IGNORED (no judgment, the combo is not broken, the note keeps waiting). Done with
		-- W5 = 0.160 and the W5 window disabled per player (ApplyPerPlayer): a step there gets no judgment at all.
		TimingWindowSecondsW5   = 0.160,
		-- A note not stepped on is a MISS 160 ms after it, whatever the other windows are (IndependentMissWindow).
		TimingWindowSecondsMiss = 0.160,
		-- Freeze arrows: releasing the panel for less than 300 ms does not break the freeze (the hold life empties in
		-- 0.300 s without pressing and refills when pressed again). The Miss no longer depends on this.
		TimingWindowSecondsHold       = 0.300,
		TimingWindowSecondsRoll       = 0.300,
		TimingWindowSecondsCheckpoint = 0.160,
		TimingWindowSecondsAttack     = 0.135,
		-- Shock arrows (a row with a mine on every column, ShockArrowJudgment): the window opens 34 ms before the row and
		-- closes 84 ms after it. O.K. as soon as no panel is pressed inside it; N.G. if a panel is still pressed when it
		-- closes (you have to be STANDING on a panel the whole time). One judgment for the whole row.
		TimingWindowSecondsShockEarly = 0.034,
		TimingWindowSecondsShockLate  = 0.084,
		TimingWindowSecondsMine       = 0.008,  -- loose mines that are not a full shock row
		-- Jumps: the panels of a row may be stepped up to 66 ms apart (the later step gives the judgment).
		TimingWindowJump        = 0.067,
		TimingWindowAdd         = 0,      -- no extra leniency
		TimingWindowScale       = 1,
		RegenComboAfterMiss     = 0,      -- no combo regeneration after a miss
		MaxRegenComboAfterMiss  = 0,
	},
	-- Fallback (engines without the systems above): the timing used before, unchanged.
	Arcade = {
		TimingWindowSecondsW1   = 0.017,  -- +-17 ms  Marvelous
		TimingWindowSecondsW2   = 0.034,  -- +-34 ms  Perfect
		TimingWindowSecondsW3   = 0.084,  -- +-84 ms  Great
		TimingWindowSecondsW4   = 0.124,  -- +-124 ms Good
		TimingWindowSecondsW5   = 0.126,  -- just above Good: practically no Way Off
		-- The engine counts a note as MISSED when it is older than the LARGEST of ALL these windows
		-- (Player::GetMaxStepDistanceSeconds: W1..W5, Mine, Hold, Roll, Attack and Checkpoint), so none of them may be
		-- larger than the Miss time wanted (160 ms). Hold, Roll and Checkpoint are also how long a hold or
		-- roll survives without being pressed, so they are 160 ms too.
		-- TEST (2026-11-06): Hold and Roll are 0.20 (were 0.16: releasing a freeze / roll for just over 1/6 s gave N.G.).
		-- Side effect: the Miss now comes 0.20 s after the note instead of 0.16 s (see above). To go back, put both to 0.160.
		TimingWindowSecondsHold       = 0.200,
		TimingWindowSecondsRoll       = 0.200,
		TimingWindowSecondsCheckpoint = 0.160,
		TimingWindowSecondsAttack     = 0.135,
		TimingWindowSecondsMine       = 0.008,  -- shock arrows
		TimingWindowAdd         = 0,      -- no extra leniency
		TimingWindowScale       = 1,
		RegenComboAfterMiss     = 0,      -- no combo regeneration after a miss
		MaxRegenComboAfterMiss  = 0,
	},
	StepMania = {
		TimingWindowSecondsW1   = 0.0225,
		TimingWindowSecondsW2   = 0.045,
		TimingWindowSecondsW3   = 0.090,
		TimingWindowSecondsW4   = 0.135,
		TimingWindowSecondsW5   = 0.180,
		TimingWindowSecondsHold       = 0.250,
		TimingWindowSecondsRoll       = 0.500,
		TimingWindowSecondsCheckpoint = 0.1664,
		TimingWindowSecondsAttack     = 0.135,
		TimingWindowSecondsMine       = 0.090,
		TimingWindowAdd         = 0,
		TimingWindowScale       = 1,
		RegenComboAfterMiss     = 5,
		MaxRegenComboAfterMiss  = 5,
	},
}

-- In the fallback, true would also turn the Way Off judgment off per player (hits outside the Good window ignored).
-- Left off there: W5 is already just above W4. The native version always disables it (see above).
local DISABLE_W5 = false

local function PrefExists(name)
	local ok, res = pcall(function() return PREFSMAN:PreferenceExists(name) end)
	return ok and res == true
end

-- True when the engine has the independent Miss window and the shock arrow judging.
function ArcadeTiming.Native()
	if ArcadeTiming.NativeCache == nil then
		ArcadeTiming.NativeCache = PrefExists("TimingWindowSecondsMiss")
			and PrefExists("TimingWindowSecondsShockEarly")
			and PrefExists("TimingWindowSecondsShockLate")
	end
	return ArcadeTiming.NativeCache
end

-- The theme always uses the Arcade timing; the native version when the engine supports it.
function ArcadeTiming.Current()
	return ArcadeTiming.Native() and "ArcadeNative" or "Arcade"
end

-- Sets the engine preferences of the chosen timing. Safe to call as many times as needed.
-- A preference this engine does not have is skipped.
function ArcadeTiming.Apply()
	for key, value in pairs(PROFILES[ArcadeTiming.Current()]) do
		if PrefExists(key) then PREFSMAN:SetPreference(key, value) end
	end
end

-- Back to the engine's stock values.
function ArcadeTiming.Reset()
	local done = {}
	for _, name in ipairs({ "ArcadeNative", "Arcade" }) do
		for key in pairs(PROFILES[name]) do
			if not done[key] and PrefExists(key) then
				PREFSMAN:SetPreferenceToDefault(key)
				done[key] = true
			end
		end
	end
end

-- Per player, when a song starts: W5 off in the native version (steps at 125..160 ms are ignored). The fallback does
-- nothing here unless DISABLE_W5. Applied to every mods level so it also reaches the song that is starting.
function ArcadeTiming.ApplyPerPlayer()
	if not (ArcadeTiming.Native() or DISABLE_W5) then return end
	for _, pn in ipairs(GAMESTATE:GetHumanPlayers()) do
		local ps = GAMESTATE:GetPlayerState(pn)
		for _, level in ipairs({ "ModsLevel_Preferred", "ModsLevel_Stage", "ModsLevel_Song", "ModsLevel_Current" }) do
			local options = ps:GetPlayerOptions(level)
			if options and options.DisableTimingWindow then
				options:DisableTimingWindow("TimingWindow_W5")
			end
		end
	end
end
