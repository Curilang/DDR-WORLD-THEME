-- Player combo/default.lua
-- Unifica 1000_combo, 0100_combo, 0010_combo, 0001_combo y label en un solo archivo.

local args = ...
if type(args) ~= "table" then args = nil end
local player = (args and args.Player) or Var "Player"
local isCopy = args ~= nil and args.Copy == true
local engineHidden = false
local ShowComboAt  = THEME:GetMetric("Combo", "ShowComboAt");
local Pulse        = THEME:GetMetric("Combo", "PulseCommand");
local PulseLabel   = THEME:GetMetric("Combo", "PulseLabelCommand");
local NumberZoom   = THEME:GetMetric("Combo", "NumberZoom");
local LabelZoom    = THEME:GetMetric("Combo", "LabelZoom");
local NumberCommand = THEME:GetMetric("Combo", "NumberCommand");
local LabelCommand  = cmd(horizalign,right;vertalign,bottom;xy,52,6);

local xxState;

-- Un actor por cada estado de juicio (mismos nombres que antes: W1..W4 y Normal)
local Keys = { "W1", "W2", "W3", "W4", "Normal" };

-- Fuente base por estado (el sufijo _w / _c depende del dígito)
local FontBase = {
	W1 = "marv", W2 = "perf", W3 = "great", W4 = "good", Normal = "marv",
};

-- Un dígito por entrada.
--   Divisor : 1000 / 100 / 10 / 1 para extraer el dígito
--   Min     : combo mínimo para mostrarlo
--   Suffix  : sufijo de la fuente (las unidades usan _w, el resto _c)
--   Pos     : { combo mínimo, x, y }; se aplica la última fila que cumpla
local Digits = {
	{ Name = "D1000", Divisor = 1000, Min = 1000, Suffix = "c",
	  Pos = { {1000, -43, -6} } },
	{ Name = "D0100", Divisor = 100,  Min = 100,  Suffix = "c",
	  Pos = { {100, -29, -8}, {1000, -8, -12} } },
	{ Name = "D0010", Divisor = 10,   Min = 10,   Suffix = "c",
	  Pos = { {10, -6, -13}, {100, 5.5, -14.5}, {1000, 26, -18} } },
	{ Name = "D0001", Divisor = 1,    Min = 0,    Suffix = "w",
	  Pos = { {0, 8, -15}, {10, 28, -19}, {100, 40, -21}, {1000, 59, -25} } },
};

-- Muestra solo el hijo `name` de la tabla `children` (nil = ocultar todos)
local function showOnly(children, name)
	for key, a in pairs(children) do
		a:visible(key == name);
	end
end

local function makeDigit(d)
	local frame = Def.ActorFrame{ Name = d.Name };
	for _, key in ipairs(Keys) do
		frame[#frame+1] = Def.BitmapText{
			Name = "Number" .. key,
			Font = "combo " .. FontBase[key] .. "_" .. d.Suffix,
			OnCommand = NumberCommand,
		};
	end
	return frame;
end

local function makeLabel()
	local frame = Def.ActorFrame{ Name = "LabelFrame" };
	local states = { W1 = 0, W2 = 1, W3 = 2, W4 = 3, Normal = 0 };
	for _, key in ipairs(Keys) do
		local state = states[key];
		frame[#frame+1] = Def.Sprite{
			Name = "Label" .. key,
			Texture = "combo",
			InitCommand = function(s) s:pause():setstate(state) end,
			OnCommand = LabelCommand,
		};
	end
	return frame;
end

local digitChildren = {};  -- digitChildren[i] = hijos del dígito i
local labelChildren;

local t = Def.ActorFrame{};
for _, d in ipairs(Digits) do
	t[#t+1] = makeDigit(d);
end
t[#t+1] = makeLabel();

t.InitCommand = function(self)
	for i, d in ipairs(Digits) do
		digitChildren[i] = self:GetChild(d.Name):GetChildren();
		showOnly(digitChildren[i], nil);
	end
	labelChildren = self:GetChild("LabelFrame"):GetChildren();
	showOnly(labelChildren, nil);
	-- LOW: el combo del motor se oculta y lo dibuja la copia del underlay
	if not isCopy and POMenu and POMenu.ComboHigh and not POMenu.ComboHigh(player) then
		engineHidden = true
		self:visible(false)
	end
end;

local function hideAll()
	for i = 1, #Digits do
		showOnly(digitChildren[i], nil);
	end
	showOnly(labelChildren, nil);
end

local function render(self, param)
	local iCombo = param.Combo;
	if not xxState or param.Misses or not iCombo or iCombo < ShowComboAt then
		hideAll();
		return;
	end

	param.Zoom = NumberZoom;
	param.LabelZoom = LabelZoom;

	-- Números
	local Number = xxState.Number;
	for i, d in ipairs(Digits) do
		local children = digitChildren[i];
		showOnly(children, Number);
		local actor = children[Number];
		actor:stoptweening();

		if iCombo >= d.Min then
			actor:visible(true);
			actor:settext(string.format("%d", math.floor(iCombo / d.Divisor) % 10));
			for _, p in ipairs(d.Pos) do
				if iCombo >= p[1] then actor:xy(p[2], p[3]) end
			end
			Pulse(actor, param);
		else
			actor:visible(false);
		end
	end

	-- Label
	local Label = xxState.Label;
	showOnly(labelChildren, Label);
	PulseLabel(labelChildren[Label], param);
end;

if isCopy then
	-- la copia del underlay no recibe ComboCommand del motor: lo recibe por relevo
	t.ComboRelayMessageCommand = function(self, p)
		if p.Player == player then render(self, p.Param) end
	end;
else
	t.ComboCommand = function(self, param)
		if engineHidden then
			MESSAGEMAN:Broadcast("ComboRelay", { Player = player, Param = param })
		else
			render(self, param)
		end
	end;
end

t.AfterStatsEngineMessageCommand = function(s, param)
	if param.Player ~= player then return end;
	xxState = param.Data.XXComboState;
end;

return t;
