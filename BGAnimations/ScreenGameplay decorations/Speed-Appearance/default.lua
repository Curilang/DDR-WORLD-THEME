local t = Def.ActorFrame{};
local pn = ({...})[1]

-- OPTIONS (guardadas temporalmente)
local OptionsByPlayer = {
	PlayerNumber_P1 = GAMESTATE:GetPlayerState('PlayerNumber_P1'):GetPlayerOptionsString('ModsLevel_Preferred'),
	PlayerNumber_P2 = GAMESTATE:GetPlayerState('PlayerNumber_P2'):GetPlayerOptionsString('ModsLevel_Preferred'),
}
local OptionsSongByPlayer = {
	PlayerNumber_P1 = GAMESTATE:GetPlayerState('PlayerNumber_P1'):GetPlayerOptionsString('ModsLevel_Song'),
	PlayerNumber_P2 = GAMESTATE:GetPlayerState('PlayerNumber_P2'):GetPlayerOptionsString('ModsLevel_Song'),
}

local numPlayers = GAMESTATE:GetNumPlayersEnabled()
local center1P = PREFSMAN:GetPreference("Center1Player")
local style = GAMESTATE:GetCurrentStyle();
local styleType = ToEnumShortString(style:GetStyleType());

-- Gráfico del lane cover: "single.png" / "double.png", en la misma carpeta que este default.lua.
-- Es el mismo para los dos jugadores.
local function CoverGraphicPath(kind, player)
	return string.lower(kind) .. ".png"
end

-- Helper: normalize and apply battery/lives to an options string
local function applyLivesOption(opt_str)
	-- remove any existing battery tokens first
	opt_str = string.gsub(opt_str, "(battery,)", "")
	-- check explicit lives patterns (allow forms "1Lives" or "1 Lives")
	for i = 1, 4 do
		if string.find(opt_str, tostring(i) .. "Lives") or string.find(opt_str, tostring(i) .. " Lives") then
			-- remove existing XLives token if present
			opt_str = string.gsub(opt_str, "(" .. tostring(i) .. "Lives,)", "")
			opt_str = string.gsub(opt_str, "(" .. tostring(i) .. " Lives,)", "")
			-- append battery form used elsewhere in the theme
			opt_str = opt_str .. ",failimmediate,battery, " .. tostring(i) .. " Lives"
			return opt_str
		end
	end
	-- no lives keyword found -> just return with battery removed
	return opt_str
end

function retrieveMeterType()
	-- Extra stages: the gauge (FLARE, FLOATING FLARE, LIFE4 or RISKY) is the one the player chose in the options menu,
	-- the extra stage does not force a battery any more (the default is set in ScreenSelectMusic overlay/default.lua)
	if GAMESTATE:IsExtraStage() or GAMESTATE:IsExtraStage2() then
		-- (nothing)
	else
		-- Normal flow: apply any "XLives" keywords into battery options
		OptionsByPlayer.PlayerNumber_P1 = applyLivesOption(OptionsByPlayer.PlayerNumber_P1)
		OptionsByPlayer.PlayerNumber_P2 = applyLivesOption(OptionsByPlayer.PlayerNumber_P2)
	end

	GAMESTATE:SetFailTypeExplicitlySet();
end

function RecordGameplayMeterType(player)
	if GAMESTATE:IsCourseMode() or GAMESTATE:IsExtraStage() or GAMESTATE:IsExtraStage2() then return end

	local pf = PROFILEMAN:GetProfile(player)
	if not pf then return end
	local PlayerUID = pf:GetGUID()
	local Options = (player == "PlayerNumber_P1") and OptionsByPlayer.PlayerNumber_P1 or OptionsByPlayer.PlayerNumber_P2

	if string.find(Options, "battery") then
		if string.find(Options, "1Lives") or string.find(Options, "1 Lives") then
			SaveGameplayMeterTypeForPlayer(PlayerUID, "1 Lives")
		elseif string.find(Options, "2Lives") or string.find(Options, "2 Lives") then
			SaveGameplayMeterTypeForPlayer(PlayerUID, "2 Lives")
		elseif string.find(Options, "3Lives") or string.find(Options, "3 Lives") then
			SaveGameplayMeterTypeForPlayer(PlayerUID, "3 Lives")
		elseif string.find(Options, "4Lives") or string.find(Options, "4 Lives") then
			SaveGameplayMeterTypeForPlayer(PlayerUID, "4 Lives")
		end
	else
		SaveGameplayMeterTypeForPlayer(PlayerUID, "Normal")
	end
