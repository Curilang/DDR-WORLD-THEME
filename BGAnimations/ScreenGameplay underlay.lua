local t = Def.ActorFrame{}

local function GetSongVideo()
    local song = GAMESTATE:GetCurrentSong()
    if not song then return nil end

    local files = FILEMAN:GetDirListing(song:GetSongDir() .. "/")
    for _, file in ipairs(files) do
        if IsVideoFile(file) then
            return song:GetSongDir() .. "/" .. file
        end
    end
    return nil
end

local videoPath = GetSongVideo()
local enabledPlayers = GAMESTATE:GetEnabledPlayers()

local function GetVideoPosition()
    local style = GAMESTATE:GetCurrentStyle()
    local sizePref = ThemePrefs.Get("VideoSize")

    local w, h = 320, 180
    local x, y = _screen.cx, _screen.cy
	
	if PREFSMAN:GetPreference('Center1Player') and GAMESTATE:GetNumPlayersEnabled() == 1 and GAMESTATE:GetNumSidesJoined() == 1 then
		if sizePref == "Small" or sizePref == "Medium" then
			w, h = 195, 108
			y = _screen.cy
			x = enabledPlayers[1] == PLAYER_1 and _screen.cx + 286 or _screen.cx - 286
		end
	else

		if style:GetStepsType() == "StepsType_Dance_Double" then
			if sizePref == "Small" or sizePref == "Medium" then
				w, h = 144, 80

				if #enabledPlayers == 1 then
					local pn = enabledPlayers[1]
					x = pn == PLAYER_1 and SCREEN_RIGHT-72 or SCREEN_LEFT+72
				end
			end
		else
			if sizePref == "Small" then
				w, h = 195, 108
				y = _screen.cy + 128.5

			elseif sizePref == "Medium" then
				if style:GetStyleType() == "StyleType_TwoPlayersTwoSides" then
					w, h = 195, 108
					y = _screen.cy + 128.5
				else
					w, h = 513, 289

					if #enabledPlayers == 2 then
						x = _screen.cx
					else
						x = enabledPlayers[1] == PLAYER_1
							and _screen.cx + 166
							or _screen.cx - 166
					end
				end
			end
		end
	end
    return w, h, x, y
end

local sizePref = ThemePrefs.Get("VideoSize")

if sizePref == "Off" then
    PREFSMAN:SetPreference("SongBackgrounds", false)

elseif sizePref == "Small" or sizePref == "Medium" then
    PREFSMAN:SetPreference("SongBackgrounds", false)

    if videoPath and #enabledPlayers > 0 then
        local w, h, x, y = GetVideoPosition()

        t[#t+1] = Def.ActorFrame{
            InitCommand=function(s)
                s:xy(x, y)
            end,

            -- Fondo negro con tamaño fijo
            Def.Quad{
                InitCommand=function(s)
                    s:setsize(w, h)
                    s:diffuse(color("#000000"))
                end,
            },

            -- Video ajustado sin deformación
            Def.Sprite{
				Texture=videoPath,
				InitCommand=function(s)
					s:scaletofit(-w/2, -h/2, w/2, h/2)
				end,
				OnCommand=function(s)
					s:loop(0):sleep(SongMeasureSec())
				end,
			},
        }
    end

else
    PREFSMAN:SetPreference("SongBackgrounds", true)
end

return t