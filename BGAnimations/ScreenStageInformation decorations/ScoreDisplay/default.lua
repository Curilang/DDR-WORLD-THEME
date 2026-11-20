local t = Def.ActorFrame{};
local SleepOffset = 0.3;
local cx = 640
local ox = 450

function StageTopRecord(pn) --�^�ǳ̰��������Ӭ���
	local SongOrCourse, StepsOrTrail;
	local myScoreSet = {
		["HasScore"] = 0;
		["SongOrCourse"] =0;
		["topscore"] = 0;
		["topW1"]=0;
		["topW2"]=0;
		["topW3"]=0;
		["topW4"]=0;
		["topW5"]=0;
		["topMiss"]=0;
		["topOK"]=0;
		["topEXScore"]=0;
		["topMAXCombo"]=0;
		["topDate"]=0;
		};
		
	if GAMESTATE:IsCourseMode() then
		SongOrCourse = GAMESTATE:GetCurrentCourse();
		StepsOrTrail = GAMESTATE:GetCurrentTrail(pn);
	else
		SongOrCourse = GAMESTATE:GetCurrentSong();
		StepsOrTrail = GAMESTATE:GetCurrentSteps(pn);
	end;

	local profile, scorelist;
	
	if SongOrCourse and StepsOrTrail then
		local st = StepsOrTrail:GetStepsType();
		local diff = StepsOrTrail:GetDifficulty();
		local courseType = GAMESTATE:IsCourseMode() and SongOrCourse:GetCourseType() or nil;

		if PROFILEMAN:IsPersistentProfile(pn) then
			-- player profile
			profile = PROFILEMAN:GetProfile(pn);
		else
			-- machine profile
			profile = PROFILEMAN:GetMachineProfile();
		end;

		scorelist = profile:GetHighScoreList(SongOrCourse,StepsOrTrail);
		assert(scorelist);
		local scores = scorelist:GetHighScores();
		assert(scores);
		if scores[1] then
			myScoreSet["SongOrCourse"]=1;
			myScoreSet["HasScore"] = 1;
			myScoreSet["topscore"] = scores[1]:GetScore();
			myScoreSet["topW1"]  = scores[1]:GetTapNoteScore("TapNoteScore_W1");
			myScoreSet["topW2"]  = scores[1]:GetTapNoteScore("TapNoteScore_W2");
			myScoreSet["topW3"]  = scores[1]:GetTapNoteScore("TapNoteScore_W3");
			myScoreSet["topW4"]  = scores[1]:GetTapNoteScore("TapNoteScore_W4");
			myScoreSet["topW5"]  = scores[1]:GetTapNoteScore("TapNoteScore_W5");
			myScoreSet["topMiss"]  = scores[1]:GetTapNoteScore("TapNoteScore_W5")+scores[1]:GetTapNoteScore("TapNoteScore_Miss");
			myScoreSet["topOK"]  = scores[1]:GetHoldNoteScore("HoldNoteScore_Held");
			--myScoreSet["topEXScore"]  = scores[1]:GetTapNoteScore("TapNoteScore_W1")*3+scores[1]:GetTapNoteScore("TapNoteScore_W2")*2+scores[1]:GetTapNoteScore("TapNoteScore_W3")+scores[1]:GetHoldNoteScore("HoldNoteScore_Held")*3;
			if (StepsOrTrail:GetRadarValues( pn ):GetValue( "RadarCategory_TapsAndHolds" ) >=0) then --If it is not a random course
				if scores[1]:GetGrade() ~= "Grade_Failed" then
					myScoreSet["topEXScore"] = scores[1]:GetTapNoteScore("TapNoteScore_W1")*3+scores[1]:GetTapNoteScore("TapNoteScore_W2")*2+scores[1]:GetTapNoteScore("TapNoteScore_W3")+scores[1]:GetHoldNoteScore("HoldNoteScore_Held")*3;
				else
					myScoreSet["topEXScore"] = (StepsOrTrail:GetRadarValues( pn ):GetValue( "RadarCategory_TapsAndHolds" )*3+StepsOrTrail:GetRadarValues( pn ):GetValue( "RadarCategory_Holds" )*3)*scores[1]:GetPercentDP();
				end
			else --If it is Random Course then the scores[1]:GetPercentDP() value will be -1
				if scores[1]:GetGrade() ~= "Grade_Failed" then
					myScoreSet["topEXScore"]  = scores[1]:GetTapNoteScore("TapNoteScore_W1")*3+scores[1]:GetTapNoteScore("TapNoteScore_W2")*2+scores[1]:GetTapNoteScore("TapNoteScore_W3")+scores[1]:GetHoldNoteScore("HoldNoteScore_Held")*3;
				else
					myScoreSet["topEXScore"]  = 0;
				end
			end
			myScoreSet["topMAXCombo"]  = scores[1]:GetMaxCombo();
			myScoreSet["topDate"]  = scores[1]:GetDate() ;
		else
			myScoreSet["SongOrCourse"]=1;
			myScoreSet["HasScore"] = 0;
		end;
	else
		myScoreSet["HasScore"] = 0;
		myScoreSet["SongOrCourse"]=0;
		
	end
	return myScoreSet;

