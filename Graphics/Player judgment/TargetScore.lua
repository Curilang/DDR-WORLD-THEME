-- TargetScore (A3)
-- Sourced from https://josevarela.net/SMArchive/Themes/ThemePreview.php?Category=StepMania%205&ID=DDR2013
-- Modified for DDR A3 theme with realistic behavior
-- Needs judgments in the background

local pn = ...
local st = GAMESTATE:GetCurrentStyle():GetStepsType();
local pname = ToEnumShortString(pn);
local ts = {0,0};

local playerFailed = false;

local t = Def.ActorFrame {};

function TargetScore(pn)
	return "personal"
end

function EXScore(pn)
	return "personal"
end

function GetNormalScore(maxsteps,score,pn)
	local s;
	local w1 = score:GetTapNoteScore('TapNoteScore_W1');
	local w2 = score:GetTapNoteScore('TapNoteScore_W2');
	local w3 = score:GetTapNoteScore('TapNoteScore_W3');
	local hd = score:GetHoldNoteScore('HoldNoteScore_Held');
	if EXScore(pn) == "On" then
		s = w1*3 + w2*2 + w3 + hd*3;
	else
		if PREFSMAN:GetPreference("AllowW1")~="AllowW1_Everywhere" then
			w1 = w1+w2;
			w2 = 0;
		end;
		s = (math.round( (w1 + w2 + w3/2+hd)*100000/maxsteps-(w2 + w3))*10);
	end;
	return s;
end;

local bTargetScore = TargetScore(pn);

if not GAMESTATE:IsDemonstration() and not GAMESTATE:IsCourseMode() and GAMESTATE:GetPlayMode() == 'PlayMode_Regular' and bTargetScore ~= "off" then
	local bEXScore = EXScore(pn);
	
	local function GetMachinePersonalHighScores()
		local profile;
		if bTargetScore == "personal" then
			if PROFILEMAN:IsPersistentProfile(pn) then
				profile = PROFILEMAN:GetProfile(pn);
			else
				profile = PROFILEMAN:GetMachineProfile();
			end;
		else
			profile = PROFILEMAN:GetMachineProfile();
		end;
		local song = GAMESTATE:GetCurrentSong()
		local diff = GAMESTATE:GetCurrentSteps(pn):GetDifficulty()
		local steps = song:GetOneSteps( st, diff );
		scorelist = profile:GetHighScoreList(song,steps);
		assert(scorelist);
		return scorelist:GetHighScores();
	end;

	local p=((pn == PLAYER_1) and 1 or 2);

	local steps = GAMESTATE:GetCurrentSteps(pn);
	local rv = steps:GetRadarValues(pn);
	local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(pn);
	local maxsteps = math.max(rv:GetValue('RadarCategory_TapsAndHolds')
	+rv:GetValue('RadarCategory_Holds')+rv:GetValue('RadarCategory_Rolls'),1);

	local scores = GetMachinePersonalHighScores(pn);
	assert(scores);
	local topscore=0;
	if scores[1] then
		for i = 1, #scores do
			if scores[i] then
				local topscore2 = GetNormalScore(maxsteps,scores[i],pn);
				if topscore2 > topscore then
					topscore = topscore2;
				end;
			else
				break;
			end;
		end;
	end;
	assert(topscore);

	if topscore == 0 then return end
			
	local moto = topscore/maxsteps;
	
	setenv("TopScoreSave"..pname,topscore);
	
	t[#t+1] = Def.ActorFrame {
		LifeChangedMessageCommand=function(self,params)
			if params.Player ~= pn then return end;
			if params.LivesLeft == 0 then
				self:visible(false);
			else
				self:visible(true);
			end;
		end;
		LoadFont("TargetScore numbers") .. {
			InitCommand=function(self)
				self:xy(-76,IsReverse(pn) and -8 or 37);
				self:rotationz(-10)
				self:zoom(0.55);
				(cmd(horizalign,left;strokecolor,color("#000000")))(self)
			end;
			OnCommand=function(self)
				if GAMESTATE:GetCurrentStyle():GetName() == "double" then
					self:x(SCREEN_CENTER_X+55)
				end
			end;
			LifeChangedMessageCommand=function(self,params)
				if params.Player ~= pn then return end
				if params.LifeMeter:GetLife() == 0 then
					self:visible(false)
					playerFailed = true
				end
			end;
			JudgmentMessageCommand=function(self,params)
				if GAMESTATE:GetPlayerState(pn):GetHealthState() == "HealthState_Dead" then return end
				if params.Player ~= pn then return end;
				self:finishtweening();
				if params.TapNoteScore and
				   params.TapNoteScore ~= 'TapNoteScore_AvoidMine' and
				   params.TapNoteScore ~= 'TapNoteScore_HitMine' and
				   params.TapNoteScore ~= 'TapNoteScore_CheckpointMiss' and
				   params.TapNoteScore ~= 'TapNoteScore_CheckpointHit' and
				   params.TapNoteScore ~= 'TapNoteScore_None'
				then
					local ret=0;
					local w1=pss:GetTapNoteScores('TapNoteScore_W1');
					local w2=pss:GetTapNoteScores('TapNoteScore_W2');
					local w3=pss:GetTapNoteScores('TapNoteScore_W3');
					local hd=pss:GetHoldNoteScores('HoldNoteScore_Held');
					if params.HoldNoteScore=='HoldNoteScore_Held' then
						hd=hd+1;
					elseif params.TapNoteScore=='TapNoteScore_W1' then
						w1=w1+1;
					elseif params.TapNoteScore=='TapNoteScore_W2' then
						w2=w2+1;
					elseif params.TapNoteScore=='TapNoteScore_W3' then
						w3=w3+1;
					end;
					
					if bEXScore == "On" then
						ret = w1*3 + w2*2 + w3;
						ts[p] = ts[p] + moto
						local last = math.round((ret-ts[p]));
						if last > 0 then
							self:diffuse(color("#766fbd"));
							self:settext("+"..last);
						elseif last < 0 then
							self:diffuse(color("#bd727f"));
							self:settext(last);
						else
							self:diffuse(color("#ffffff"));
							self:settext("0");
						end;
					else
						ret=(math.round((w1 + w2 + w3/2 + hd) *100000/maxsteps-(w2 + w3))*10);
						ts[p] = ts[p] + moto
						local last = math.round((ret-ts[p])*0.1);
						if last > 0 then
							self:diffuse(color("#766fbd"));
							self:settext("+"..last*10);
						elseif last < 0 then
							self:diffuse(color("#bd727f"));
							self:settext(last*10);
						else
							self:diffuse(color("#ffffff"));
							self:settext("±0");
						end;
					end;
					
					self:diffusealpha(1)
				end;
			end;
		};
	};
else
	setenv("TopScoreSave"..pname,0);
end;

return Def.ActorFrame{
	InitCommand=function(s) s:visible(ThemePrefs.Get("TargetScore") == "ON" and true or false) end,
	t;
};
