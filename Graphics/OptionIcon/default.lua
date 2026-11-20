local pn = ...
local player = ToEnumShortString(pn)

return Def.ActorFrame {
	Def.Sprite{
		Texture=THEME:GetPathG("","OptionIcon/base"),
	};
	
	Def.ActorFrame{
		InitCommand=function(s) s:zoom(0.9) end,
		-- Risky
		Def.Sprite {
			InitCommand=function(self)
				self:xy(-15,-36)
				if table.search(GAMESTATE:GetPlayerState(pn):GetPlayerOptionsArray("ModsLevel_Preferred"), '4Lives') then			
					self:Load(THEME:GetPathG("","OptionIcon/Gauge/life4.png"));
				elseif table.search(GAMESTATE:GetPlayerState(pn):GetPlayerOptionsArray("ModsLevel_Preferred"), '1Lives') then			
					self:Load(THEME:GetPathG("","OptionIcon/Gauge/risky.png"));                                			
				end;
			end;
			PlayerJoinedMessageCommand=function(self, params)
				if params.Player == pn then
					self:playcommand("Init");
				end;
			end;
		};
		-- FLARE gauge (same slot as Risky; see Scripts/08 FlareGauge.lua)
		FlareGauge.IconActor(pn)..{ },
		-- Turn
		Def.Sprite {
			InitCommand=function(self)
				self:xy(13,-36)
				if GAMESTATE:GetPlayerState(pn):GetPlayerOptions('ModsLevel_Current'):Mirror() then
					self:Load(THEME:GetPathG("","OptionIcon/Turn/Mirror.png"));
				elseif GAMESTATE:GetPlayerState(pn):GetPlayerOptions('ModsLevel_Current'):Left() then
					self:Load(THEME:GetPathG("","OptionIcon/Turn/Left.png"));
				elseif GAMESTATE:GetPlayerState(pn):GetPlayerOptions('ModsLevel_Current'):Right() then
					self:Load(THEME:GetPathG("","OptionIcon/Turn/Right.png"));
				elseif GAMESTATE:GetPlayerState(pn):GetPlayerOptions('ModsLevel_Current'):Shuffle() then
					self:Load(THEME:GetPathG("","OptionIcon/Turn/Shuffle.png"));
				end;
			end;
			PlayerJoinedMessageCommand=function(self, params)
				if params.Player == pn then
					self:playcommand("Init");
				end;
			end;
		};
		-- Boost
		Def.Sprite {
			InitCommand=function(self)
				self:xy(-15,-8)
				if GAMESTATE:GetPlayerState(pn):GetPlayerOptions('ModsLevel_Current'):Boost() == 1 then
					self:Load(THEME:GetPathG("","OptionIcon/Boost/Boost.png"));
				elseif GAMESTATE:GetPlayerState(pn):GetPlayerOptions('ModsLevel_Current'):Brake() == 1 then
					self:Load(THEME:GetPathG("","OptionIcon/Boost/Brake.png"));
				elseif GAMESTATE:GetPlayerState(pn):GetPlayerOptions('ModsLevel_Current'):Wave() == 1 then
					self:Load(THEME:GetPathG("","OptionIcon/Boost/Wave.png"));
				end;
			end;
			PlayerJoinedMessageCommand=function(self, params)
				if params.Player == pn then
					self:playcommand("Init");
				end;
			end;
		};
		-- Scroll
		Def.Sprite {
			InitCommand=function(self)
				self:xy(13,-8)
				if IsReverse(pn) then
					self:Load(THEME:GetPathG("","OptionIcon/Scroll/Reverse.png"));
				end;
			end;
			PlayerJoinedMessageCommand=function(self, params)
				if params.Player == pn then
					self:playcommand("Init");
				end;
			end;
		};
		-- Cut
		Def.Sprite {
			InitCommand=function(self)
				self:xy(-15,20)
				if GAMESTATE:GetPlayerState(pn):GetPlayerOptions('ModsLevel_Current'):Little() then
					self:Load(THEME:GetPathG("","OptionIcon/Cut/On1.png"));
				end;
			end;
			PlayerJoinedMessageCommand=function(self, params)
				if params.Player == pn then
					self:playcommand("Init");
				end;
			end;
		};
		-- Freeze arrow
		Def.Sprite {
			InitCommand=function(self)
				self:xy(13,20)
				if GAMESTATE:GetPlayerState(pn):GetPlayerOptions('ModsLevel_Current'):NoHolds() then
					self:Load(THEME:GetPathG("","OptionIcon/Freeze/Off.png"));
				end;
			end;
			PlayerJoinedMessageCommand=function(self, params)
				if params.Player == pn then
					self:playcommand("Init");
				end;
			end;
		};
	-- Jump
	Def.Sprite {
		InitCommand=function(self)
			self:xy(-15,48)
			if GAMESTATE:GetPlayerState(pn):GetPlayerOptions('ModsLevel_Current'):NoJumps() then
				self:Load(THEME:GetPathG("","OptionIcon/Jump/Off.png"));
			end;
		end;
		PlayerJoinedMessageCommand=function(self, params)
			if params.Player == pn then
				self:playcommand("Init");
			end;
		end;
	};
	-- Speed
	Def.ActorFrame{
		InitCommand=function(s) s:xy(13,48) end,
		PlayerJoinedMessageCommand=function(self, params)
			if params.Player == pn then
				self:playcommand("On");
			end;
		end;
		CodeMessageCommand=function(self, params)
			if params.PlayerNumber == pn then
				self:queuecommand("On");
			end;
		end;
		-- Def.Sprite{ Texture= "Speed", };
		-- Def.BitmapText{
			-- Font="OptionIcon Speed",
			-- OnCommand=function(self)
				-- self:xy(1,4):zoom(0.667):maxwidth(34)
				-- local speed = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Current"):ScrollSpeed();
				-- self:settext(string.format("x%g", speed))
			-- end;	
		-- };
	};
	
	-- -- Appearance
	-- Def.Sprite {
		-- InitCommand=function(self)
			-- self:x(-119);
			-- local PlayerUID = PROFILEMAN:GetProfile(pn):GetGUID()
			-- local MyValue = ReadOrCreateAppearancePlusValueForPlayer(PlayerUID,MyValue);
			-- if MyValue == "Visible" then
				-- self:Load(THEME:GetPathG("","OptionIcon/Off.png"));
			-- elseif MyValue == "Hidden" then
				-- self:Load(THEME:GetPathG("","OptionIcon/Appearance/Hidden.png"));
			-- elseif MyValue == "Sudden" then
				-- self:Load(THEME:GetPathG("","OptionIcon/Appearance/Sudden.png"));
			-- elseif MyValue == "Stealth" then
				-- self:Load(THEME:GetPathG("","OptionIcon/Appearance/Stealth.png"));
			-- elseif MyValue == "Hidden+" then
				-- self:Load(THEME:GetPathG("","OptionIcon/Appearance/HiddenPlus.png"));
			-- elseif MyValue == "Sudden+" then
				-- self:Load(THEME:GetPathG("","OptionIcon/Appearance/SuddenPlus.png"));
			-- elseif MyValue == "Hidden+&Sudden+" then
				-- self:Load(THEME:GetPathG("","OptionIcon/Appearance/HiddenSuddenPlus.png"));
			-- end;
		-- end;
		-- PlayerJoinedMessageCommand=function(self, params)
			-- if params.Player == pn then
				-- self:playcommand("Init");
			-- end;
		-- end;
	-- };
	
	-- -- Dark
	-- Def.Sprite {
		-- InitCommand=function(self)
			-- self:x(-51);
			-- if GAMESTATE:GetPlayerState(pn):GetPlayerOptions('ModsLevel_Current'):Dark() == 1 then
				-- self:Load(THEME:GetPathG("","OptionIcon/Dark/Off.png"));
			-- end;
		-- end;
		-- PlayerJoinedMessageCommand=function(self, params)
			-- if params.Player == pn then
				-- self:playcommand("Init");
			-- end;
		-- end;
	-- };
	
	-- -- Arrow
	-- Def.Sprite {
		-- InitCommand=function(self)
			-- self:x(16);
			-- if not GAMESTATE:IsDemonstration() then
				-- if string.find(GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred"):NoteSkin(),"flat") then
					-- self:Load(THEME:GetPathG("","OptionIcon/Arrow/Flat"));
				-- elseif string.find(GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred"):NoteSkin(),"note") then
					-- self:Load(THEME:GetPathG("","OptionIcon/Arrow/Note"));
				-- elseif string.find(GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred"):NoteSkin(),"vivid") then
					-- self:Load(THEME:GetPathG("","OptionIcon/Arrow/Vivid"));
				-- elseif string.find(GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred"):NoteSkin(),"smnote") then
					-- self:Load(THEME:GetPathG("","OptionIcon/Arrow/SMNote"));
				-- end;
			-- end
		-- end;
		-- PlayerJoinedMessageCommand=function(self, params)
			-- if params.Player == pn then
				-- self:playcommand("Init");
			-- end;
		-- end;
	-- };
	};
};