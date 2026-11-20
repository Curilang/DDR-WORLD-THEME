local pn = ...

-- Best score of the chart this item stands for (in the LEVEL sort, the chart of its row). The engine is asked
-- once per chart and the answer is reused (Scripts/08 WheelCache.lua); a texture is only loaded when it changes.
local function ChartInfo(self)
	local song = self.cur_song
	if not song then return nil end
	local diff = LevelSort.WheelDifficulty(song, pn, self.cur_index)
	if not diff then return nil end
	return WheelCache.Chart(pn, song, GAMESTATE:GetCurrentStyle():GetStepsType(), diff)
end

return Def.ActorFrame{
	Def.Sprite{
		Texture="cleared_base",
		InitCommand=function(self) self:zoom(0.9):y(-3) end;
	},
	-- clear mark: full combo, cleared with the life bar or with the battery
	Def.Sprite{
		InitCommand=function(self) self:zoom(0.45) end;
		SetCommand=function(self,param)
			if not GAMESTATE:IsCourseMode() then
				self.cur_song = param.Song; if param.Index then self.cur_index = param.Index end;
				self:queuecommand "DiffChange";
			end
		end;
		LevelSortCalibratedMessageCommand=function(self) self:queuecommand("DiffChange") end;
		DiffChangeCommand=function(self)
			local info = ChartInfo(self)
			if info and not info.missing and info.mark then
				WheelCache.LoadOnce(self, WheelCache.PathG("", "_shared/cleared/" .. info.mark))
				self:visible(true)
			else
				self:visible(false)
			end
		end;
	};
	-- grade of the best score
	Def.Sprite{
		InitCommand=function(self) self:y(-7):zoom(0.055) end;
		SetCommand=function(self,param)
			if not GAMESTATE:IsCourseMode() then
				self.cur_song = param.Song; if param.Index then self.cur_index = param.Index end;
				self:queuecommand "DiffChange";
			end
		end;
		LevelSortCalibratedMessageCommand=function(self) self:queuecommand("DiffChange") end;
		DiffChangeCommand=function(self)
			local info = ChartInfo(self)
			if info and not info.missing and info.gradeFile then
				WheelCache.LoadBackgroundOnce(self, WheelCache.PathG("", "Grade/" .. info.gradeFile))
				self:visible(true)
			else
				self:visible(false)
			end
		end;
	};
};