end

function SetGameplayMeterType(player)
	if GAMESTATE:IsCourseMode() or GAMESTATE:IsExtraStage() or GAMESTATE:IsExtraStage2() then return end

	local pf = PROFILEMAN:GetProfile(player)
	if not pf then return end
	local PlayerUID = pf:GetGUID()

	-- read whatever value saved for this player
	local val = ReadOrCreateGameplayMeterTypeForPlayer(PlayerUID)

	-- get current preferred options fresh
	local OptionsP1P = GAMESTATE:GetPlayerState('PlayerNumber_P1'):GetPlayerOptionsString('ModsLevel_Preferred');
	local OptionsP2P = GAMESTATE:GetPlayerState('PlayerNumber_P2'):GetPlayerOptionsString('ModsLevel_Preferred');
	local Options = (player == "PlayerNumber_P1") and OptionsP1P or OptionsP2P

	-- remove any previous battery and XLives tokens then append based on saved val
	Options = string.gsub(Options, "(battery,)", "")
	Options = string.gsub(Options, "(1Lives,)", "")
	Options = string.gsub(Options, "(2Lives,)", "")
	Options = string.gsub(Options, "(3Lives,)", "")
	Options = string.gsub(Options, "(4Lives,)", "")

	if val == "1 Lives" then
		Options = Options .. ",failimmediate,battery, 1 Lives";
	elseif val == "2 Lives" then
		Options = Options .. ",failimmediate,battery, 2 Lives";
	elseif val == "3 Lives" then
		Options = Options .. ",failimmediate,battery, 3 Lives";
	elseif val == "4 Lives" then
		Options = Options .. ",failimmediate,battery, 4 Lives";
	else
		-- Normal -> no battery
	end

	if player == "PlayerNumber_P1" then
		GAMESTATE:GetPlayerState('PlayerNumber_P1'):SetPlayerOptions('ModsLevel_Preferred', Options);
	else
		GAMESTATE:GetPlayerState('PlayerNumber_P2'):SetPlayerOptions('ModsLevel_Preferred', Options);
	end
end

----------------------------------------------------------------------
-- GUARDADO POR PERFIL: POProfile (Scripts/03 ProfileOptions.lua)
-- Todo va al "<Tema> UserPrefs.ini" de la carpeta del perfil, seccion [Options]:
--   LaneCoverPosition      posicion del cover en Hidden+ / Sudden+
--   LaneCoverPositionDual  posicion de los covers en HIDSUD+
--   GameplayMeterType      tipo de gauge que se restaura al cambiar la velocidad
-- Sin perfil (invitado) POProfile solo lo recuerda durante la sesion.
----------------------------------------------------------------------
-- Las funciones globales conservan su nombre y su argumento (PlayerUID) por si otro archivo
-- del tema las llama; solo cambia donde guardan.
local function PlayerFromUID(PlayerUID)
	for _, pn in ipairs({PLAYER_1, PLAYER_2}) do
		local pf = PROFILEMAN:GetProfile(pn)
		if pf and pf:GetGUID() == PlayerUID then return pn end
	end
	return nil
end

function ReadOrCreateGameplayMeterTypeForPlayer(PlayerUID, MyValue)
	local pn = PlayerFromUID(PlayerUID)
	if not pn then return "Normal" end
	return POProfile.Get(pn, "GameplayMeterType", "Normal")
end

function SaveGameplayMeterTypeForPlayer(PlayerUID, MyValue)
	local pn = PlayerFromUID(PlayerUID)
	if pn then POProfile.Set(pn, "GameplayMeterType", MyValue) end
end

