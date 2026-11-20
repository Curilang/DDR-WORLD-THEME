-- Preferencias de las opciones de jugador POR PERFIL.
-- Se guardan en <carpeta del perfil>/<Tema> UserPrefs.ini, así que siguen al perfil aunque cambie de P1 a P2.
-- (Se llama POProfile porque el tema ya tiene un ProfilePrefs en "05 ProfilePrefs.lua".)
POProfile = {}

local SECTION = "Options"
local SLOT = { [PLAYER_1] = "ProfileSlot_Player1", [PLAYER_2] = "ProfileSlot_Player2" }
local cache = {}                                       -- [carpeta] = tabla ini
local guest = { [PLAYER_1] = {}, [PLAYER_2] = {} }     -- sin perfil: solo vale en esta sesión

local function Dir(pn)
	if not pn or not SLOT[pn] then return nil end
	if not PROFILEMAN:IsPersistentProfile(pn) then return nil end
	local d = PROFILEMAN:GetProfileDir(SLOT[pn])
	if d and d ~= "" then return d end
	return nil
end

local function Path(dir)
	return dir .. THEME:GetThemeDisplayName() .. " UserPrefs.ini"
end

local function Load(dir)
	if cache[dir] then return cache[dir] end
	local t
	if FILEMAN:DoesFileExist(Path(dir)) then t = IniFile.ReadFile(Path(dir)) end
	if type(t) ~= "table" then t = {} end
	t[SECTION] = t[SECTION] or {}
	cache[dir] = t
	return t
end

-- Devuelve el valor guardado (string) o 'default' si no hay.
function POProfile.Get(pn, key, default)
	local dir = Dir(pn)
	local v
	if dir then
		v = Load(dir)[SECTION][key]
	elseif pn and guest[pn] then
		v = guest[pn][key]
	end
	if v == nil then return default end
	return tostring(v)
end

function POProfile.Set(pn, key, value)
	value = tostring(value)
	local dir = Dir(pn)
	if not dir then
		if pn and guest[pn] then guest[pn][key] = value end
		return
	end
	local t = Load(dir)
	t[SECTION][key] = value
	IniFile.WriteFile(Path(dir), t)
end

-- Velocidad por perfil.
-- Ahora se guarda con POProfile (03 ProfileOptions.lua): un ini dentro de la carpeta del perfil
-- (claves SpeedMode y RealSpeed), igual que Guideline / Lane Preview / Fast-Slow.
-- Lo guardado antes como .cfg (Save/UserPrefs/<Tema>/SpeedMod_<GUID>.cfg, RealSpeed_<GUID>.cfg y
-- RealSpeed_<slot>.cfg) se lee solo como respaldo y, si existe, se pasa al perfil la primera vez.

-- Lectura del .cfg antiguo. Se recuerda el resultado para no volver a tocar el disco.
local legacyMemo = {}
local function LegacyRead(name)
	local m = legacyMemo[name]
	if m ~= nil then return m or nil end
	local v = nil
	local path = "Save/UserPrefs/" .. THEME:GetThemeDisplayName() .. "/" .. name .. ".cfg"
	if FILEMAN:DoesFileExist("/" .. path) then v = ReadPrefFromFile(name) end
	legacyMemo[name] = v or false
	return v
end

-- GUID del perfil; sin perfil (invitado) se usa el slot. Solo se usa para leer los .cfg antiguos.
function SpeedProfileKey(pn)
	if PROFILEMAN:IsPersistentProfile(pn) then
		local pf = PROFILEMAN:GetProfile(pn)
		if pf then return pf:GetGUID() end
	end
	return "Guest" .. ToEnumShortString(pn)
end

-- Modo que usa un perfil (o invitado) que aún no ha elegido: "RealSpeed" o "Xmod".
local DEFAULT_SPEED_MODE = "RealSpeed"

-- Devuelve "Xmod" o "RealSpeed". Si el perfil no ha elegido, parte del .cfg antiguo
-- y, si tampoco hay, de DEFAULT_SPEED_MODE.
function GetSpeedMode(pn)
	local t = POProfile.Get(pn, "SpeedMode", nil)
	if t == nil then
		local old = LegacyRead("SpeedMod_" .. SpeedProfileKey(pn))
		if old then
			if old ~= "RealSpeed" then old = "Xmod" end
			POProfile.Set(pn, "SpeedMode", old)           -- migra al perfil
			t = old
		else
			t = DEFAULT_SPEED_MODE
		end
	end
	if t == "RealSpeed" then return "RealSpeed" end
	return "Xmod"
end

function SetSpeedMode(pn, mode)
	POProfile.Set(pn, "SpeedMode", mode)
end

-- Valor de Real Speed del perfil (si no tiene, hereda el .cfg antiguo; si tampoco, 120).
-- Mantiene _G.RealSpeed[pn] actualizado para el código que lo lea directo.
function GetRealSpeed(pn)
	local v = tonumber(POProfile.Get(pn, "RealSpeed", nil))
	if not v then
		v = tonumber(LegacyRead("RealSpeed_" .. SpeedProfileKey(pn)))
			or tonumber(LegacyRead("RealSpeed_" .. tostring(pn)))
		if v then POProfile.Set(pn, "RealSpeed", tostring(v)) end   -- migra al perfil
		v = v or 120
	end
	_G.RealSpeed = _G.RealSpeed or {}
	_G.RealSpeed[pn] = v
	return v
end

function SetRealSpeed(pn, v)
	_G.RealSpeed = _G.RealSpeed or {}
	_G.RealSpeed[pn] = v
	POProfile.Set(pn, "RealSpeed", tostring(v))
end
