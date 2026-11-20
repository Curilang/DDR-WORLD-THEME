local t = Def.ActorFrame{ 
	StandardDecorationFromFileOptional("Footer","Footer");
};

local StageIndex = GAMESTATE:GetCurrentStageIndex()
local FinalStage = PREFSMAN:GetPreference("SongsPerPlay")

t[#t+1] = Def.ActorFrame{
	OffCommand=function(s) s:linear(0.15):diffusealpha(0) end,
	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/ddr"),
		InitCommand=function(s) s:zoom(0.667):xy(SCREEN_LEFT+96,_screen.t+39) end,
	};
	Def.Sprite{
		Texture="RESULTS",
		InitCommand=function(s) s:zoom(0.667):xy(_screen.cx,_screen.t+32) end,
	};
	Def.Sprite{
		Texture="stage",
		InitCommand=function(s) s:zoom(0.667):xy(_screen.cx,_screen.t+58):pause():queuecommand("Set") end,
		SetCommand=function(s) 
			if PREFSMAN:GetPreference("EventMode") then
				if GAMESTATE:IsCourseMode() then
					s:setstate(8)
				else
					s:setstate(7)
				end
			elseif GAMESTATE:IsCourseMode() then 
				s:setstate(8)
				--Final
			elseif GAMESTATE:GetCurrentStageIndex() == PREFSMAN:GetPreference("SongsPerPlay") then
				s:setstate(4)
				--Extra1
			elseif GAMESTATE:GetCurrentStageIndex() == PREFSMAN:GetPreference("SongsPerPlay")+1 then
				s:setstate(5)
				--Extra2
			elseif GAMESTATE:GetCurrentStageIndex() == PREFSMAN:GetPreference("SongsPerPlay")+2 then
				s:setstate(6)
			else
				if GAMESTATE:GetCurrentStageIndex() == 1 then
					s:setstate(0)
				elseif GAMESTATE:GetCurrentStageIndex() == 2 then
					s:setstate(1)
				elseif GAMESTATE:GetCurrentStageIndex() == 3 then
					s:setstate(2)
				elseif GAMESTATE:GetCurrentStageIndex() == 4 then
					s:setstate(3)
				end;
			end;
		end,
	};
};

t[#t+1] = Def.ActorFrame{
	OffCommand=function(s) s:linear(0.15):diffusealpha(0) end,
    Name="Jacket";
	Def.Sprite{
		Texture="base",
		InitCommand=function(s) s:setsize(149,189):xy(_screen.cx,_screen.cy-77) end,
	};
	Def.Sprite{
		Texture="rocket",
		InitCommand=function(s) s:zoom(0.667):xy(_screen.cx+64,_screen.cy+5) end,
	};
	Def.Sprite {
		OnCommand=function(s)
		local song; if GAMESTATE:IsCourseMode() then song = GAMESTATE:GetCurrentCourse() else song = GAMESTATE:GetCurrentSong(); end
			if GAMESTATE:IsCourseMode() then
                s:Load(song:GetBannerPath()):zoomto(290,52):xy(_screen.cx+3,_screen.cy-114)
			else	
				s:LoadSongImage(song, 141, 141):xy(_screen.cx,_screen.cy-97)
			end
		end;
	};
	Def.BitmapText{
        Font="_swis721 blk bt 28px",
        InitCommand=function(s) s:xy(_screen.cx-70,_screen.cy-8):maxwidth(310):zoom(0.4):halign(0)
            local song = GAMESTATE:GetCurrentSong()
            local course = GAMESTATE:GetCurrentCourse()
            if GAMESTATE:IsCourseMode() then
                s:settext(GAMESTATE:GetCurrentCourse() and GAMESTATE:GetCurrentCourse():GetDisplayFullTitle() or "")
			else
				s:settext(song:GetDisplayMainTitle())
			end
        end,
    };		
    Def.BitmapText{
        Font="_swis721 blk bt 28px",
        InitCommand=function(s) s:xy(_screen.cx-70,_screen.cy+6):wrapwidthpixels(650):zoom(0.2):halign(0)
            local song = GAMESTATE:GetCurrentSong()
			if not GAMESTATE:IsCourseMode() then
                s:settext(GetArtistName(song))
            end
        end,
    };	
};

local st = STATSMAN:GetCurStageStats()
local pss_p1 = st:GetPlayerStageStats(PLAYER_1)
local pss_p2 = st:GetPlayerStageStats(PLAYER_2)
t[#t+1] = Def.ActorFrame{
	Condition=pss_p1:GetScore() > 0 or pss_p2:GetScore() > 0;
	BeginCommand=function(s) s:queuecommand("Play") end,
	PlayCommand=function(s) 
		local sound = THEME:GetPathS("WORLD/Evaluation","score")
		SOUND:PlayOnce(StreamingSound(sound)) 
	end,
};
	