----------------------------------------------------------------------
-- LANE COVER (Hidden+ / Sudden+ / Hidden+&Sudden+)
--
-- Estado en memoria por jugador, un solo controlador por jugador (asi
-- HIDSUD+ ya no aplica el movimiento dos veces) y guardado por perfil con POProfile (ver arriba).
-- Ocultar con START NO se guarda: cada cancion empieza con el cover visible.
----------------------------------------------------------------------
-- Como en el arcade: un toque mueve poco (ajuste fino) y mantener presionado MenuUp / MenuDown
-- mueve rapido. Ajusta estos tres valores a tu gusto.
local COVER_TAP_STEP   = 5    -- pixeles por toque (tap x tap)
local COVER_HOLD_DELAY = 0.3  -- segundos presionado antes de empezar a correr
local COVER_HOLD_SPEED = 240  -- pixeles por segundo mientras se mantiene presionado

-- Despues del primer STEP del jugador (la primera nota de la cancion, ya sea
-- acertada o fallada) ya no se puede mover el cover ni cambiar la velocidad
-- (solo START para ocultar / mostrar el cover). Se reinicia en cada cancion.
local SteppedByPlayer = {
	PlayerNumber_P1 = false,
	PlayerNumber_P2 = false,
}
local function CoverInputLocked(pn)
	return SteppedByPlayer[pn] == true
end

local CoverState  = {}  -- [player] = { single = 0, dual = 0, hidden = false }
local CoverLayers = {}  -- [player] = { { actor = <actor>, mode = "Hidden+"/"Sudden+", two = bool }, ... }

local function LoadCoverState(player)
	local st = {
		single = tonumber(POProfile.Get(player, "LaneCoverPosition", "0")) or 0,
		dual   = tonumber(POProfile.Get(player, "LaneCoverPositionDual", "0")) or 0,
		hidden = false,
	}
	if st.dual > 0 then st.dual = 0 end
	return st
end

local function SaveCoverState(player)
	local st = CoverState[player]
	local layers = CoverLayers[player]
	if not st or not layers or #layers == 0 then return end
	if layers[1].two then
		POProfile.Set(player, "LaneCoverPositionDual", st.dual)
	else
		POProfile.Set(player, "LaneCoverPosition", st.single)
	end
end

-- Reverse (opciones del jugador, o la cancion actual si es un Course)
local function CoverIsReverse(player)
	local opt = OptionsByPlayer[player] or ""
	if string.find(string.lower(opt), "reverse") then return true end
	if GAMESTATE:IsCourseMode() then
		local trail = GAMESTATE:GetCurrentTrail(player)
		if trail then
			local entry = trail:GetTrailEntry(GAMESTATE:GetCourseSongIndex())
			if entry and string.find(string.lower(entry:GetNormalModifiers()), "reverse") then
				return true
			end
		end
	end
	return false
end

-- Posicion Y del cover segun modo y Reverse.
-- Hidden+ (normal) y Sudden+ (Reverse) usan y = amount; los otros dos son su espejo: y = alto - amount.
-- Antes el espejo llevaba un "- 32" de mas, por eso Sudden+ subia de mas, no bajaba por completo
-- y en HIDSUD+ los dos covers no se cerraban en el centro.
local function CoverY(mode, amount, isReverse)
	local fromTop = (mode == "Hidden+") ~= isReverse
	if fromTop then return amount end
	return SCREEN_HEIGHT - amount
end

local function ApplyCover(layer, player, tween)
	local st = CoverState[player]
	local actor = layer.actor
	if not st or not actor then return end
	local amount = layer.two and st.dual or st.single
	actor:stoptweening()
	actor:diffusealpha(st.hidden and 0 or 1)
	if tween then actor:linear(0.1) end
	actor:y(CoverY(layer.mode, amount, CoverIsReverse(player)))
end

-- dir: +1 = MenuDown (el cover baja en pantalla), -1 = MenuUp (el cover sube); amount en pixeles
local function MoveCover(player, dir, amount, tween)
	local st = CoverState[player]
	local layers = CoverLayers[player]
	if not st or not layers or #layers == 0 then return end

	if layers[1].two then
		-- HIDSUD+: los dos covers se juntan con Down y se separan con Up
		st.dual = math.max(-SCREEN_HEIGHT/2, math.min(0, st.dual + dir * amount))
	else
		-- Hidden+ / Sudden+: el delta se define en terminos de pantalla (arriba/abajo),
		-- y se invierte segun el modo y Reverse.
		local isReverse = CoverIsReverse(player)
		local sign
		if layers[1].mode == "Hidden+" then
			sign = isReverse and -1 or 1
		else
			sign = isReverse and 1 or -1
		end
		st.single = math.max(-SCREEN_HEIGHT/2, math.min(SCREEN_HEIGHT/2, st.single + dir * sign * amount))
	end

	-- mover el cover lo vuelve a mostrar si estaba oculto
	st.hidden = false
	for _, layer in ipairs(layers) do ApplyCover(layer, player, tween) end
