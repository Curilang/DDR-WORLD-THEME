local pn = ...
local Risky = GAMESTATE:GetPlayerState(pn):GetPlayerOptions('ModsLevel_Current'):LifeSetting() == 'LifeType_Battery'
local sizex = 273
local sizey = 25

_G.FinalLife = _G.FinalLife or {}

-- ---------------------------------------------------------------------------
-- FLARE gauge support (see Scripts/08 FlareGauge.lua)
--
-- With a FLARE the bar is not driven by the engine's life meter, because the engine only redraws it
-- once the song has started. Instead the bar texture is cropped from the right to match the FLARE value.
-- Danger is also decided by the FLARE gauge (FlareDangerChanged message), not by the engine.
-- ---------------------------------------------------------------------------
local flareLevel = FlareGauge.StartLevel(pn)   -- level 1..10 in use, nil without FLARE
local flareDanger = false
local flareGauge = 1       -- FLARE gauge, 0..1
local flarePrev = 1        -- previous gauge value, to know whether it is dropping
local flareSwapping = false   -- true while the old bar empties and the next level's bar has not appeared yet

local function RefillTimes()
	local R = FlareGauge.Refill or {}
	return R.collapse or 0.14, R.fill or 0.14
end

-- Crops the bar to the current gauge value. With tween, the change is animated; when the gauge drops,
-- the edge bounces a little and settles, like the arcade.
local function FlareCrop(s, tween)
	if not flareLevel then return end
	local c = 1 - flareGauge
	if not tween then s:cropright(c) return end
	s:stoptweening()
	local B = FlareGauge.Bounce
	if B and flareGauge < flarePrev then
		s:linear(0.05):cropright(c)
		local amp = B.amp
		for _ = 1, B.count do
			s:linear(B.period):cropright(math.max(0, c - amp)):linear(B.period):cropright(c)
			amp = amp * 0.6
		end
	else
		s:linear(0.12):cropright(c)
	end
end

local function FlareState() return flareDanger and "danger" or "normal" end

-- Texture for a bar state. With a FLARE it uses stream/flare_N (or the shared danger one); if that file does
-- not exist yet it falls back to the regular texture tinted with the level color.
local function StreamPath(state)
	if flareLevel then
		local f = FlareGauge.StreamTex(flareLevel, state == "danger" and "_danger" or "")
		if f then return f, false end
	end
	return THEME:GetPathB("","ScreenGameplay decorations/lifeframe/stream/"..state), flareLevel ~= nil
end

local function FlareTint(s, danger, tint)
	if not flareLevel then return end
	if danger or tint == false then s:diffuse(Color.White) else s:diffuse(color(FlareGauge.Colors[flareLevel])) end
end

local function ApplyStream(s, state)
	local path, tint = StreamPath(state)
	s:Load(path):setsize(sizex,sizey)
	FlareTint(s, state == "danger", tint)
end

-- Remembers the gauge value from a FlareGaugeChanged message (both bar layers listen to it).
local function TrackGauge(param)
	if param.Gauge ~= flareGauge then flarePrev = flareGauge; flareGauge = param.Gauge end
end

-- Value shown on the results screen: the FLARE gauge when there is one, the engine's life otherwise.
local function SaveFinalLife()
	local screen = SCREENMAN:GetTopScreen()
	if screen and screen.GetLifeMeter then
		local st = FlareGauge.State[pn]
		_G.FinalLife[pn] = st and st.gauge or screen:GetLifeMeter(pn):GetLife()
	end
end