for _,pn in pairs(GAMESTATE:GetEnabledPlayers()) do
	t[#t+1] = Def.ActorFrame{ 
		InitCommand=function(s) s:x(pn==PLAYER_1 and 0 or 384) end,
		OffCommand=function(s) s:linear(0.15):diffusealpha(0) end,
		Name="Player",
		Def.Sprite{
			Texture="Appeal",
			InitCommand=function(s) s:zoom(0.667):y(_screen.t+47.5)
				s:x(_screen.cx-192)
			end,
		};
		Def.BitmapText{
			Font="_arial black cont 28px",
			InitCommand=function(s) 
				s:maxwidth(285):diffuse(color("#ffffff")):zoom(0.5):y(_screen.t+70)
				s:x(_screen.cx-195)
				--s:horizalign(right)
				if PROFILEMAN:GetNumLocalProfiles() >= 1 then
					s:settext(string.upper(PROFILEMAN:GetPlayerName(pn)))
				else
					s:settext(pn==PLAYER_1 and "PLAYER 1" or "PLAYER 2")
				end
			end,
        };
		Def.Quad{
			InitCommand=function(s) 
				s:diffuse(color("#00000")):diffusealpha(0.3):setsize(148.2,24)
				s:xy(_screen.cx-192,_screen.t+90) 
			end,
		};
		Def.Sprite{
			Texture="style",
			InitCommand=function(s) s:zoom(0.667):xy(_screen.cx-238, _screen.t+90):pause():queuecommand("Set") end,
			SetCommand=function(s) s:setstate(GAMESTATE:GetCurrentStyle()== "StyleType_OnePlayerTwoSides" and 1 or 0) end,
		},
		Def.Sprite{
			Texture="diff",
			InitCommand=function(s) s:zoom(0.7):xy(_screen.cx-179, _screen.t+90):pause():queuecommand("Set") end,
			SetCommand=function(s)
				local steps = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(pn) or GAMESTATE:GetCurrentSteps(pn)
				local diff = steps and ToEnumShortString(steps:GetDifficulty()) or "Beginner"
				local idx = {Beginner=0,Easy=1,Medium=2,Hard=3,Challenge=4,Edit=5}
					s:setstate(idx[diff] or 0)
			end,
		},
		Def.BitmapText{
			Font="eval_diff",
            InitCommand=function(s) s:zoom(0.285):y(_screen.t+92)
                local steps = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(pn) or GAMESTATE:GetCurrentSteps(pn)
				local meter = steps:GetMeter();
				local shortDiff = ToEnumShortString(steps:GetDifficulty())
				local diffData = {
					Beginner  = { x = 136 },
					Easy      = { x = 169 },
					Medium    = { x = 146 },
					Hard      = { x = 157 },
					Challenge = { x = 136 },
					Edit      = { x = 136 },
				}
				local data = diffData[shortDiff]
				s:x(_screen.cx-data.x)
				if meter ~= 0 then
					s:settext(meter)
				end
			end,
        };
	};
	t[#t+1] = LoadActor("Grade",pn)..{
		OffCommand=function(s) s:linear(0.15):diffusealpha(0) end,
	}
	local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(pn)
	
	t[#t+1] = Def.RollingNumbers{
            File="eval_score",
            InitCommand=function(s) 
				s:zoom(0.667)
				s:xy(pn==PLAYER_1 and _screen.cx-180 or _screen.cx+200,_screen.cy+15)
				s:playcommand("Set") 
			end,
            OffCommand=function(s) s:linear(0.15):diffusealpha(0) end,
            SetCommand=function(s)
            local score
				if IsEXScore() then
					score = (pss:GetPossibleDancePoints())*(pss:GetPercentDancePoints());
				else 
					score = pss:GetScore();
				end;
			    s:Load("RollingNumbersEvaluation"):targetnumber(score);
            end,
		};
	
	if pss:GetPersonalHighScoreIndex() == 0 then
		t[#t+1] = Def.Sprite{
			Texture="RECORD",
			InitCommand=function(s) s:zoom(0.667):xy(pn==PLAYER_1 and _screen.cx-138 or _screen.cx+246,_screen.cy+34) end,
			OnCommand=function(s) s:queuecommand("Light") end,
			LightCommand=function(s) s:diffusealpha(1):linear(1):diffusealpha(0.4):linear(1):diffusealpha(1):queuecommand("Light") end,
			OffCommand=function(s) s:stoptweening():linear(0.15):diffusealpha(0) end,
		};
	end

	-- if not ((StageIndex == FinalStage+1) or (StageIndex == FinalStage+2)) then
		-- t[#t+1] = Def.ActorFrame{
			-- Condition=not GAMESTATE:IsEventMode();
			-- InitCommand=function(s) s:zoom(0.667)
				-- s:xy(pn == PLAYER_1 and _screen.cx-33 or _screen.cx+33,_screen.cy+27) 
			-- end,
			-- OffCommand=function(s) s:linear(0.05):diffusealpha(0) end,
			-- Def.Sprite{
				-- Texture="Three_stars_on",
			-- };
			-- Def.Sprite{
				-- Texture="Got Extra Stars",
				-- InitCommand=function(s) s:y(22) end,
			-- };
		-- };
	-- end;
