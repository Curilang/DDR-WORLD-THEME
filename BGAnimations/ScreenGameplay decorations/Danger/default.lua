local pn = ({...})[1]

local Position
if PREFSMAN:GetPreference('Center1Player') and GAMESTATE:GetNumPlayersEnabled() == 1 and GAMESTATE:GetNumSidesJoined() == 1 then 
	Position = _screen.cx
elseif GAMESTATE:GetCurrentStyle():GetStepsType() == 'StepsType_Dance_Double' then
	Position = _screen.cx
else
	Position = pn == PLAYER_1 and ScreenGameplay_P1X()-1 or ScreenGameplay_P2X()+1
end

local filter
if GAMESTATE:GetCurrentStyle():GetStepsType() == 'StepsType_Dance_Double' then
	filter = "double"
else
	filter = "single"
end;

return Def.ActorFrame{
	Name="Danger";
	-- With a FLARE, danger is decided by the FLARE gauge (FlareDangerChanged), not by the engine.
	FlareDangerChangedMessageCommand=function(self, param)
		if param.Player == pn then
			self:RunCommandsOnChildren(cmd(playcommand, param.Danger and "Show" or "Hide"))
		end
	end;
	HealthStateChangedMessageCommand=function(self, param)
		if FlareGauge.StartLevel(pn) then return end
		if param.PlayerNumber == pn then
			if param.HealthState == "HealthState_Danger" then
				self:RunCommandsOnChildren(cmd(playcommand,"Show"))
			else
				self:RunCommandsOnChildren(cmd(playcommand,"Hide"))
			end
		end
	end;
	Def.Sprite {
		Texture=filter,
		InitCommand=function(s) s:xy(Position,_screen.cy):blend('BlendMode_Add'):diffusealpha(0)
			if GAMESTATE:GetCurrentStyle():GetStepsType() == 'StepsType_Dance_Double' then
				s:setsize(567,480)
			else
				s:setsize(287,480)
			end
		end,
		ShowCommand=function(s) s:diffusealpha(1) end,
		HideCommand=function(s) s:diffusealpha(0) end,
	};
};