-- Base from CyberiaStyle 7 by gl_yukt
local st = GAMESTATE:GetCurrentStyle():GetStepsType();
local mStages = STATSMAN:GetStagesPlayed();
local i = 0;



local t = Def.ActorFrame{};

t[#t+1] = StandardDecorationFromFileOptional("Footer","Footer");

t[#t+1] = Def.ActorFrame {
	InitCommand=function(s) s:zoom(0.667):diffusealpha(0):xy(_screen.cx,_screen.t) end,
	OnCommand=function(s) s:sleep(0.1):linear(0.2):diffusealpha(1) end,
	OffCommand=function(s) s:linear(0.2):diffusealpha(0) end,
	Def.Sprite{
		Texture=THEME:GetPathB("ScreenEvaluation","decorations/RESULTS"),
		InitCommand=function(s) s:xy(1,60) end,
	};
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/tex"),
		InitCommand=function(s) s:xy(-496,58):pause():setstate(GetProjectName()) end,
	};
};  

t[#t+1] = Def.ActorFrame{
	BeginCommand=function(s)
		SOUND:PlayOnce(THEME:GetPathS("WORLD/Total Result","In"))
	end,
};

for i = 1, mStages do
	local sStats = STATSMAN:GetPlayedStageStats(i)
	local SpaceCommand=function(self) 
		self:addy(-130+((mStages-i)*(PREFSMAN:GetPreference("SongsPerPlay") == 5 and 74 or 87)))  
	end
	t[#t+1] = Def.ActorFrame{
		InitCommand=function(s) s:Center():zoom(0.667):diffusealpha(0) end,
		OnCommand=function(s) s:sleep(0.1):linear(0.2):diffusealpha(1) end,
		BeginCommand=SpaceCommand;
		OffCommand=function(s) s:linear(0.2):zoomy(0) end,
		Def.Quad {
			InitCommand=function(s) s:setsize(403,72):diffusealpha(0.85):xy(1,14.5) end,
		};
		LoadFont("_swis721 blk bt 28px")..{
			InitCommand=function(s) s:y(12):halign(0.5):maxwidth(280):diffuse(Color.Black) end,
			BeginCommand=function(s)
				local sssong = sStats:GetPlayedSongs()[1]
				s:settext(sssong:GetDisplayMainTitle())
			end,	
		};
		Def.Sprite{
			Texture="stage",
			InitCommand=function(s) s:y(-33):pause() end,
			BeginCommand=function(s)
				local stageState = {
					Stage_1st    = 0,
					Stage_2nd    = 1,
					Stage_3rd    = 2,
					Stage_4th    = 3,
					Stage_Final  = 4,
					Stage_Extra1 = 5,
					Stage_Extra2 = 6,
				}
				s:setstate(stageState[STATSMAN:GetPlayedStageStats(i):GetStage()])
			end,
		};
	};
	
	for pn in ivalues(PlayerNumber) do
		if GAMESTATE:IsPlayerEnabled(pn) == true then
			local pStats = sStats:GetPlayerStageStats(pn)
			t[#t+1] = Def.Banner {
				InitCommand=function(s) 
					s:x(pn==PLAYER_1 and _screen.cx-115 or _screen.cx+115)
					s:y(_screen.cy+10):diffusealpha(0)
					local sssong = sStats:GetPlayedSongs()[1]
					s:LoadSongImage(sssong, 32, 32)
				end,
				OnCommand=function(s) s:sleep(0.1):linear(0.2):diffusealpha(1) end,
				BeginCommand=SpaceCommand;
				OffCommand=function(s) s:linear(0.2):zoomy(0) end,
			};
			t[#t+1] = Def.ActorFrame {
				InitCommand=function(s) 
					s:x(pn==PLAYER_1 and _screen.cx-192.5 or _screen.cx+194)
					s:y(_screen.cy)
					s:zoom(0.667) 
					s:diffusealpha(0)
				end,
				OnCommand=function(s) 
					s:addx(pn==PLAYER_1 and -30 or 30)
					s:sleep(0.1):linear(0.2):addx(pn==PLAYER_1 and 30 or -30):diffusealpha(1) 
				end,
				BeginCommand=SpaceCommand;
				OffCommand=function(s) s:linear(0.2):zoomy(0) end,		
				Def.Sprite{
					Texture="style",
					InitCommand=function(s) s:xy(14,-28):pause():queuecommand("Set") end,
					SetCommand=function(s)
						local style = GAMESTATE:GetCurrentStyle():GetStyleType()
						s:setstate(style == "StyleType_OnePlayerTwoSides" and 1 or 0) 
					end,
				};
				Def.Sprite{
					Texture="chart",
					InitCommand=function(s) s:xy(0.5,8):pause() end,
					BeginCommand=function(s)
						local step = pStats:GetPlayedSteps()
						local diff = step[1]:GetDifficulty()
						local DiffState = {
							Difficulty_Beginner	= 0,
							Difficulty_Easy		= 1,
							Difficulty_Medium	= 2,
							Difficulty_Hard		= 3,
							Difficulty_Challenge= 4,
							Difficulty_Edit 	= 5,
						};
						s:setstate(DiffState[diff])
					end,
				};
				Def.Sprite{
					Texture="text",
					InitCommand=function(s) s:xy(pn==PLAYER_1 and -48 or 0,0):pause() end,
				};
				Def.Sprite {
					InitCommand=function(s) s:zoom(0.15):xy(pn==PLAYER_1 and 55 or -57,-4) end,
					BeginCommand=function(s) local Grade = pStats:GetGrade()
						s:LoadBackground(THEME:GetPathG("","Grade/Grade_"..ToEnumShortString(Grade)));	
					end;
				};
				Def.Sprite{
					InitCommand=function(s) s:xy(pn==PLAYER_1 and 54 or -56,15):zoom(0.8) end,
					BeginCommand=function(s)
						local grade = pStats:GetGrade()
						if grade ~= "Grade_Tier08" then
							if pStats:FullComboOfScore('TapNoteScore_W1') then
								s:Load(THEME:GetPathG("","_shared/cleared/MarvelousFullcombo"))
							elseif pStats:FullComboOfScore('TapNoteScore_W2') then
								s:Load(THEME:GetPathG("","_shared/cleared/PerfectFullcombo"))
							elseif pStats:FullComboOfScore('TapNoteScore_W3') then
								s:Load(THEME:GetPathG("","_shared/cleared/GreatFullcombo"))
							elseif pStats:FullComboOfScore('TapNoteScore_W4') then
								s:Load(THEME:GetPathG("","_shared/cleared/GoodFullcombo"))
							else
								if grade ~= "Grade_Failed" then
									local song = sStats:GetPlayedSongs()[1]
									local diff = pStats:GetPlayedSteps()[1]:GetDifficulty()
									local steps = song:GetOneSteps(st, diff)
									local profile = MachineOrProfile(pn)
									local scorelist = profile:GetHighScoreList(song, steps)
									local scores = scorelist:GetHighScores()
									local hasUsedBattery = false
									for _, score in ipairs(scores) do
										if score:GetScore() == pStats:GetScore() then
											hasUsedBattery = string.find(score:GetModifiers(), "Lives") ~= nil
											break
										end
									end
									if hasUsedBattery then
										s:Load(THEME:GetPathG("","_shared/cleared/Gauge"))
									else
										s:Load(THEME:GetPathG("","_shared/cleared/LifeBar"))
									end
								else
									s:visible(false)
								end
							end
						end
					end,
				};
				-- FLARE earned in this stage, under the clear mark. The textures are the music wheel's
				-- (Graphics/MusicWheelItem Song NormalPart/flare/flare_N.png): there is only one copy of them.
				Def.Sprite{
					InitCommand=function(s) s:xy(pn==PLAYER_1 and 55 or -55,35):zoom(1.09):visible(false) end,
					BeginCommand=function(s)
						local song = sStats:GetPlayedSongs()[1]
						local steps = pStats:GetPlayedSteps()[1]
						if not (song and steps) then return end
						-- this stage's position among the stages of the summary that had the same chart (stage "i" counts
						-- backwards: mStages is the first one played)
						local occurrence, total = 0, 0
						for j = mStages, 1, -1 do
							local other = STATSMAN:GetPlayedStageStats(j)
							local oSong = other:GetPlayedSongs()[1]
							local oSteps = other:GetPlayerStageStats(pn):GetPlayedSteps()[1]
							if oSong and oSteps and oSong:GetSongDir() == song:GetSongDir()
								and oSteps:GetDifficulty() == steps:GetDifficulty() then
								total = total + 1
								if j >= i then occurrence = occurrence + 1 end
							end
						end
						local level = FlareGauge.StageClear(pn, song, steps, occurrence, total)
						local f = level and FlareGauge.WheelFile("flare/flare_" .. level)
						if f then s:Load(f):visible(true) end
					end,
				};
				Def.RollingNumbers {
					File=THEME:GetPathF("EvaluationSummary","Score");
					InitCommand=function(s) s:Load("RollingNumbersScore")
						s:xy(pn==PLAYER_1 and 22 or 70,24):halign(1) 
					end,
					BeginCommand=function(s)
						local song = sStats:GetPlayedSongs()[1];
						local diff = pStats:GetPlayedSteps()[1]:GetDifficulty();
						local steps = song:GetOneSteps( st, diff );
						local radar = steps:GetRadarValues(pn);
						local maxsteps = math.max(radar:GetValue('RadarCategory_TapsAndHolds')+radar:GetValue('RadarCategory_Holds')+radar:GetValue('RadarCategory_Rolls'),1);			
						s:targetnumber(GetEvaScore(maxsteps,pStats,pn))
					end;
				};
				Def.BitmapText{
					Font="EvaluationSummary Score",
					InitCommand=function(s) s:xy(pn==PLAYER_1 and 22 or 70,54):halign(1) end,
					BeginCommand=function(s) s:settext("0") end,
				},
				Def.Sprite{
					Texture="new",
					InitCommand=function(s)
						s:xy(pn==PLAYER_1 and 16 or 63,-11.5)
						s:visible(pStats:GetPersonalHighScoreIndex() == 0)
					end,
					OnCommand=function(s)
						if pStats:GetPersonalHighScoreIndex() == 0 then
							s:queuecommand("Light")
						end
					end,
					LightCommand=function(s)
						s:diffuseshift():effectcolor1(color("#ffffff")):effectcolor2(color("#de2073")):effectperiod(0.4)
					end,
					OffCommand=function(s)
						s:stoptweening():linear(0.15):diffusealpha(0)
					end,
				},
			};
		end;
	end;