end;

if #GAMESTATE:GetEnabledPlayers() == 1 then
	t[#t+1] = LoadActor("frame", GAMESTATE:GetMasterPlayerNumber(),PLAYER_1,(GAMESTATE:GetMasterPlayerNumber() ~= PLAYER_1))..{
		InitCommand=cmd(xy,_screen.cx-172,_screen.cy+115;zoom,0.667);
	};
	t[#t+1] = LoadActor("frame", GAMESTATE:GetMasterPlayerNumber(),PLAYER_2,(GAMESTATE:GetMasterPlayerNumber() ~= PLAYER_2))..{
		InitCommand=cmd(xy,_screen.cx+172,_screen.cy+115;zoom,0.667);
	};
else
	t[#t+1] = LoadActor("frame", PLAYER_1,PLAYER_1,false)..{
		InitCommand=cmd(xy,_screen.cx-172,_screen.cy+115;zoom,0.667);
	};
	t[#t+1] = LoadActor("frame", PLAYER_2,PLAYER_2,false)..{
		InitCommand=cmd(xy,_screen.cx+172,_screen.cy+115;zoom,0.667);
	};
end

-- if not ((StageIndex == FinalStage+1) or (StageIndex == FinalStage+2)) then
	-- t[#t+1] = Def.Sprite{
		-- Condition=not GAMESTATE:IsEventMode();
		-- Texture=THEME:GetPathG("","_shared/nine_stars_on.png"),
		-- InitCommand=function(s) s:zoom(0.667):xy(_screen.cx,_screen.b-51) end,
		-- OffCommand=function(s) s:linear(0.05):diffusealpha(0) end,
	-- };
-- end

-- if (GAMESTATE:HasEarnedExtraStage() and GAMESTATE:IsExtraStage()) then
	-- t[#t+1] = Def.Sound{
		-- File=THEME:GetPathS("WORLD/Try Extra","Stage"),
		-- OnCommand=function(s) s:sleep(2.7):queuecommand("Play") end,
		-- PlayCommand=function(s) s:play() end,
	-- };
	
	-- t[#t+1] = Def.Sprite{
		-- Texture="Try Extra Stage",
		-- InitCommand=function(s) s:zoomx(0.667):zoomy(0):xy(_screen.cx,_screen.b-51) end,
		-- OnCommand=function(s) s:sleep(2.7):linear(0.1):zoomy(0.667) end,
		-- OffCommand=function(s) s:linear(0.05):diffusealpha(0) end,
	-- };
	-- t[#t+1] = Def.Sprite{
		-- Texture="Try Extra Stage",
		-- InitCommand=function(s) s:zoom(0.667):xy(_screen.cx,_screen.b-51):diffusealpha(0) end,
		-- OnCommand=function(s) s:sleep(2.7):queuecommand("Zoom") end,
		-- ZoomCommand=function(s) s:linear(0.2):diffusealpha(1):linear(0.2):zoom(0.767):diffusealpha(0):sleep(0.8):zoom(0.667):queuecommand("Zoom")end,
		-- OffCommand=function(s) s:stoptweening():linear(0.05):diffusealpha(0) end,
	-- };
	
-- end

t[#t+1] = Def.ActorFrame{
	OffCommand=function(s)
		SOUND:PlayOnce(THEME:GetPathS("WORLD/Evaluation","Out"))
	end,
};

t[#t+1] = loadfile(THEME:GetPathB("ScreenGameplay","out/_doors"))()..{
	BeginCommand=function(s) s:draworder(99)
		if (STATSMAN:GetCurStageStats():AllFailed()) then
			s:playcommand("FailedOpen")
		else
			s:playcommand("Open") 
		end
	end,
};

-- the menu timer (Scripts/08 MenuTimer.lua); added before the doors, which have draworder 99
t[#t+1] = DDRWORLD_MenuTimer("ScreenEvaluation", MenuTimerPositions.Results.x, MenuTimerPositions.Results.y);

return t;