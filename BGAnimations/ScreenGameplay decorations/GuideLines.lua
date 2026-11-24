local pn = ...
local MAX_LINES = 80
local active = false

local function FieldX()
    if PREFSMAN:GetPreference('Center1Player') and GAMESTATE:GetNumPlayersEnabled() == 1 and GAMESTATE:GetNumSidesJoined() == 1 then
        return _screen.cx
    elseif GAMESTATE:GetCurrentStyle():GetStepsType() == 'StepsType_Dance_Double' then
        return _screen.cx
    end
    return pn == PLAYER_1 and ScreenGameplay_P1X()-1 or ScreenGameplay_P2X()+1
end

local function FieldWidth()
    return GAMESTATE:GetCurrentStyle(pn):ColumnsPerPlayer() * 64
end

---------------------------------------------------------------
-- #TIMESIGNATURES:; on .sm or .ssc file.
---------------------------------------------------------------
local function ReadFile(path)
    if not path or path == "" then return nil end
    local f = RageFileUtil.CreateRageFile()
    if not f:Open(path, 1) then f:destroy() return nil end
    local s = f:Read()
    f:Close(); f:destroy()
    return s
end

local function StripComments(s)
    return (s:gsub("//[^\r\n]*", ""))
end

local function NormType(s)
    s = (s or ""):lower():gsub("^stepstype_", ""):gsub("_", "-")
    return s
end

local function Tag(block, name)
    local v = block:match("#"..name..":(.-);")
    return v and v:gsub("^%s+", ""):gsub("%s+$", "") or nil
end

