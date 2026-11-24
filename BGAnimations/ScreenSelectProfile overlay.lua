local ProfileInfoCache = {}
setmetatable(ProfileInfoCache, {__index =
function(table, ind)
    local out = {}
    local prof = PROFILEMAN:GetLocalProfileFromIndex(ind-1)
    out.DisplayName = prof:GetDisplayName()
    out.UserTable = prof:GetUserTable()
    rawset(table, ind, out)
    return out
end
})

local function LoadCard(cColor,cColor2,pn,IsJoinFrame)
	local t = Def.ActorFrame {
		
		Def.ActorFrame{
			InitCommand=function(s) s:y(16):zoomy(0) end,
			OnCommand=function(s) s:linear(0.3):zoomy(IsJoinFrame and 1 or 0) end,
			OffCommand=function(s) s:sleep(IsJoinFrame and 0.1 or 0.3):linear(0.1):zoomy(0) end,
			
			LoadActor(THEME:GetPathG("","ScreenSelectProfile/BG01"))..{
				InitCommand=function(s) s:setsize(428,400) end,
			};
			
		};
		
		Def.ActorFrame{
			InitCommand=function(s) s:zoomy(0) end,
			OnCommand=function(s) s:linear(0.3):zoomy(IsJoinFrame and 0 or 1) end,
			OffCommand=function(s) s:diffusealpha(0) end,
			
			Def.Sprite{
				Texture=THEME:GetPathG("","ScreenSelectProfile/Appeal"),
				InitCommand=function(s) s:xy(_screen.cx-426,_screen.t-156) end,
			};
			LoadActor(THEME:GetPathG("","ScreenSelectProfile/BG02"))..{
				InitCommand=function(s) s:y(6) end,
			};
			LoadActor(THEME:GetPathG("","ScreenSelectProfile/rank"))..{
				InitCommand=function(s) s:xy(-11,2):pause():setstate(0) end,
			};
			Def.BitmapText{
				Font="rank_num",
				InitCommand=function(s) s:xy(132,20):settext("0"):diffuse(color("#7b7b7b")):halign(0.5) end,
			},
			Def.Sprite{
				Texture=THEME:GetPathG("","ScreenSelectProfile/rank"),
				InitCommand=function(s) s:xy(-11,43):pause():setstate(0) end,
			};
			Def.BitmapText{
				Font="rank_num",
				InitCommand=function(s) s:xy(132,63):settext("0"):diffuse(color("#7b7b7b")):halign(0.5) end,
			},
			LoadActor(THEME:GetPathG("","ScreenSelectProfile/league"))..{
				InitCommand=function(s) s:y(136):pause():setstate(0) end,
			};
			
		};
		Def.ActorFrame{
			InitCommand=function(s) s:y(-232):zoomy(0) end,
			OnCommand=function(s) s:linear(0.3):zoomy(1) end,
			OffCommand=function(s) s:sleep(IsJoinFrame and 0.1 or 0.3):linear(0.1):zoomy(0) end,
			
			Def.Sprite{
				Texture=THEME:GetPathG("","ScreenSelectProfile/top"),
				InitCommand=function(s) s:setsize(428,80) end,			
			};
			Def.Sprite{
				Texture=THEME:GetPathG("","ScreenSelectProfile/PLAYER"),
				InitCommand=function(s) s:xy(-108,-26):pause():setstate(pn==PLAYER_1 and 0 or 1):valign(0)  end,
			};
			Def.Sprite{
				Texture=THEME:GetPathG("","ScreenSelectProfile/profile"),
				InitCommand=function(s) s:xy(-49,4):valign(0):pause():setstate(GetCurrentLanguage()) end,
			};
		};
};

	return t
end