end;

for _,pn in pairs(GAMESTATE:GetEnabledPlayers()) do
	t[#t+1] = Def.ActorFrame{
		InitCommand=function(s) s:xy(pn==PLAYER_1 and _screen.cx-177 or _screen.cx+177,_screen.t+44):diffusealpha(0) end,
		OnCommand=function(s) s:sleep(0.1):linear(0.2):diffusealpha(1) end,
		OffCommand=function(s) s:linear(0.15):diffusealpha(0) end,
		Def.Sprite{
			Texture="Appeal",
			InitCommand=function(s) s:zoom(0.667) end,
		};
		Def.BitmapText{
			Font="_arial black cont 28px",
			InitCommand=function(s) 
				s:maxwidth(285):diffuse(color("#ffffff")):zoom(0.5):y(23):halign(0.5)
				if PROFILEMAN:GetNumLocalProfiles() >= 1 then
					s:settext(string.upper(PROFILEMAN:GetPlayerName(pn)))
				else
					s:settext(pn==PLAYER_1 and "PLAYER 1" or "PLAYER 2")
				end
			end,
		};
	};
end;

t[#t+1] = Def.ActorFrame{
	OffCommand=function(s)
		SOUND:PlayOnce(THEME:GetPathS("WORLD/Total Result","Out"))
	end,
};

-- the menu timer (Scripts/08 MenuTimer.lua)
t[#t+1] = DDRWORLD_MenuTimer("ScreenEvaluationSummary", MenuTimerPositions.Results.x, MenuTimerPositions.Results.y);

return t