end

-- Mantener presionado MenuUp / MenuDown: CoverHold[player] = { dir, time, moved }
local CoverHold = {}

local function StopCoverHold(player)
	local h = CoverHold[player]
	CoverHold[player] = nil
	local st = CoverState[player]
	if h and h.moved and st then
		-- al soltar: se redondea a pixeles enteros y se guarda una sola vez
		st.single = math.floor(st.single + 0.5)
		st.dual = math.floor(st.dual + 0.5)
		for _, layer in ipairs(CoverLayers[player]) do ApplyCover(layer, player, false) end
		SaveCoverState(player)
	end
end

local function CoverHoldInput(player, event)
	if event.PlayerNumber ~= player or not CoverState[player] then return end
	local btn = event.GameButton or event.button
	local dir = nil
	if btn == "MenuDown" then dir = 1 elseif btn == "MenuUp" then dir = -1 end
	if not dir then return end

	if event.type == "InputEventType_FirstPress" then
		if not CoverInputLocked(player) then
			CoverHold[player] = { dir = dir, time = 0, moved = false }
		end
	elseif event.type == "InputEventType_Release" then
		local h = CoverHold[player]
		if h and h.dir == dir then StopCoverHold(player) end
	end
end

local function CoverHoldUpdate(player, dt)
	local h = CoverHold[player]
	if not h then return end
	if CoverInputLocked(player) then StopCoverHold(player) return end
	dt = math.min(dt, 0.05)
	h.time = h.time + dt
	if h.time < COVER_HOLD_DELAY then return end
	h.moved = true
	MoveCover(player, h.dir, COVER_HOLD_SPEED * dt, false)
end

local function HandleCoverCode(player, name)
	local st = CoverState[player]
	local layers = CoverLayers[player]
	if not st or not layers or #layers == 0 then return end

	-- START: ocultar / mostrar (siempre permitido, tambien despues del primer step)
	if name == "AppearancePlusShow" then
		-- si el mismo START llega dos veces seguidas se anularian entre si; se ignora el repetido
		local now = GetTimeSinceStart()
		if st.lastToggle and now - st.lastToggle < 0.2 then return end
		st.lastToggle = now
		st.hidden = not st.hidden
		for _, layer in ipairs(layers) do ApplyCover(layer, player, false) end
		return
	end

	local dir = 0
	if name == "AppearancePlusHarsher" then dir = 1
	elseif name == "AppearancePlusEasier" then dir = -1
	else return end

	if CoverInputLocked(player) then return end

	-- si ya esta corriendo por mantener presionado, no se suma el toque encima
	local h = CoverHold[player]
	if h and h.moved then return end

	-- toque: paso fino
	MoveCover(player, dir, COVER_TAP_STEP, true)
	SaveCoverState(player)
end

local function AddCoverLayer(FileName, player, pos, Mode, TwoCoverMode)
	local layer = { mode = Mode, two = TwoCoverMode }
	table.insert(CoverLayers[player], layer)

	t[#t+1] = LoadActor(FileName)..{
		InitCommand=function(self)
			layer.actor = self
			self:zoom(0.667):x(pos)
			ApplyCover(layer, player, false)
		end;
		HealthStateChangedMessageCommand=function(self, param)
			if param.PlayerNumber == player then
				if param.HealthState == "HealthState_Dead" then
					self:visible(false);
				else
					self:visible(true);
				end
			end;
		end;
	};
end