function LoadPlayerStuff(pn)
	local t = Def.ActorFrame {
		--No Player yet
		Def.ActorFrame {
			Condition=not IsDataSaveSummary();
			Name = 'JoinFrame';
			LoadCard(Color('Outline'),color('0,0,0,0'),pn,true);
			LoadActor( THEME:GetPathG("","ScreenSelectProfile/press") ) .. {
				InitCommand=cmd(zoomy,0;diffuseshift;effectcolor1,Color('White');effectcolor2,color("#A5A6A5"));
				OnCommand=cmd(x,2;y,11;sleep,0.5;linear,0.1;zoomy,1);
				OffCommand=function(s) s:linear(0.1):zoomy(0):diffusealpha(0) end,
			};
		};
		--Player
		Def.ActorFrame {
			Name = 'BigFrame';
			LoadCard(PlayerColor(),color('1,1,1,1'),pn,false);
		};
		Def.BitmapText{
			Name = 'ProfileText';
			Font="_arial black cont 28px",
			InitCommand=function(s) 
				s:uppercase(true)
				s:xy(-205,-145):halign(0)
				s:maxwidth(245)
				s:shadowlength(2) 
			end,
			OnCommand=function(s) s:diffusealpha(0):sleep(0.87):linear(0.3):diffusealpha(1) end,
			OffCommand=function(s) s:diffusealpha(0) end,
		};
		Def.BitmapText{
			Name = 'RegionText';
			Font="_arial black cont 28px",
			InitCommand=function(s) 
				s:uppercase(true)
				s:zoom(0.5)
				s:xy(202,-148):halign(1)
				s:maxwidth(245)
				s:shadowlength(2) 
			end,
			OnCommand=function(s) s:diffusealpha(0):sleep(0.87):linear(0.3):diffusealpha(1) end,
			OffCommand=function(s) s:diffusealpha(0) end,
		};
	};
	return t;
end

local function UpdateInternal3(self, Player)
	local pn = (Player == PLAYER_1) and 1 or 2;
	local frame = self:GetChild(string.format('P%uFrame', pn));
	local ProfileText = frame:GetChild('ProfileText');
	local RegionText = frame:GetChild('RegionText');
	local joinframe = frame:GetChild('JoinFrame');
	local bigframe = frame:GetChild('BigFrame');
	
	if GAMESTATE:IsHumanPlayer(Player) then
		frame:visible(true);
		if MEMCARDMAN:GetCardState(Player) == 'MemoryCardState_none' then
			joinframe:visible(false);
			bigframe:visible(false);
			ProfileText:visible(true);
			RegionText:visible(true);

			local ind = SCREENMAN:GetTopScreen():GetProfileIndex(Player);
			if ind > 0 then
				local profile = PROFILEMAN:GetLocalProfileFromIndex(ind-1);

				bigframe:visible(true);
				ProfileText:settext(ProfileInfoCache[ind].DisplayName);
				RegionText:settext(ThemePrefs.Get("RegionP"..pn));

				local profileID = PROFILEMAN:GetLocalProfileIDFromIndex(ind-1)
				local prefs = ProfilePrefs.Read(profileID)
				if SN3Debug then
					ProfilePrefs.Save(profileID)
				end

			else
				if SCREENMAN:GetTopScreen():SetProfileIndex(Player, 1) then
					bigframe:visible(false);
					self:queuecommand('UpdateInternal2');
				else
					joinframe:visible(false);
					bigframe:visible(false);
					ProfileText:settext('No profile');
					RegionText:settext(ThemePrefs.Get("RegionP"..pn));
				end;
			end;
		else
			--using card
			ProfileText:settext('CARD');
			RegionText:settext(ThemePrefs.Get("RegionP"..pn));
			SCREENMAN:GetTopScreen():SetProfileIndex(Player, 0);
		end;
	else
		joinframe:visible(true);
		ProfileText:visible(false);
		RegionText:visible(false);
		bigframe:visible(false);
	end;
end;

