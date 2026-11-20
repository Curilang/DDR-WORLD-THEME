local t = Def.ActorFrame{};
local lastAnnouncer = ANNOUNCER:GetCurrentAnnouncer()

t[#t+1] = StatsEngine()

t[#t+1] = Def.Actor{
    AfterStatsEngineMessageCommand = function(_,params)
        local pn = params.Player
		local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(pn)

        local aScore = params.Data.AScoring
		pss:SetScore(aScore.Score)
		pss:SetCurMaxScore(aScore.MaxScore)

        local fast, slow = 0, 0

        local fastSlow = params.Data.FastSlowRecord
			if fastSlow then
				fast = fastSlow.Fast
				slow = fastSlow.Slow
			end

        local short = ToEnumShortString(pn)
			setenv("numFast"..short, fast)
		setenv("numSlow"..short, slow)
	end,
};


t[#t+1] = Def.ActorFrame {
	Def.Actor {
		OffCommand=function(s)
			ANNOUNCER:SetCurrentAnnouncer('')
			s:sleep(BeginOutDelay()):queuecommand('Play')
		end,
		PlayCommand=function()
			local st = STATSMAN:GetCurStageStats()
			if lastAnnouncer then
				ANNOUNCER:SetCurrentAnnouncer(lastAnnouncer)
			end
			
			if st:AllFailed() then
				SOUND:PlayAnnouncer('gameplay failed')
			else
				SOUND:PlayAnnouncer('gameplay cleared')
			end
		end,
	},
	Def.Actor {
		NextCourseSongMessageCommand=function(s) s:stoptweening() end,
		CurrentSongChangedMessageCommand=function(s)
			if GAMESTATE:IsCourseMode() then
				local curStage = GAMESTATE:GetLoadingCourseSongIndex()+1
				if curStage > 1 then
					s:sleep(BeginReadyDelay()):queuecommand('Play')
				end
			end
		end,
		PlayCommand=function(s) SOUND:PlayAnnouncer('gameplay ready') end,
	},
	Def.Actor{
		NextCourseSongMessageCommand=function(s) s:sleep(2):queuecommand('Play') end,
		PlayCommand=function(s)
			local curStage = GAMESTATE:GetLoadingCourseSongIndex()+1
			local stageName = 'stage ' .. curStage
			local maxStages = GAMESTATE:GetCurrentCourse():GetEstimatedNumStages()
		
			if curStage == maxStages then
				stageName = 'stage final'
			end
			
			SOUND:PlayAnnouncer(stageName)
		end,
	},
};

for _, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do	
	t[#t+1] = LoadActor("ScreenFilter",pn);
	t[#t+1] = LoadActor("Danger",pn);
	t[#t+1] = LoadActor("GuideLines", pn)
end;

-- COMBO / JUDGMENT en LOW por jugador: copia dibujada bajo el notefield, encima del filtro y las guías.
-- Solo se crea para quien eligió LOW; el actor del motor de ese jugador queda oculto.
for _, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
	local short = ToEnumShortString(pn)
	local needCombo = not POMenu.ComboHigh(pn)
	local needJudg  = not POMenu.JudgmentHigh(pn)

	if needCombo or needJudg then
		local frame = Def.ActorFrame{
			Name = "UnderField" .. short,
			-- misma posición que el actor Player del motor
			OnCommand = function(self)
				local screen = SCREENMAN:GetTopScreen()
				local pl = screen and screen:GetChild("Player" .. short)
				if pl then self:xy(pl:GetX(), pl:GetY()) end
			end,
		}

		if needCombo then
			frame[#frame+1] = Def.ActorFrame{
				Name = "Combo",
				InitCommand = function(self)
					ComboTransformCommand(self, { bReverse = IsReverse(pn) })
				end,
				LoadActor(THEME:GetPathG("Player", "combo"), { Player = pn, Copy = true }),
			}
		end

		if needJudg then
			-- juicio grande
			frame[#frame+1] = Def.ActorFrame{
				Name = "Judgment",
				InitCommand = function(self)
					JudgmentTransformCommand(self, { bReverse = IsReverse(pn) })
				end,
				LoadActor(THEME:GetPathG("Player", "judgment"), { Player = pn, Copy = true }),
			}

			-- OK/NG de los holds: una copia por columna, con los mismos commands que usa el motor
			local style = GAMESTATE:GetCurrentStyle()
			local yStd = THEME:GetMetric("Player", "HoldJudgmentYStandard")
			local yRev = THEME:GetMetric("Player", "HoldJudgmentYReverse")
			local HeldCmd  = THEME:GetMetric("HoldJudgment", "HoldJudgmentHeldCommand")
			local LetGoCmd = THEME:GetMetric("HoldJudgment", "HoldJudgmentLetGoCommand")

			for col = 1, style:ColumnsPerPlayer() do
				local info = style:GetColumnInfo(pn, col)
				frame[#frame+1] = Def.Sprite{
					Name = "HoldJudgment" .. col,
					InitCommand = function(self)
						self:Load(THEME:GetPathG("", "HoldJudgment label 1x2/Hold"))
						self:animate(false):visible(false)
						self:xy(info.XOffset, IsReverse(pn) and yRev or yStd)
					end,
					HeldCommand = HeldCmd,
					LetGoCommand = LetGoCmd,
					JudgmentMessageCommand = function(self, p)
						if p.Player ~= pn or not p.HoldNoteScore then return end
						if p.FirstTrack ~= col - 1 then return end
						if p.HoldNoteScore == "HoldNoteScore_Held" then
							self:setstate(0)
							self:playcommand("Held")
						elseif p.HoldNoteScore == "HoldNoteScore_LetGo" then
							self:setstate(1)
							self:playcommand("LetGo")
						end
					end,
				}
			end
		end

		t[#t+1] = frame
	end
end

t[#t+1] = LoadActor("ScoreFrame")..{ InitCommand=function(s) s:draworder(99) end, };

for _,pn in pairs(GAMESTATE:GetEnabledPlayers()) do
	t[#t+1] = LoadActor("lifeframe",pn);
	t[#t+1] = LoadActor(THEME:GetPathG("","OptionIcon"),pn)..{
		InitCommand=function(s) 
			s:zoom(0.667):draworder(1):xy(pn==PLAYER_1 and SCREEN_LEFT+23 or SCREEN_RIGHT-23,_screen.cy+165)
		end,
	};
	t[#t+1] = LoadActor("FirstStep", pn)
	
	t[#t+1] = LoadActor("Speed-Appearance",pn)..{
		Condition=(not GAMESTATE:IsDemonstration());
		InitCommand=function(s) s:draworder(1) end, 
	};
	
end

t[#t+1] = LoadActor("StageFrame")..{ InitCommand=function(s) s:draworder(1) end, };

if not GAMESTATE:IsDemonstration() then
	t[#t+1] = Def.Sprite{
		Texture="READY",
		InitCommand=function(s) s:Center():zoom(1.5):decelerate(0.3):zoom(0.667):draworder(99) end,
		CurrentSongChangedMessageCommand=function(s) s:sleep(BeginReadyDelay()+SongMeasureSec()-0.3):decelerate(0.3):zoom(0)end,
	};	
	t[#t+1] = Def.Sprite{
		Texture=THEME:GetPathG("","_shared/circle.png"),
		InitCommand=function(s) s:diffuse(color("#00ce9c")):Center():zoom(2):draworder(99) end,
		OnCommand=function(s) s:decelerate(0.3):zoom(0) end, 
	};
	
	t[#t+1] = loadfile(THEME:GetPathB("ScreenGameplay","out/_doors"))() .. {
		InitCommand=function(s) s:draworder(99) end,
		OffCommand=function(s)
		local st = STATSMAN:GetCurStageStats()
			-- delay before shutter close
			s:sleep(BeginOutDelay())
			if st:AllFailed() then
				s:queuecommand("FailedClose")
			else
				s:queuecommand("Close")
			end
		end,
	};
end

return t