local function ParseSigs(str)
    local out = {}
    if not str then return out end
    for entry in str:gmatch("[^,]+") do
        local b, n, d = entry:match("^%s*([%-%d%.]+)%s*=%s*(%d+)%s*=%s*(%d+)")
        b, n, d = tonumber(b), tonumber(n), tonumber(d)
        if b and n and d and n > 0 and d > 0 then
            out[#out+1] = {beat=b, num=n, den=d}
        end
    end
    table.sort(out, function(a,b) return a.beat < b.beat end)
    return out
end

local function GetTimeSignatures(song, steps)
    local text = ReadFile(song:GetSongFilePath())
    if not text then return {} end
    text = StripComments(text)

    local headerEnd = text:find("#NOTEDATA", 1, true)
    local header = headerEnd and text:sub(1, headerEnd-1) or text
    local sigStr = Tag(header, "TIMESIGNATURES")

    -- chart-level (.ssc)
    if headerEnd then
        local wantType = NormType(ToEnumShortString and steps:GetStepsType() or "")
        local wantDiff = ToEnumShortString(steps:GetDifficulty()):lower()
        local wantDesc = steps:GetDescription() or ""
        local wantMeter = tostring(steps:GetMeter())
        local pos = headerEnd
        while pos do
            local nxt = text:find("#NOTEDATA", pos + 1, true)
            local block = text:sub(pos, (nxt or #text+1) - 1)
            local bt = NormType(Tag(block, "STEPSTYPE"))
            local bd = (Tag(block, "DIFFICULTY") or ""):lower()
            local bdesc = Tag(block, "DESCRIPTION") or ""
            local bm = Tag(block, "METER")
            local ok = (bt == wantType) and (bd == wantDiff)
            if ok and wantDiff == "edit" then ok = (bdesc == wantDesc) end
            if ok and bm and tonumber(bm) and tostring(tonumber(bm)) ~= wantMeter then ok = false end
            if ok then
                local chartSig = Tag(block, "TIMESIGNATURES")
                if chartSig then sigStr = chartSig end
                break
            end
            pos = nxt
        end
    end

    return ParseSigs(sigStr)
end

-- Unidad (en beats) de cada línea según el denominador. Por defecto 4/den (norma de StepMania);
-- aquí van las excepciones que usan los charts. Con den=2 las líneas van cada medio beat.
local DENOM_UNIT = { [2] = 0.5 }

local function BuildLines(sigs, lastBeat)
    if #sigs == 0 or sigs[1].beat > 0 then
        table.insert(sigs, 1, {beat=0, num=4, den=4})
    end
    local out = {}
    for i, s in ipairs(sigs) do
        local e = sigs[i+1] and sigs[i+1].beat or (lastBeat + 8)
        local unit = DENOM_UNIT[s.den] or (4 / s.den)
        local k = 0
        while true do
            local t = s.beat + k * unit
            if t >= e - 1e-4 then break end
            out[#out+1] = {beat=t, measure=(k % s.num == 0)}
            k = k + 1
        end
    end
    return out
end

---------------------------------------------------------------
-- Y
---------------------------------------------------------------
local recStd = THEME:GetMetric("Player","ReceptorArrowsYStandard")
local recRev = THEME:GetMetric("Player","ReceptorArrowsYReverse")

local mode = "Off"
local lines, idx = {}, 1
local quads, lastShown = {}, 0
local C = {}
local BORDER_OFFSET = -32          -- BORDER choice

local function Update()
    if not active then return end
    local pos = C.fromPlayer and C.ps:GetSongPosition() or GAMESTATE:GetSongPosition()
    local curBeat = C.useVisible and pos:GetSongBeatVisible() or pos:GetSongBeat()

    local po    = C.po
    local scale = 64 * (po:XMod() or 1)
    local rev   = po:Reverse()
    local dir   = 1 - 2*rev
    local base  = C.y0 + recStd + (recRev - recStd)*rev + C.off

    -- first line
    while idx > 1 and lines[idx-1].beat >= curBeat - 1 do idx = idx - 1 end
    while idx < #lines and lines[idx].beat < curBeat - 1 do idx = idx + 1 end

    local n = 0
    for i = 0, MAX_LINES-1 do
        local ln = lines[idx + i]
        if not ln then break end
        local px = (ln.beat - curBeat) * scale
        if px > SCREEN_HEIGHT * 1.2 then break end      -- out of screen
        n = n + 1
        local q = quads[n]
        q.a:y(base + dir*px)
        if q.measure ~= ln.measure then
            q.measure = ln.measure
            q.a:zoomtoheight(ln.measure and 2 or 1):diffusealpha(ln.measure and 1 or 0.25)
        end
    end
    for j = lastShown+1, n do quads[j].a:visible(true) end
    for j = n+1, lastShown do quads[j].a:visible(false) end
    lastShown = n
end

local af = Def.ActorFrame{
    InitCommand=function(self)
        self:visible(false):diffusealpha(0)
    end,
    OnCommand=function(self)
        mode = GuideLinesMode(pn)
        if mode == "Off" then return end
        local song  = GAMESTATE:GetCurrentSong()
        local steps = GAMESTATE:GetCurrentSteps(pn)
        if song and steps then
            local td = steps:GetTimingData()
            local endBeat = math.max(song:GetLastBeat(),
                td:GetBeatFromElapsedTime(song:MusicLengthSeconds()))
            lines = BuildLines(GetTimeSignatures(song, steps), endBeat)
        end
        self:sleep(BeginReadyDelay()+SongMeasureSec()-0.3):queuecommand("Start")
    end,
    StartCommand=function(self)
        local scr = SCREENMAN:GetTopScreen()
        local pl  = scr and scr:GetChild("Player"..ToEnumShortString(pn))
        if not (pl and #lines > 0) then return end

        local ps  = GAMESTATE:GetPlayerState(pn)
        local pos = (ps.GetSongPosition and ps:GetSongPosition()) or GAMESTATE:GetSongPosition()
        C.ps, C.po = ps, ps:GetCurrentPlayerOptions()
        C.fromPlayer = ps.GetSongPosition ~= nil
        C.useVisible = pos.GetSongBeatVisible ~= nil
        C.y0  = pl:GetY()
        C.off = (mode == "Border") and BORDER_OFFSET or 0

        local x, w = FieldX(), FieldWidth()
        for i = 1, MAX_LINES do
            quads[i].a:x(x):zoomtowidth(w)
            quads[i].measure = nil
        end
        idx, lastShown = 1, 0
        active = true
        self:SetUpdateFunction(Update)
        self:sleep(0.37):decelerate(0.2):visible(true):diffusealpha(1)
    end,
    OffCommand=function(self)
        if mode == "Off" then return end
        local song = GAMESTATE:GetCurrentSong()
        if song and GAMESTATE:GetSongBeat() >= song:GetLastBeat() then
            self:queuecommand("Out")
        end
    end,
    OutCommand=function(self)
        active = false
        self:decelerate(0.2):diffusealpha(0)
    end,
}

for i = 1, MAX_LINES do
    af[#af+1] = Def.Quad{
        InitCommand=function(s) s:visible(false); quads[i] = {a = s} end,
    }
end

return af