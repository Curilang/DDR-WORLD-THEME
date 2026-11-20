local pn = ...

return Def.ActorFrame{
	Def.Sprite{
		Texture="cleared_base",
		InitCommand=function(self) self:zoom(0.9):y(-3) end;
	},
	Def.Sprite{
		InitCommand=function(self) self:zoom(0.45)
		end;
		SetCommand=function(self,param)
			if not GAMESTATE:IsCourseMode() then
				self.cur_song = param.Song; if param.Index then self.cur_index = param.Index end;
				self:queuecommand "DiffChange";
			end
		end;
		LevelSortCalibratedMessageCommand=function(self) self:queuecommand("DiffChange") end;
			DiffChangeCommand=function(self)
			local st = GAMESTATE:GetCurrentStyle():GetStepsType();
			local diff = LevelSort.WheelDifficulty(self.cur_song, pn, self.cur_index);
			if self.cur_song then
				if self.cur_song:HasStepsTypeAndDifficulty(st,diff) then
					local steps = self.cur_song:GetOneSteps( st, diff );
					local profile
					if PROFILEMAN:IsPersistentProfile(pn) then
						profile = PROFILEMAN:GetProfile(pn);
					else
						profile = PROFILEMAN:GetMachineProfile();
					end;
					local scorelist = profile:GetHighScoreList(self.cur_song,steps);
					assert(scorelist);
					local scores = scorelist:GetHighScores();
					assert(scores);
					local topscore=0;
					if scores[1] then
						topscore = scores[1];
						assert(topscore);
						local misses = topscore:GetTapNoteScore("TapNoteScore_Miss")
									  +topscore:GetTapNoteScore("TapNoteScore_CheckpointMiss")
									  +topscore:GetTapNoteScore("TapNoteScore_HitMine")
									  +topscore:GetTapNoteScore("TapNoteScore_W5")
						local goods = topscore:GetTapNoteScore("TapNoteScore_W4")
						local greats = topscore:GetTapNoteScore("TapNoteScore_W3")
						local perfects = topscore:GetTapNoteScore("TapNoteScore_W2")
						local marvelous = topscore:GetTapNoteScore("TapNoteScore_W1")
						local hasUsedBattery = string.find(topscore:GetModifiers(),"Lives")
						if (misses) == 0 and scores[1]:GetScore() > 0 and (marvelous+perfects)>0 then
							if (greats+perfects) == 0 then
								self:Load(THEME:GetPathG("","_shared/cleared/MarvelousFullCombo"))
							elseif greats == 0 then
								self:Load(THEME:GetPathG("","_shared/cleared/PerfectFullCombo"))
							elseif (misses+goods) == 0 then
								self:Load(THEME:GetPathG("","_shared/cleared/GreatFullCombo"))
							elseif (misses) == 0 then
								self:Load(THEME:GetPathG("","_shared/cleared/FullCombo"))
							end;
							self:visible(true)
						else
							if topscore:GetGrade() ~= 'Grade_Failed' then
								if hasUsedBattery then
									self:visible(true)
									self:Load(THEME:GetPathG("","_shared/cleared/Gauge"))
								else
									self:visible(true)
									self:Load(THEME:GetPathG("","_shared/cleared/LifeBar"))
								end
							else
								self:visible(false)
							end
						end;
					else
						self:visible(false)
					end;
                else
					self:visible(false)
				end;
            else
                self:visible(false)
            end;
        end;
    };
};