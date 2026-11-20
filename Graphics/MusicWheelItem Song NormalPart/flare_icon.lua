-- FLARE icon of a music wheel item, next to the difficulty number and the clear mark.
--   flare_base: always visible (part of the look), whatever the difficulty and even without a FLARE.
--   flare_N:    the best FLARE earned on the chart of the selected difficulty. Shown only when that chart
--               exists and has been cleared with a FLARE, like the other icons.
-- The FLARE is saved when a song ends (see Scripts/08 FlareGaugeClears.lua).
local pn = ...

local ZOOM = 0.7        -- size of the base icon
local ICON_ZOOM = 0.65  -- flare_N is drawn a little smaller than the base

-- force = true when the item got a new song or its row changed. The difficulty messages also arrive every time the
-- wheel moves to a song with the same difficulty, and then nothing this item shows changes: it is not worked out again.
local function Update(self, force)
	local current = GAMESTATE:GetCurrentSteps(pn)
	local currentDiff = current and current:GetDifficulty()
	local levelKey = LevelSort.CurrentLevel()
	if not force and self.shownValid and self.shownDiff == currentDiff and self.shownLevel == levelKey then
		return
	end
	self.shownValid, self.shownDiff, self.shownLevel = true, currentDiff, levelKey

	local icon = self:GetChild("Icon")
	local level
	local song = self.ParamSong
	if song and not GAMESTATE:IsCourseMode() then
		local cur = GAMESTATE:GetCurrentSteps(pn)
		if cur then
			local steps = song:GetOneSteps(GAMESTATE:GetCurrentStyle():GetStepsType(), LevelSort.WheelDifficulty(song, pn, self.ParamIndex))
			if steps then level = FlareGauge.GetClear(pn, song, steps) end
		end
	end
	local f = level and FlareGauge.WheelFile("flare/flare_" .. level)
	icon:visible(f ~= nil)
	if f then WheelCache.LoadOnce(icon, f) end
end

return Def.ActorFrame{
	SetCommand=function(self, param)
		self.ParamSong = param.Song
		if param.Index then self.ParamIndex = param.Index end
		Update(self, true)
	end,
	CurrentStepsP1ChangedMessageCommand=function(self) Update(self) end,
	CurrentStepsP2ChangedMessageCommand=function(self) Update(self) end,
	CurrentSongChangedMessageCommand=function(self) Update(self) end,
	LevelSortCalibratedMessageCommand=function(self) Update(self, true) end,

	Def.Sprite{
		Name="Base",
		InitCommand=function(self)
			self:zoom(ZOOM):y(-3)
			local f = FlareGauge.WheelFile("flare/flare_base")
			if f then self:Load(f) else self:visible(false) end
		end,
	},
	Def.Sprite{
		Name="Icon",
		InitCommand=function(self) self:zoom(ICON_ZOOM):y(-3):visible(false) end,
	},
}
