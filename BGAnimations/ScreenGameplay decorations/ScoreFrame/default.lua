local yval = SCREEN_BOTTOM-38
local t = Def.ActorFrame{
    CurrentSongChangedMessageCommand=function(s) s:queuecommand("Set") end,
};	

t[#t+1] = Def.ActorFrame{
	Condition=(not GAMESTATE:IsDemonstration());
	InitCommand=function(s) s:xy(_screen.cx+1,yval):zoom(0.67):draworder(99) end,		
	LoadActor("SongMeter")..{
	Condition=ThemePrefs.Get("MeterBar") ~= "Off";
	};
	Def.Quad{
        InitCommand=function(self) self:setsize(291,58):x(SCREEN_LEFT-1.5)
			if GAMESTATE:GetCurrentStyle():GetStepsType() == 'StepsType_Dance_Double' then
				self:diffuse(color("#000000"))	
			else	
				self:diffuse(color("#ffffff"))
			end
			self:diffusealpha(ThemePrefs.Get("MeterBar") == "Off" and 0.75 or 0.45)
		end,
	};
	Def.BitmapText{
		Font="_swis721 blk bt 28px",
		InitCommand=function(s) s:zoom(0.5):halign(0):maxwidth(470):xy(-94,-6)
			if GAMESTATE:GetCurrentStyle():GetStepsType() == 'StepsType_Dance_Double' then
				s:diffuse(color("#ffffff"))
			else
				s:diffuse(color("#000000"))
			end 
		end,
		CurrentSongChangedMessageCommand=function(s)
			local song = GAMESTATE:GetCurrentSong()
			if song then
				s:settext(song:GetDisplayMainTitle())
			end
		end,
	};
	Def.BitmapText{
		Font="_swis721 blk bt 28px",
		InitCommand=function(s) s:zoom(0.38):halign(0):maxwidth(620):xy(-94,10)
			if GAMESTATE:GetCurrentStyle():GetStepsType() == 'StepsType_Dance_Double' then
				s:diffuse(color("#ffffff"))
			else
				s:diffuse(color("#000000"))
			end
		end,
		CurrentSongChangedMessageCommand=function(s)
			local song = GAMESTATE:GetCurrentSong()
			if song then
				s:settext(GetArtistName(song))
			end
		end,
	};
	Def.Sprite{
		InitCommand=function(s) s:x(-117):draworder(99) end,
		CurrentSongChangedMessageCommand=function(s)
			s:LoadSongImage(GetSong(), 40, 40)
		end,
	};
};

--Players
for _,pn in pairs(GAMESTATE:GetEnabledPlayers()) do
   local diff = {
		["Beginner"] 	= "diff_beginner",
		["Easy"] 		= "diff_easy",
		["Medium"] 		= "diff_medium",
		["Hard"] 		= "diff_hard",
		["Challenge"] 	= "diff_challenge",
		["Edit"] 		= "diff_edit",
	};
	local steps = GAMESTATE:GetCurrentSteps(pn):GetDifficulty(); 

   t[#t+1] = Def.ActorFrame{
		InitCommand=function(s) 
			s:xy(pn==PLAYER_1 and SCREEN_LEFT+128 or SCREEN_RIGHT-250,144)
			s:draworder(10):zoom(0.67)
		end,
		Def.ActorFrame{
            InitCommand=function(s) 
				s:y(IsReverse(pn) and SCREEN_TOP-148 or (yval-33))
			end,
				Def.BitmapText{
					Font="_arial black cont 28px",
					InitCommand=function(s) 
						s:zoom(0.72):maxwidth(180):horizalign(left)
						s:xy(125,3):diffuse(color("#FFFFFF"))
						s:settext(string.upper(PROFILEMAN:GetPlayerName(pn)))
					end,
				};
				Def.ActorFrame{
				InitCommand=function(self)
					self:xy(-41,4)
				end;
				Def.Sprite{
					Texture=THEME:GetPathG("","_shared/diff"),
					Name="Diff Label",
					InitCommand=function(s) s:x(85):zoom(0.8):pause()
						local diff = {
							["Beginner"] 	= 0,
							["Easy"] 		= 1,
							["Medium"] 		= 2,
							["Hard"] 		= 3,
							["Challenge"] 	= 4,
							["Edit"] 		= 5,
						};
						local steps = GAMESTATE:GetCurrentSteps(pn):GetDifficulty();
						s:setstate(diff[ToEnumShortString(steps)]) end,
					CurrentSongChangedMessageCommand=function(s) s:queuecommand("Init") end,
				};
				Def.BitmapText{
					Font=diff[ToEnumShortString(steps)],
					Name = "Difficulty Meter";
					InitCommand=function(s) s:zoom(0.667) 
						local steps;
					if GAMESTATE:IsCourseMode() then
						steps = ToEnumShortString(GAMESTATE:GetCurrentTrail(pn):GetDifficulty());
					else
						steps = ToEnumShortString(GAMESTATE:GetCurrentSteps(pn):GetDifficulty());
					end
					local diff = {
							["Beginner"] = 130,
							["Easy"] = 80,
							["Medium"] = 110,
							["Hard"] = 95,
							["Challenge"] = 130,
							["Edit"] = 136,
						};
						s:x(diff[steps])
					end,
					SetCommand=function(s)
						local meter = GAMESTATE:GetCurrentSteps(pn):GetMeter()
						if meter % 1 == 0 then
							s:settext(meter)
						else
							s:settext(string.format("%.1f", meter))
						end
					end;
					CurrentSongChangedMessageCommand=function(s) s:queuecommand("Set") end,
				};
			};
		};
		Def.ActorFrame{
			InitCommand=function(s) s:xy(80,yval+30) end,
			LoadActor("score_counter",pn);
			Def.Sprite{
				Texture="score.png",
				InitCommand=function(s) s:xy(10,8)end,
			};
		};
		-- Def.Sprite{
			-- Texture=THEME:GetPathG("","_shared/EX"),
			-- InitCommand=function(s) s:xy(-83,yval+1):visible(IsEXScore()) end,
		-- };
		Def.ActorFrame{
			InitCommand=function(s) s:xy(pn==PLAYER_1 and 265 or -82,yval-5) end,
			Def.Sprite{
				Texture="bpm_base",
			};
			LoadActor("BPMDisplay",pn)..{
				InitCommand=function(s) s:y(-2) end,
			};
		};	
	};
end

return t;