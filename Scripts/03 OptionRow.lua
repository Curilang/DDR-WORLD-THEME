function OptionRowComboUnderField()
	local t = {
		Name = "ComboUnderField";
		LayoutType = "ShowAllInRow";
		SelectType = "SelectOne";
		OneChoiceForAllPlayers = true;
		ExportOnChange = true;
		Choices = {"Background", "Foreground", };
		LoadSelections = function(self, list, pn)
			if ReadPrefFromFile("OptionRowComboUnderField") ~= nil then
				if GetUserPref("OptionRowComboUnderField")=='true' then
					list[1] = true
				elseif GetUserPref("OptionRowComboUnderField")=='false'then
					list[2] = true
				else
					list[1] = true
				end
			else
				WritePrefToFile("OptionRowComboUnderField",true);
				list[1] = true;
			end;
		end;
		SaveSelections = function(self, list, pn)
			if list[1] then
				WritePrefToFile("OptionRowComboUnderField",true);
			elseif list[2] then
				WritePrefToFile("OptionRowComboUnderField",false);
			else
				WritePrefToFile("OptionRowComboUnderField",true);
			end;
			THEME:ReloadMetrics();
		end;
	};
	setmetatable( t, t );
	return t;
end

function OptionRowScreenFilter()
    local choices = {}
    for i = 0, 10 do
        table.insert(choices, string.format("%.1f", i/10))
    end

    local t = {
        Name = "ScreenFilter",
        LayoutType = "ShowAllInRow",
        SelectType = "SelectOne",
        OneChoiceForAllPlayers = false,
        ExportOnChange = true,
        Choices = choices,

        LoadSelections = function(self, list, pn)
            local pName = ToEnumShortString(pn)
            local pref = GetUserPref("OptionRowScreenFilter"..pName) or "0"
            
            local found = false
            for i, v in ipairs(self.Choices) do
                if v == pref then
                    list[i] = true
                    found = true
                    break
                end
            end
            
            if not found then
                list[1] = true -- default 0
            end
        end,

        SaveSelections = function(self, list, pn)
            local pName = ToEnumShortString(pn)
            for i, v in ipairs(self.Choices) do
                if list[i] then
                    SetUserPref("OptionRowScreenFilter"..pName, v)
                    return
                end
            end
            SetUserPref("OptionRowScreenFilter"..pName, "1")
        end,
    }

    setmetatable(t, t)
    return t
end

function FilterReadPref(pn)
    local pName = ToEnumShortString(pn)
    local val = GetUserPref("OptionRowScreenFilter"..pName)
    if val == nil then
        return "0.3"
    end
    return val
end

--Code by Midflight Digital
function OptionRowGauge()
	local t = {
		Name="Gauge",
		LayoutType = "ShowAllInRow",
		SelectType = "SelectOne",
		OneChoiceForAllPlayers = false,
		ExportOnChange = true,
		Choices = {"NORMAL", "LIFE4", "RISKY"};
		LoadSelections = function(self, list, pn)
			local po = GAMESTATE:GetPlayerState(pn):GetPlayerOptionsArray("ModsLevel_Preferred")
				if table.search(po, "4Lives") then
					list[2] = true
				elseif table.search(po, "1Lives") then
					list[3] = true
				else
					list[1] = true
				end
		end,
		SaveSelections = function(self, list, pn)
			local mod
			if list[2] then
				mod = "4 lives,battery,failimmediate"
			elseif list[3] then
				mod = "1 lives,battery,failimmediate"
			else
				mod = "bar,failimmediate"
			end
			if mod ~= "" then
				GAMESTATE:ApplyPreferredModifiers(pn, mod)
			end
		end,
	};
	setmetatable(t, t);
	return t;
end

--Code by Midflight Digital

function OptionRowSpeedX()
    -- Configuración base: misma que en tu pantalla principal
    local SPEED_MIN, SPEED_STEP, SPEED_MAX = 0.25, 0.05, 10
    local speeds = {}

    -- Generar lista desde x0.25 a x10.00 (en pasos de 0.05)
    for i = SPEED_MIN, SPEED_MAX + 0.001, SPEED_STEP do
        table.insert(speeds, string.format("x%.2f", i))
    end

    return {
        Name = "Speed",
        LayoutType = "ShowAllInRow",
        SelectType = "SelectOne",
        OneChoiceForAllPlayers = false,
        ExportOnChange = true,
        Choices = speeds,

        LoadSelections = function(self, list, pn)
			local target = tostring(math.floor(GetRealSpeed(pn) / 10 + 0.5) * 10)
			for i, v in ipairs(rs_values) do
				if v == target then list[i] = true; break end
			end
		end;

		SaveSelections = function(self, list, pn)
			for i, v in ipairs(rs_values) do
				if list[i] then SetRealSpeed(pn, tonumber(v)); break end
			end
		end;
    }
end

function OptionRowRealSpeed()
	local RS_MIN, RS_STEP, RS_MAX = 10, 10, 2000
	local rs_values = {}

	for i = RS_MIN, RS_MAX, RS_STEP do
		table.insert(rs_values, tostring(i))
	end

	local t = {
		Name = "Speed";
		LayoutType = "ShowAllInRow";
		SelectType = "SelectOne";
		OneChoiceForAllPlayers = false;
		ExportOnChange = true;
		Choices = rs_values;

		-- La velocidad vive en 03 SpeedPrefs.lua (por perfil); aqui solo se lee y se escribe con sus funciones.
		LoadSelections = function(self, list, pn)
			local target = tostring(math.floor(GetRealSpeed(pn) / 10 + 0.5) * 10)
			for i, v in ipairs(rs_values) do
				if v == target then
					list[i] = true
					return
				end
			end
			list[12] = true   -- 120
		end;

		SaveSelections = function(self, list, pn)
			for i, v in ipairs(rs_values) do
				if list[i] then
					SetRealSpeed(pn, tonumber(v))
					break
				end
			end
		end;
	}
	setmetatable(t, t)
	return t
end
