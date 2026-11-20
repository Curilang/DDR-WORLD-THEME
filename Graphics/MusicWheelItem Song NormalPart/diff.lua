local pn =...

-- Level number of an item, in the color of the difficulty it is for.
-- force = true when the item got a new song (or its row changed): it is always drawn again. The messages about the
-- selected difficulty also arrive every time the wheel moves to a song, even when the difficulty is the same; in
-- that case nothing this item shows can have changed, so it is not worked out again.
local function setDiff(self, force)
	local st = GAMESTATE:GetCurrentStyle():GetStepsType()
	if self.ParamSong then
		local steps = GAMESTATE:GetCurrentSteps(pn)
		local level = LevelSort and LevelSort.CurrentLevel and LevelSort.CurrentLevel()
		local currentDiff = steps and steps:GetDifficulty()
		if not force and self.shownValid and self.shownDiff == currentDiff and self.shownLevel == level then
			return
		end
		self.shownValid, self.shownDiff, self.shownLevel = true, currentDiff, level

		-- LEVEL sort (Scripts/08 LevelSort.lua): the chart this row stands for in the open level section
		local chart = LevelSort and LevelSort.ItemChart and LevelSort.ItemChart(self.ParamSong, self.ParamIndex)
		if chart then
			self:settext(chart:GetMeter())
			self:diffuse(CustomDifficultyToColor(chart:GetDifficulty()))
			self:visible(true)
			return
		end
		if steps then
			local sDiff = currentDiff
			-- the level of the chart comes from the cache (Scripts/08 WheelCache.lua), not from the engine every time
			local info = WheelCache.Chart(pn, self.ParamSong, st, sDiff)
			local diffname = sDiff
			if not info.missing then
				self:settext(info.meter)
				self:diffuse(CustomDifficultyToColor(diffname));
				self:visible(true)
			else
				self:settext("")
				self:diffuse(color("1,1,1,0"))
			end
		else
			self:settext("")
			self:diffuse(color("1,1,1,0"))
		end
	end
end

return Def.BitmapText{
	InitCommand=function(s) s:zoom(0.92) end,
	Font="SelectMusicCard_numbers";
	SetCommand=function(self,param)
		self.ParamSong = param.Song
		if param.Index then self.ParamIndex = param.Index end
		if LevelSort and LevelSort.NoteRow then LevelSort.NoteRow(param) end
		setDiff(self, true)
	end;
	CurrentStepsP1ChangedMessageCommand=function(self) setDiff(self) end;
	CurrentStepsP2ChangedMessageCommand=function(self) setDiff(self) end;
	CurrentSongChangedMessageCommand=function(self) setDiff(self) end;
	LevelSortCalibratedMessageCommand=function(self) setDiff(self, true) end;
};