-- Appearance main
function AppearancePlusMain(pn)
	local player = pn;
	local pNum = (player == PLAYER_1) and 1 or 2
	local OptionString = (player == PLAYER_1)  and OptionsByPlayer.PlayerNumber_P1 or OptionsByPlayer.PlayerNumber_P2;
	local pf = PROFILEMAN:GetProfile(player)
	local PlayerUID = pf and pf:GetGUID() or "Unknown"

	local pos = SCREEN_CENTER_X;
	-- Center1Player solo centra cuando hay UN jugador; con 2, cada cover va a su lado
	if not (center1P and numPlayers == 1) then
		local metricName = string.format("PlayerP%i%sX", pNum, styleType)
		pos = THEME:GetMetric("ScreenGameplay", metricName)
	end

	local MyValue = ReadOrCreateAppearancePlusValueForPlayer(PlayerUID, "Visible");

	-- Normal options that use engine mods (we add them to OptionString)
	if MyValue == "Hidden" then
		OptionString = string.gsub(OptionString, "(Sudden,)", "");
		OptionString = string.gsub(OptionString, "(Stealth,)", "");
		OptionString = OptionString .. ', Hidden,';
	elseif MyValue == "Sudden" then
		OptionString = string.gsub(OptionString, "(Stealth,)", "");
		OptionString = string.gsub(OptionString, "(Hidden,)", "");
		OptionString = OptionString .. ', Sudden,';
	elseif MyValue == "Stealth" then
		OptionString = string.gsub(OptionString, "(Sudden,)", "");
		OptionString = string.gsub(OptionString, "(Hidden,)", "");
		OptionString = OptionString .. ', Stealth,';
	end

	-- CONSTANT drives the engine's Sudden by itself (Scripts/08 ConstantVisibility.lua), so the
	-- other visibility mods must not be active at the same time.
	if MyValue == "Constant" then
		OptionString = string.gsub(OptionString, "(Sudden,)", "");
		OptionString = string.gsub(OptionString, "(Stealth,)", "");
		OptionString = string.gsub(OptionString, "(Hidden,)", "");
	end

	-- For + modes we need to add covers. Use fewer branches by selecting graphic by steps type.
	local function addForMode(mode, twomode)
		local stepsType = GAMESTATE:GetCurrentStyle():GetStepsType()
		local kind = (stepsType == "StepsType_Dance_Single") and "Single" or "Double"
		local graphic = CoverGraphicPath(kind, player)
		if not graphic then return end
		AddCoverLayer(graphic, player, pos, mode, twomode)
	end

	-- The lane cover (Hidden+ / Sudden+ / both) is chosen only in LANE COVER SETTING, separately from the
	-- visibility above.
	local coverMode = POMenu and POMenu.LaneCoverMode and POMenu.LaneCoverMode(player)

	if coverMode == "Hidden+" or coverMode == "Sudden+" or coverMode == "Hidden+&Sudden+" then
		CoverState[player] = LoadCoverState(player)
		CoverLayers[player] = {}

		-- Un solo controlador por jugador: recibe los Codes (toques) y vigila el boton
		-- presionado (movimiento rapido) para mover todas sus capas
		t[#t+1] = Def.ActorFrame{
			InitCommand = function(self)
				self:SetUpdateFunction(function(af, dt) CoverHoldUpdate(player, dt) end)
			end;
			OnCommand = function(self)
				local screen = SCREENMAN:GetTopScreen()
				if screen and screen.AddInputCallback then
					screen:AddInputCallback(function(event) CoverHoldInput(player, event) end)
				end
			end;
			CodeMessageCommand = function(self, params)
				if params.PlayerNumber ~= player then return end
				HandleCoverCode(player, params.Name)
			end;
			-- cada cancion de un Course empieza con el cover visible. Fuera de Course no se toca:
			-- la pantalla ya empieza limpia y este mensaje podia llegar tarde y deshacer el START.
			CurrentSongChangedMessageCommand = function(self)
				if not GAMESTATE:IsCourseMode() then return end
				local st = CoverState[player]
				if not st then return end
				st.hidden = false
				for _, layer in ipairs(CoverLayers[player]) do
					ApplyCover(layer, player, false)
				end
			end;
		};
	end

	if coverMode == "Hidden+" then
		addForMode("Hidden+", false)
	elseif coverMode == "Sudden+" then
		addForMode("Sudden+", false)
	elseif coverMode == "Hidden+&Sudden+" then
		-- Hidden+ then Sudden+ (order doesn't affect visuals here)
		addForMode("Hidden+", true)
		addForMode("Sudden+", true)
	end

	return OptionString;
end

----------------------------------------------------------------------
-- SPEEDKILL: cambio de velocidad (X-Mod) durante el gameplay
-- Solo X-Mod: no hay logica de M-Mod ni C-Mod.
----------------------------------------------------------------------
local speedkills_Initialized = false;
local maxBPM = {
	PlayerNumber_P1 = 0,
	PlayerNumber_P2 = 0,
};

local function AddSpeedKill()
	t[#t+1] = Def.ActorFrame {
		OnCommand = function(self)
			-- BPM maximo de la cancion (o del course), solo para mostrar el BPM en el mensaje
			local pns = {
				'PlayerNumber_P1',
				'PlayerNumber_P2',
			};

			for _,v in pairs(pns) do
				if GAMESTATE:IsSideJoined(v) then
					local displayBPMs = {math.huge, 0}; -- Min, Max

					if GAMESTATE:IsCourseMode() then
						local trail = GAMESTATE:GetCurrentTrail(v);
						local entries = trail:GetTrailEntries();

						for i = 1, #entries do
							local song = entries[i]:GetSong();

							if not song:IsDisplayBpmSecret() then
								local curDisplayBPMs = song:GetDisplayBpms();
								displayBPMs[1] = math.min(curDisplayBPMs[1], displayBPMs[1]);
								displayBPMs[2] = math.max(curDisplayBPMs[2], displayBPMs[2]);
							else
								displayBPMs[1] = -1;
							end;
						end;

						if displayBPMs[1] < 0 then
							displayBPMs = {math.huge, 0};

							for i = 1, #entries do
								local song = entries[i]:GetSong();

								local curDisplayBPMs = song:GetDisplayBpms();
								displayBPMs[1] = math.min(curDisplayBPMs[1], displayBPMs[1]);
								displayBPMs[2] = math.max(curDisplayBPMs[2], displayBPMs[2]);
							end;
						end;
					else
						local song = GAMESTATE:GetCurrentSong();

						if not song:IsDisplayBpmSecret() then
							displayBPMs = song:GetDisplayBpms();
						else
							displayBPMs[1] = -1;
						end;

						if displayBPMs[1] < 0 then
							displayBPMs = song:GetTimingData():GetActualBPM();
						end;
					end;

					maxBPM[v] = displayBPMs[2];
				end;
			end;

			speedkills_Initialized = true;
		end;

		CodeMessageCommand = function(self, params)
			-- Solo reaccionar a SpeedUp / SpeedDown
			local pn = params.PlayerNumber;
			if not pn then return end
			if params.Name ~= "SpeedUp" and params.Name ~= "SpeedDown" then return end
			if not speedkills_Initialized then return end

			-- Despues del primer step ya no se puede cambiar la velocidad
			if CoverInputLocked(pn) then return end

			local ps = GAMESTATE:GetPlayerState(pn);
			local po = ps:GetPlayerOptions("ModsLevel_Preferred");

			-- Si el jugador no esta usando X-Mod no se toca nada
			local speed = po:XMod();
			if not speed then return end

			speed = math.floor(speed * 100 + 0.5) / 100
			local minSpeed, maxSpeed = 0.25, 10
			local speedDelta = (params.Name == "SpeedUp") and 0.05 or -0.05

			-- Pasos de 0.05 con limites entre 0.25 y 10
			speed = math.max(minSpeed, math.min(speed + speedDelta, maxSpeed))

			local modstring = ps:GetPlayerOptionsString("ModsLevel_Preferred");

			-- HACK: agregar "default, " para evitar un crash
			modstring = "default, " .. modstring;
			modstring = modstring .. ", " .. speed .. "x";

			ps:SetPlayerOptions("ModsLevel_Preferred", modstring);

			-- 1.00x -> 1.0x -> 1x
			local xString = string.format("%.2fx", speed);
			xString = string.gsub(xString, "(%d+%.%d)0x", "%1x");
			xString = string.gsub(xString, "(%d+)%.0x", "%1x");

			SCREENMAN:SystemMessage(string.format("%s: %s (m%.0f)", pn, xString, speed * maxBPM[pn]));

			retrieveMeterType();
			SetGameplayMeterType(pn);
		end;
	};
end

-- Detecta el primer step de cada jugador (primer juicio de la cancion) para bloquear
-- el movimiento del cover y el cambio de velocidad. Se reinicia con cada cancion.
t[#t+1] = Def.Actor{
	JudgmentMessageCommand = function(self, params)
		local pn = params.Player or params.PlayerNumber
		if not pn then return end
		if params.TapNoteScore == "TapNoteScore_AvoidMine" then return end
		SteppedByPlayer[pn] = true
	end;
	CurrentSongChangedMessageCommand = function(self)
		if not GAMESTATE:IsCourseMode() then return end
		SteppedByPlayer.PlayerNumber_P1 = false
		SteppedByPlayer.PlayerNumber_P2 = false
	end;
}

-- Apply initial retrieval
retrieveMeterType();

-- Lock SpeedMod when Oni Course has SpeedMod in course file
if GAMESTATE:GetPlayMode() == "PlayMode_Oni" then
	local trailHasSpeedMod = false;
	local trailHasAppearanceMode = false;

	local checkTrail = function(playerTag)
		if not GAMESTATE:IsPlayerEnabled(playerTag) then return {} end
		local trail = GAMESTATE:GetCurrentTrail(playerTag)
		if not trail then return {} end
		local entries = trail:GetTrailEntries()
		for i = 1, #entries do
			local modString = entries[i]:GetNormalModifiers()
			if string.find(modString, "x") or string.find(modString, "X") then
				trailHasSpeedMod = true
			end
			if string.find(modString, "Hidden") or string.find(modString, "Sudden") or string.find(modString, "Stealth") then
				trailHasAppearanceMode = true
			end
		end
		return entries
	end

	checkTrail('PlayerNumber_P1')
	checkTrail('PlayerNumber_P2')

	if not trailHasSpeedMod then
		AddSpeedKill();
	end

	if not trailHasAppearanceMode then
		if GAMESTATE:IsPlayerEnabled('PlayerNumber_P1') then
			OptionsByPlayer.PlayerNumber_P1 = AppearancePlusMain('PlayerNumber_P1');
		end
		if GAMESTATE:IsPlayerEnabled('PlayerNumber_P2') then
			OptionsByPlayer.PlayerNumber_P2 = AppearancePlusMain('PlayerNumber_P2');
		end
	end
else
	-- Non-Oni flow
	AddSpeedKill();

	if GAMESTATE:IsPlayerEnabled('PlayerNumber_P1') then
		OptionsByPlayer.PlayerNumber_P1 = AppearancePlusMain('PlayerNumber_P1');
		RecordGameplayMeterType('PlayerNumber_P1')
	end
	if GAMESTATE:IsPlayerEnabled('PlayerNumber_P2') then
		OptionsByPlayer.PlayerNumber_P2 = AppearancePlusMain('PlayerNumber_P2');
		RecordGameplayMeterType('PlayerNumber_P2')
	end
end

-- Oni Options hack
if GAMESTATE:GetPlayMode() == "PlayMode_Oni" then
	if GAMESTATE:IsPlayerEnabled('PlayerNumber_P1') then
		if GAMESTATE:GetCurrentTrail('PlayerNumber_P1'):GetDifficulty() == "Difficulty_Hard" then
			OptionsByPlayer.PlayerNumber_P1 = OptionsByPlayer.PlayerNumber_P1 .. ',failimmediate,battery,4 lives,'
		else
			OptionsByPlayer.PlayerNumber_P1 = OptionsByPlayer.PlayerNumber_P1 .. ',failimmediate,battery,8 lives,'
		end
	end

	if GAMESTATE:IsPlayerEnabled('PlayerNumber_P2') then
		if GAMESTATE:GetCurrentTrail('PlayerNumber_P2'):GetDifficulty() == "Difficulty_Hard" then
			OptionsByPlayer.PlayerNumber_P2 = OptionsByPlayer.PlayerNumber_P2 .. ',failimmediate,battery,4 lives,'
		else
			OptionsByPlayer.PlayerNumber_P2 = OptionsByPlayer.PlayerNumber_P2 .. ',failimmediate,battery,8 lives,'
		end
	end

	GAMESTATE:SetFailTypeExplicitlySet();
end

-- Apply options to players
GAMESTATE:GetPlayerState('PlayerNumber_P1'):SetPlayerOptions('ModsLevel_Preferred', OptionsByPlayer.PlayerNumber_P1);
GAMESTATE:GetPlayerState('PlayerNumber_P2'):SetPlayerOptions('ModsLevel_Preferred', OptionsByPlayer.PlayerNumber_P2);

return t;
