local function GetSongPercent()
    local song = GAMESTATE:GetCurrentSong()
    if not song then return 0 end
    local songPos = GAMESTATE:GetSongPosition()
    if not songPos then return 0 end

    local musicLength = song:GetLastSecond() or 1
    local elapsed = songPos:GetMusicSeconds() or 0

    local percent = math.min(elapsed / musicLength, 1)
    return percent
end

local function GetStepsPercent()
    local song = GAMESTATE:GetCurrentSong()
    if not song then return 0 end

    local songPos = GAMESTATE:GetSongPosition()
    if not songPos then return 0 end

    local currentBeat = songPos:GetSongBeat() or 0
    local firstBeat = song:GetFirstBeat() or 0
    local lastBeat = song:GetLastBeat() or 1

    local percent = (currentBeat - firstBeat) / (lastBeat - firstBeat)
    percent = math.min(math.max(percent, 0), 1)

    return percent
end

return Def.ActorFrame{
    InitCommand=function(self) 
		self:xy(-147,0)
    end,

    Def.Quad{
        Name="ProgressBar",
        InitCommand=function(self)
            self:setsize(291,58)
            self:horizalign(left)
			if GAMESTATE:GetCurrentStyle():GetStepsType() == 'StepsType_Dance_Double' then
				self:diffuse(Color.Black)
			else	
				self:diffuse(Color.White)
			end
			self:diffusealpha(0.7)
        end,
        OnCommand=function(self)
            self:queuecommand("Update")
        end,
        UpdateCommand=function(self)
			local percent = ThemePrefs.Get("MeterBar") == "SongMeter" and GetSongPercent() or GetStepsPercent()
			local width = (SCREEN_WIDTH/4.38) * percent
    
    -- Animación suave hacia el nuevo ancho
			self:stoptweening()               -- cancela animaciones anteriores
			self:smooth(0.01)                 -- duración de la transición
			self:zoomx(percent)                 -- cambia el tamaño suavemente

			self:queuecommand("Update")       -- sigue actualizando
		end
    }
}