local screen = Var("LoadingScreen")
local t = Def.ActorFrame {
	StorageDevicesChangedMessageCommand=function(self, params)
		self:queuecommand('UpdateInternal2');
	end;

	CodeMessageCommand = function(self, params)
		if params.Name == 'Start' or params.Name == 'Center' then
			MESSAGEMAN:Broadcast("StartButton");
			if not GAMESTATE:IsHumanPlayer(params.PlayerNumber) then
				SCREENMAN:GetTopScreen():SetProfileIndex(params.PlayerNumber, -1);
			else
				SCREENMAN:GetTopScreen():Finish();
			end;
		end;
		if params.Name == 'Up' or params.Name == 'Up2' or params.Name == 'DownLeft' then
			if GAMESTATE:IsHumanPlayer(params.PlayerNumber) then
				local ind = SCREENMAN:GetTopScreen():GetProfileIndex(params.PlayerNumber);
				if ind > 1 then
					if SCREENMAN:GetTopScreen():SetProfileIndex(params.PlayerNumber, ind - 1 ) then
						MESSAGEMAN:Broadcast("DirectionButton");
						self:queuecommand('UpdateInternal2');
					end;
				end;
			end;
		end;
		if params.Name == 'Down' or params.Name == 'Down2' or params.Name == 'DownRight' then
			if GAMESTATE:IsHumanPlayer(params.PlayerNumber) then
				local ind = SCREENMAN:GetTopScreen():GetProfileIndex(params.PlayerNumber);
				if ind > 0 then
					if SCREENMAN:GetTopScreen():SetProfileIndex(params.PlayerNumber, ind + 1 ) then
						MESSAGEMAN:Broadcast("DirectionButton");
						self:queuecommand('UpdateInternal2');
					end;
				end;
			end;
		end;
		if params.Name == 'Back' then
			if GAMESTATE:GetNumPlayersEnabled()==0 then
				SCREENMAN:GetTopScreen():Cancel();
			else
				MESSAGEMAN:Broadcast("BackButton");
				SCREENMAN:GetTopScreen():SetProfileIndex(params.PlayerNumber, -2);
			end;
		end;
	end;

	PlayerJoinedMessageCommand=function(self, params)
		self:queuecommand('UpdateInternal2');
	end;

	PlayerUnjoinedMessageCommand=function(self, params)
		self:queuecommand('UpdateInternal2');
	end;

	OnCommand=function(self, params)
		self:queuecommand('UpdateInternal2');
	end;

	UpdateInternal2Command=function(self)
		UpdateInternal3(self, PLAYER_1);
		UpdateInternal3(self, PLAYER_2);
	end;

	children = {
		Def.ActorFrame {
			Name = 'P1Frame';
			InitCommand=cmd(x,SCREEN_CENTER_X-146;y,SCREEN_CENTER_Y+9;zoom,0.667);
			OffCommand=cmd();
			PlayerJoinedMessageCommand=function(self,param)
				if param.Player == PLAYER_1 then
					(cmd(zoomx,0.667;zoomy,0.15;linear,0.175;zoomy,0.667;))(self);
				end;
			end;
			children = LoadPlayerStuff(PLAYER_1);
		};
		Def.ActorFrame {
			Name = 'P2Frame';
			InitCommand=cmd(x,SCREEN_CENTER_X+146;y,SCREEN_CENTER_Y+9;zoom,0.667);
			OffCommand=cmd();
			PlayerJoinedMessageCommand=function(self,param)
				if param.Player == PLAYER_2 then
					(cmd(zoomx,0.667;zoomy,0.15;linear,0.175;zoomy,0.667;))(self);
				end;
			end;
			children = LoadPlayerStuff(PLAYER_2);
		};
		-- sounds
		LoadActor( THEME:GetPathS("Common","start") )..{
			StartButtonMessageCommand=cmd(play);
		};
		LoadActor( THEME:GetPathS("WORLD/Screen", "Out") )..{
			StartButtonMessageCommand=cmd(play);
		};
		LoadActor( THEME:GetPathS("Common","cancel") )..{
			BackButtonMessageCommand=cmd(play);
		};
		LoadActor( THEME:GetPathS("ScreenOptions","change") )..{
			DirectionButtonMessageCommand=cmd(play);
		};
	};
};

return Def.ActorFrame{
	StandardDecorationFromFileOptional("Footer", "Footer");
	GetSoftwareVersion();
	Def.Sprite {
		Texture=THEME:GetPathG("","_shared/tex"),
		InitCommand=function(s) s:zoom(0.667):xy(_screen.l+96,_screen.t+39):pause():setstate(GetProjectName()) end, 
	};
	Def.Sound{
		File=THEME:GetPathS("WORLD/Profile", "in"),
		OnCommand=function(s) s:play() end,
	};
	t;
	-- the menu timer (Scripts/08 MenuTimer.lua), on top of the cards; the same place for both players
	DDRWORLD_MenuTimerPerPlayer("ScreenSelectProfile", MenuTimerPositions.Profile, MenuTimerPositions.ProfileP2);
}
