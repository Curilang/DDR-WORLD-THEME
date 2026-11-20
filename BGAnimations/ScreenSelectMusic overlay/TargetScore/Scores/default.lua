local pn = ...

-- Score of one place (1..5) for the current song and chart, and whether there is a song and chart at all. The five
-- places and the two texts of each one ask for the same list at every change, so for songs it comes from
-- Scripts/08 WheelCache.lua instead of being read from the engine each time. Courses are read directly.
local function PlaceScore(pn, place)
    if GAMESTATE:IsCourseMode() then
        local course = GAMESTATE:GetCurrentCourse();
        local trail = GAMESTATE:GetCurrentTrail(pn);
        if not (course and trail) then return nil, false end
        local scores = MachineOrProfile(pn):GetHighScoreList(course,trail):GetHighScores();
        return scores[place] and scores[place]:GetScore() or nil, true
    end

    local song = GAMESTATE:GetCurrentSong();
    local steps = GAMESTATE:GetCurrentSteps(pn);
    if not (song and steps) then return nil, false end
    return WheelCache.TopScores(pn, song, steps)[place], true
end

local function RivalScore(pn,rival,zoom,nameX,scoreX,Y)
    local t = Def.ActorFrame {
        CurrentSongChangedMessageCommand=function(s) s:finishtweening():queuecommand("Set") end,
        ["CurrentSteps" .. ToEnumShortString(pn) .. "ChangedMessageCommand"]=function(s) s:finishtweening():queuecommand("Set") end,
        Def.BitmapText{
            Font="_swis721 blk bt 28px",
            InitCommand=function(s) s:zoom(zoom):xy(nameX,Y):diffuse(Color.White):halign(1) end,
            SetCommand=function(self)
                local score, available = PlaceScore(pn, rival)
                if available then
                    if score then
                        self:settext(string.upper(PROFILEMAN:GetPlayerName(pn)))
                    else
                        self:settext("")
                    end;
                end;
            end;
        };
        Def.RollingNumbers {
            File = THEME:GetPathF("_swis721 blk bt","28px");
            InitCommand=function(s) s:zoom(zoom):xy(scoreX,Y):halign(1):diffuse(Color.White):queuecommand("Set") end,
            SetCommand=function(self)
                local topscore=0;
                local score, available = PlaceScore(pn, rival)
                if available then
                    if score and score > 1 then
                        topscore = score;
                        self:visible(true)
                    else
                        topscore = 0
                        self:visible(false)
                    end;
                end;
                self:Load("RollingNumbersSongData");
                self:targetnumber(topscore);
            end;
        };
    };
    return t;
end

local zoom = 0.28
local nameX = -2
local scoreX = 94
local yspace = -37

return Def.ActorFrame{
	Def.Sprite{
        Texture="base",
		InitCommand=function(s) s:pause():setstate(GetCurrentLanguage()):zoom(0.595) end,
    };
	RivalScore(pn,1,zoom,nameX,scoreX,yspace);
	RivalScore(pn,2,zoom,nameX,scoreX,yspace+12);
	RivalScore(pn,3,zoom,nameX,scoreX,yspace+24);
	RivalScore(pn,4,zoom,nameX,scoreX,yspace+36);
	RivalScore(pn,5,zoom,nameX,scoreX,yspace+48);
};
