-- FLARE card of a music wheel item: the card background used when the chart of the selected difficulty
-- has been cleared with a FLARE ("flare cards/flare_card_N.png", N = 1..10).
-- It sits above normal.png and behind the jacket. With two players the card is cut in half: the left half
-- shows player 1's FLARE and the right half player 2's, each for their own selected difficulty.
-- The FLARE is saved when a song ends (see Scripts/08 FlareGaugeClears.lua).
local pn = ...

return Def.Sprite{
	InitCommand=function(self)
		self:zoom(0.94):visible(false)
		if #GAMESTATE:GetHumanPlayers() == 2 then
			if pn == PLAYER_1 then
				self:cropright(0.5)
			else
				self:cropleft(0.5)
			end
		end
	end,
	SetCommand=function(self, param)
		self.ParamSong = param.Song
		if param.Index then self.ParamIndex = param.Index end
		self.forceRefresh = true
		self:playcommand("Refresh")
	end,
	CurrentStepsP1ChangedMessageCommand=function(self) self:playcommand("Refresh") end,
	CurrentStepsP2ChangedMessageCommand=function(self) self:playcommand("Refresh") end,
	CurrentSongChangedMessageCommand=function(self) self:playcommand("Refresh") end,
	LevelSortCalibratedMessageCommand=function(self) self.forceRefresh = true; self:playcommand("Refresh") end,
	RefreshCommand=function(self)
		-- skipped when nothing this card shows can have changed (the wheel moved to a song with the same difficulty)
		local force = self.forceRefresh
		self.forceRefresh = false
		local cur = GAMESTATE:GetCurrentSteps(pn)
		local currentDiff = cur and cur:GetDifficulty()
		local levelKey = LevelSort.CurrentLevel()
		if not force and self.shownValid and self.shownDiff == currentDiff and self.shownLevel == levelKey then return end
		self.shownValid, self.shownDiff, self.shownLevel = true, currentDiff, levelKey

		self:visible(false)
		local song = self.ParamSong
		if not song or GAMESTATE:IsCourseMode() then return end
		if not cur then return end
		local steps = song:GetOneSteps(GAMESTATE:GetCurrentStyle():GetStepsType(), LevelSort.WheelDifficulty(song, pn, self.ParamIndex))
		local level = steps and FlareGauge.GetClear(pn, song, steps)
		local f = level and FlareGauge.WheelFile("flare cards/flare_card_" .. level)
		if f then
			WheelCache.LoadOnce(self, f)
			self:visible(true)
		end
	end,
}
