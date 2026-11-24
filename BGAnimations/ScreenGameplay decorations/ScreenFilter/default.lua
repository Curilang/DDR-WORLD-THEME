local pn = ({...})[1]
local ScreenFilter = GAMESTATE:IsDemonstration() and 0.3 or FilterReadPref(pn);

local style = GAMESTATE:GetCurrentStyle():GetStepsType() == 'StepsType_Dance_Double' and "Double" or "Single"

local Position
if PREFSMAN:GetPreference('Center1Player') and GAMESTATE:GetNumPlayersEnabled() == 1 and GAMESTATE:GetNumSidesJoined() == 1 then 
	Position = _screen.cx
elseif GAMESTATE:GetCurrentStyle():GetStepsType() == 'StepsType_Dance_Double' then
	Position = _screen.cx
else
	Position = pn == PLAYER_1 and ScreenGameplay_P1X()-1 or ScreenGameplay_P2X()+1
end

return Def.ActorFrame {
	InitCommand=function(s) s:xy(Position,_screen.cy):diffusealpha(0) end,
	CurrentSongChangedMessageCommand=function(s) 
		s:sleep(BeginReadyDelay()+SongMeasureSec())
		s:decelerate(0.2)
		s:diffusealpha(ScreenFilter) 
	end,
	ChangeCourseSongInMessageCommand=function(s) s:playcommand('FilterOff') end,
	OffCommand=function(s) 
		if (GAMESTATE:GetSongBeat() >= GAMESTATE:GetCurrentSong():GetLastBeat()) then 
			s:decelerate(0.2):diffusealpha(0)
		end
	end,
	Def.Sprite { 
		Texture=style,
		InitCommand=function(s) s:zoom(0.667) end,
	};
};