end;

local diffData = {
    Beginner  = { spriteState = 0, x = 140, font = "diff_beginner" },
    Easy      = { spriteState = 1, x = 102, font = "diff_easy" },
    Medium    = { spriteState = 2, x = 128, font = "diff_medium" },
    Hard      = { spriteState = 3, x = 118, font = "diff_hard" },
    Challenge = { spriteState = 4, x = 148, font = "diff_challenge" },
    Edit      = { spriteState = 5, x = 154, font = "diff_edit" },
}

for _,pn in pairs(GAMESTATE:GetEnabledPlayers()) do
	local steps = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(pn) or GAMESTATE:GetCurrentSteps(pn)
    local shortDiff = ToEnumShortString(steps:GetDifficulty())
    local data = diffData[shortDiff]
	t[#t+1] = Def.ActorFrame{
		InitCommand=function(s) s:x(pn==PLAYER_1 and 0 or _screen.cx+140) end,
		Def.Sprite{
			Texture=GetLanguage().."tips",
			InitCommand=function(s) s:pause():zoom(0.667):xy(_screen.cx-292,_screen.cy-57) end,
			OnCommand=function(s)  local tips = math.random(1,3) local state = tips - 1
				s:setstate(state)
			end,
			};
		Def.BitmapText{
			Font="_arial black cont 28px",
			InitCommand=function(s) 
				s:uppercase(true):maxwidth(200):zoom(0.667)
				s:xy(pn==PLAYER_1 and 45 or 248.2,_screen.cy+80)
				s:horizalign(pn==PLAYER_1 and left or right)
				s:settext(string.upper(PROFILEMAN:GetPlayerName(pn))) 
			end,
		};
		Def.ActorFrame{
			InitCommand=function(s)
				-- P2: the block (label + number) is placed so that its right edge mirrors the left edge of P1's block.
				-- 54 px = frame of the number font, 15 px = its advance, 18.3 px = empty margin right of the last digit.
				local digits = #tostring(steps:GetMeter())
				local inkRight = data.x + 0.667*((digits/2 - 1)*15 + 54 - 18.3)
				s:x(pn==PLAYER_1 and 0 or (248.1 - inkRight))
			end,
			Def.Sprite{
				Texture=THEME:GetPathG("","_shared/diff"),
				InitCommand=function(s)
					s:xy(110,_screen.cy+103):zoom(0.667):pause()
					s:setstate(data.spriteState)
				end,
			},
			Def.BitmapText{
				Font=data.font,
				InitCommand=function(s)
					s:y(_screen.cy+102):zoom(0.667):settext(steps:GetMeter())
					s:x(data.x)
				end,
			},
		};
		
		Def.Sprite{
			Texture="best",
			InitCommand=function(s) s:xy(95,_screen.cy+126):zoom(0.667) end,
		};
		scstring="";
		Def.RollingNumbers{
			File = THEME:GetPathF("ScreenGameplay","score_on");
			InitCommand=function(s) s:xy(152,_screen.cy+164):zoom(0.667):maxwidth(240) end,
			OnCommand=function(self)
				self:Load("RollingNumbersSongData")
				myScoreSet = StageTopRecord(pn);
				if (myScoreSet["SongOrCourse"]==1) then
					if (myScoreSet["HasScore"]==1) then	
						local topscore = myScoreSet["topscore"]
						self:diffusealpha(1)
						self:targetnumber(topscore)
						scstring = topscore
					else
						self:diffusealpha(1)
						self:targetnumber(0)
						scstring = 0
					end
				else
					self:diffusealpha(0)
				end
			end;
		};
		Def.Sprite{
			Condition=ThemePrefs.Get("TargetScore") == "On";
			Texture="target",
			InitCommand=function(s) s:xy(95,_screen.cy+172):zoom(0.667) end,
		};
		Def.RollingNumbers{
			Condition=ThemePrefs.Get("TargetScore") == "On";
			File = THEME:GetPathF("ScreenStageInformation","TargetScore");
			OnCommand=function(s) s:xy(152,_screen.cy+210):zoom(0.667):maxwidth(240)
				s:Load("RollingNumbersSongData"):targetnumber(scstring)				
			end,
		};
	};
end;
	
return t;