return Def.ActorFrame{
	InitCommand=function(s)
		s:xy(pn==PLAYER_1 and _screen.cx-233 or _screen.cx+233, SCREEN_TOP+23):draworder(99)
	end,
	Name="LifeFrame",
	Def.Sprite{
		Texture=THEME:GetPathB("","ScreenGameplay decorations/lifeframe/stream/base"),
		InitCommand=function(s) s:xy(pn==PLAYER_1 and -9 or 11,2):zoom(0.667):diffusealpha(Risky and 0 or 1) end,
	};

	-- The bar itself
	Def.Sprite{
		Texture=THEME:GetPathB("","ScreenGameplay decorations/lifeframe/stream/normal"),
		InitCommand=function(s) s:xy(pn==PLAYER_1 and -11 or 8,2):setsize(sizex,sizey) end,
		OnCommand=function(s)
			if not flareLevel then
				s:MaskDest()
				s:ztestmode("ZTestMode_WriteOnFail")
			end
			-- Regular bar scrolls; with a FLARE the base stays still and only the effect layer moves.
			s:texcoordvelocity(flareLevel and 0 or 0.6, 0)
			if flareLevel then ApplyStream(s, FlareState()); FlareCrop(s) end
		end,
		FlareGaugeChangedMessageCommand=function(self, param)
			if param.Player == pn then
				TrackGauge(param)
				if not flareSwapping then FlareCrop(self, true) end
			end
		end,
		-- FLOATING level change: the old bar empties, then the next level's texture appears and grows
		-- to its value (timings in FlareGauge.Refill).
		FlareLevelChangedMessageCommand=function(self, param)
			if param.Player == pn then
				flareLevel = param.Level
				flareSwapping = true
				local collapse = RefillTimes()
				self:stoptweening():linear(collapse):cropright(1):queuecommand("Swap")
			end
		end,
		SwapCommand=function(self)
			local _, fill = RefillTimes()
			flareSwapping = false
			ApplyStream(self, FlareState())
			self:linear(fill):cropright(1 - flareGauge)
		end,
		FlareDangerChangedMessageCommand=function(self, param)
			if param.Player == pn then
				flareDanger = param.Danger
				if not flareSwapping then ApplyStream(self, FlareState()) end
			end
		end,
		HealthStateChangedMessageCommand=function(self, param)
			self:setsize(sizex,sizey)
			if flareLevel then return end   -- the FLARE gauge decides danger
			if param.PlayerNumber == pn then
				local state = "normal"
				if param.HealthState == "HealthState_Danger" then state = "danger"
				elseif param.HealthState == "HealthState_Hot" then state = "full" end
				ApplyStream(self, state)
			end
		end,
	};

	-- FLARE effect layer (flare_N_ef), drawn over the bar and cropped the same way
	Def.Sprite{
		Texture=THEME:GetPathB("","ScreenGameplay decorations/lifeframe/stream/normal"),
		InitCommand=function(s) s:xy(pn==PLAYER_1 and -11 or 8,2):setsize(sizex,sizey):visible(false) end,
		OnCommand=function(s)
			if not flareLevel then
				s:MaskDest()
				s:ztestmode("ZTestMode_WriteOnFail")
			end
			s:playcommand("Refresh")
		end,
		RefreshCommand=function(s)
			local f = flareLevel and FlareGauge.StreamTex(flareLevel, flareDanger and "_danger_ef" or "_ef")
			if f then
				s:visible(true):Load(f):setsize(sizex,sizey):blend(FlareGauge.EffectBlend)
				s:texcoordvelocity(FlareGauge.EffectVelocity,0)
				FlareCrop(s)
			else
				s:visible(false)
			end
		end,
		FlareGaugeChangedMessageCommand=function(s, param)
			if param.Player == pn then
				TrackGauge(param)
				if not flareSwapping then FlareCrop(s, true) end
			end
		end,
		FlareLevelChangedMessageCommand=function(s, param)
			if param.Player == pn then
				flareLevel = param.Level
				flareSwapping = true
				local collapse = RefillTimes()
				s:stoptweening():linear(collapse):cropright(1):queuecommand("Swap")
			end
		end,
		SwapCommand=function(s)
			local _, fill = RefillTimes()
			flareSwapping = false
			s:playcommand("Refresh")
			s:cropright(1):linear(fill):cropright(1 - flareGauge)
		end,
		-- The engine delivers a message to its listeners in memory-address order, not in the order they were created, so this
		-- layer may hear FlareDangerChanged / FlareLevelChanged BEFORE the bar layer above does. It must not depend on
		-- the bar having updated the shared flags first (it used to, and the colored flare_N_ef stayed on the grey danger bar
		-- from time to time): every handler sets what it reads from the message itself.
		FlareDangerChangedMessageCommand=function(s, param)
			if param.Player == pn then
				flareDanger = param.Danger
				if not flareSwapping then s:playcommand("Refresh") end
			end
		end,
	};

	Def.Sprite{
		Name="LifeFrame"..pn,
		InitCommand=function(s) s:xy(pn==PLAYER_1 and -9 or 9,2):zoom(0.667) end,
		BeginCommand=function(self)
			if Risky then
				self:Load(THEME:GetPathB("ScreenGameplay","decorations/lifeframe/life"))
			else
				self:Load(THEME:GetPathB("ScreenGameplay","decorations/lifeframe/normal"))
			end
		end
	};

	-- Keeps the last life value for the results screen
	Def.Actor{
		InitCommand=function(self) self:queuecommand("Update") end,
		UpdateCommand=function(self)
			SaveFinalLife()
			self:sleep(0.05)
			self:queuecommand("Update")
		end,
		OffCommand=function(self) SaveFinalLife() end,
	}
};
