-- (the wheel sound is played by BGAnimations/ScreenSelectMusic overlay/LevelSort.lua, once per change of the cursor)

local function WheelMove(mov)
    local mw = SCREENMAN:GetTopScreen():GetChild("MusicWheel")
    mw:Move(mov)
end

-- Registrar ambos tipos de botones
local pressed = {
    MenuDown=false, MenuLeft=false, MenuRight=false,
    Down=false, Left=false, Right=false
}

local function InputHandler(event)
    local player = event.PlayerNumber
    local MusicWheel = SCREENMAN:GetTopScreen("ScreenSelectMusic"):GetChild("MusicWheel")
    if event.type == "InputEventType_Release" then
        pressed[event.GameButton] = false
        return false
    end

    -- Marcar botones presionados
    pressed[event.GameButton] = true

    -- 🔹 Detectar combinaciones híbridas (pad o menú)
    local downHeld = pressed["MenuDown"] or pressed["Down"]
    local leftHeld = pressed["MenuLeft"] or pressed["Left"]
    local rightHeld = pressed["MenuRight"] or pressed["Right"]

    local currentStyle = GAMESTATE:GetCurrentStyle():GetName()
    
    -- Bloquear Versus
    if currentStyle ~= "versus" then
        if downHeld and rightHeld and currentStyle ~= "double" then
            setenv("ForceStyle", "double")
            --SOUND:PlayOnce(THEME:GetPathS("", "change"))
            SCREENMAN:SetNewScreen("ScreenSelectMusic")
            return
        elseif downHeld and leftHeld and currentStyle ~= "single" then
            setenv("ForceStyle", "single")
            --SOUND:PlayOnce(THEME:GetPathS("", "change"))
            SCREENMAN:SetNewScreen("ScreenSelectMusic")
            return
        end
    end

    if WheelButtons and (event.GameButton == "MenuUp" or event.GameButton == "MenuDown") then WheelButtons.Hold = nil end

    -- 🔹 LEFT / RIGHT on the header (the two buttons): from one button to the other before leaving it (Scripts/08 WheelButtons.lua).
    -- The engine moves the wheel on its own; SideStep makes that step bring the cursor back to the header.
    if MusicWheel ~= nil and WheelButtons and WheelButtons.SideStep and player ~= nil
            and (event.GameButton == "MenuLeft" or event.GameButton == "MenuRight") then
        WheelButtons.TraceSide("event " .. tostring(event.type) .. " " .. tostring(event.GameButton), MusicWheel)
    end
    if MusicWheel ~= nil and WheelButtons and WheelButtons.SideStep and event.type == "InputEventType_FirstPress"
            and player ~= nil and GAMESTATE:IsPlayerEnabled(player)
            and (event.GameButton == "MenuLeft" or event.GameButton == "MenuRight") then
        local dir = (event.GameButton == "MenuLeft") and -1 or 1
        local otherHeld = (dir < 0 and rightHeld) or (dir > 0 and leftHeld)   -- LEFT + RIGHT together is the filter menu
        if not otherHeld then WheelButtons.SideStep(MusicWheel, dir) end
    end

    -- 🔹 Movimientos de MusicWheel (tu código original)
    if MusicWheel ~= nil then
        -- (LEFT / RIGHT: the engine already plays the wheel sound on every step; playing it here as well doubled it)
        if event.GameButton == "MenuDown" and GAMESTATE:IsPlayerEnabled(player) and PREFSMAN:GetPreference("OnlyDedicatedMenuButtons") then
            -- from the last row of songs DOWN goes to the two buttons (Scripts/08 WheelButtons.lua)
            local toHeader = MusicWheel:GetSelectedType() == 'WheelItemDataType_Song' and WheelButtons and WheelButtons.ToHeader(1)
            if toHeader then
                WheelMove(toHeader)
            elseif MusicWheel:GetSelectedType() == 'WheelItemDataType_Song' then
                WheelMove(3)
                if MusicWheel:GetSelectedType() ~= 'WheelItemDataType_Song' then
                    WheelMove(-2)
                    if MusicWheel:GetSelectedType() == "WheelItemDataType_Song" then
                        WheelMove(2)
                        if MusicWheel:GetSelectedType() ~= "WheelItemDataType_Song" then
                            WheelMove(-1)
                            if MusicWheel:GetSelectedType() == "WheelItemDataType_Song" then
                                WheelMove(1)
                            end
                        end
                    end
                end
            else
                -- on the header (the two buttons) DOWN goes from FOLDER to FILTER first (Scripts/08 WheelButtons.lua)
                if not (WheelButtons and WheelButtons.Step(MusicWheel, 1)) then MusicWheel:Move(1) end
            end
            MusicWheel:Move(0)
        end
        if event.GameButton == "MenuUp" and GAMESTATE:IsPlayerEnabled(player) and PREFSMAN:GetPreference("OnlyDedicatedMenuButtons") then
            -- from the first row of songs UP goes to the two buttons
            local toHeader = MusicWheel:GetSelectedType() == 'WheelItemDataType_Song' and WheelButtons and WheelButtons.ToHeader(-1)
            if toHeader then
                WheelMove(toHeader)
            elseif MusicWheel:GetSelectedType() == 'WheelItemDataType_Song' then
                WheelMove(-3)
                if MusicWheel:GetSelectedType() ~= 'WheelItemDataType_Song' then
                    WheelMove(2)
                    if MusicWheel:GetSelectedType() == "WheelItemDataType_Song" then
                        WheelMove(-2)
                        if MusicWheel:GetSelectedType() ~= "WheelItemDataType_Song" then
                            WheelMove(1)
                            if MusicWheel:GetSelectedType() == "WheelItemDataType_Song" then
                                WheelMove(-1)
                            end
                        end
                    end
                end
            else
                -- on the header UP goes from FILTER to FOLDER first
                if not (WheelButtons and WheelButtons.Step(MusicWheel, -1)) then WheelMove(-1) end
            end
            WheelMove(0)
        end
    end
end

-- 🔹 ActorFrame
return Def.ActorFrame{
    OnCommand=function(self) SCREENMAN:GetTopScreen():AddInputCallback(InputHandler) end;
    OffCommand=function(self) SCREENMAN:GetTopScreen():RemoveInputCallback(InputHandler) end,
    SongChosenMessageCommand=function(self) self:playcommand("Off") end;
    SongUnchosenMessageCommand=function(self)
        self:sleep(0.5):queuecommand("On");
    end;
};
