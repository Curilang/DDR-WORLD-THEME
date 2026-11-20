local pn = ...

local function RivalScore(pn,rival)
    local t = Def.ActorFrame {
        CurrentSongChangedMessageCommand=function(s) s:finishtweening():queuecommand("Set") end,
        ["CurrentSteps" .. ToEnumShortString(pn) .. "ChangedMessageCommand"]=function(s) s:finishtweening():queuecommand("Set") end,
        Def.BitmapText{
            Font="_swis721 blk bt 28px",
            InitCommand=function(s) s:zoom(0.57):xy(43,62):diffuse(Color.White):halign(1) end,
            OnCommand=function(self)
                local SongOrCourse, StepsOrTrail;
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
                        profile = PROFILEMAN:GetProfile(pn)
                    else
                        profile = PROFILEMAN:GetMachineProfile();
                    end
                    scorelist = profile:GetHighScoreList(SongOrCourse,StepsOrTrail);
                    assert(scorelist)
                    local scores = scorelist:GetHighScores();
                    
                    if scores[rival] then
                        self:settext(string.upper(PROFILEMAN:GetPlayerName(pn)))
                    else
                        self:settext("")
                    end;
                end;
            end;
        };
        Def.RollingNumbers {
            File = THEME:GetPathF("_swis721 blk bt","28px");
            InitCommand=function(s) s:zoom(0.57):xy(160,62):halign(1):diffuse(Color.White) end,
            BeginCommand=cmd(playcommand,"Set");
            SetCommand=function(self)
                local SongOrCourse, StepsOrTrail;
                if GAMESTATE:IsCourseMode() then
                    SongOrCourse = GAMESTATE:GetCurrentCourse();
                    StepsOrTrail = GAMESTATE:GetCurrentTrail(pn);
                else
                    SongOrCourse = GAMESTATE:GetCurrentSong();
                    StepsOrTrail = GAMESTATE:GetCurrentSteps(pn);
                end;
    
                local profile, scorelist;
                local topscore=0;
                if SongOrCourse and StepsOrTrail then
                    local st = StepsOrTrail:GetStepsType();
                    local diff = StepsOrTrail:GetDifficulty();
                    local courseType = GAMESTATE:IsCourseMode() and SongOrCourse:GetCourseType() or nil;
                    local profile;
                    if PROFILEMAN:IsPersistentProfile(pn) then
                        profile = PROFILEMAN:GetProfile(pn)
                    else
                        profile = PROFILEMAN:GetMachineProfile();
                    end
                    scorelist = profile:GetHighScoreList(SongOrCourse,StepsOrTrail);
                    assert(scorelist)
                    local scores = scorelist:GetHighScores();
                    
                    if scores[rival] then
                        if scores[rival]:GetScore() > 1 then
                            topscore = scores[rival]:GetScore();
                            self:visible(true)
                        else
                            topscore = 0
                            self:visible(true)
                        end
                    else
                        topscore = 0
                        self:visible(false)
                    end;
                    assert(topscore);
                    
                end;
                self:Load("RollingNumbersSongData");
                self:targetnumber(topscore);
            end;
        };
    };
    return t;
end

local yspace = -109
return Def.ActorFrame{
	Def.Sprite{
        Texture="base",
		InitCommand=function(s) s:pause():setstate(GetCurrentLanguage()) end,
    };
	RivalScore(pn,1)..{ InitCommand=function(s) s:y(yspace) end, };
	RivalScore(pn,2)..{ InitCommand=function(s) s:y(yspace+20) end, };
	RivalScore(pn,3)..{ InitCommand=function(s) s:y(yspace+40) end, };
	RivalScore(pn,4)..{ InitCommand=function(s) s:y(yspace+60) end, };
	RivalScore(pn,5)..{ InitCommand=function(s) s:y(yspace+80) end, };
}