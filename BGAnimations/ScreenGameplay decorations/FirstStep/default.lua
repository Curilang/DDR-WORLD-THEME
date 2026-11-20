local pn = ...

local StartSettings = {
	Texture = "start 2x1.png",
	Zoom = 0.667,
	Gap = 12,
	X = 0,
	Y = 20,
}

local firstNoteCache = {}


local simfileCache = {}

local function TrimStartText(value)
	return (value or ""):match("^%s*(.-)%s*$")
end

local function FirstNoteFromText(steps)
	local filename = steps:GetFilename()
	if not filename or filename == "" then return nil end
	local contents = simfileCache[filename]
	if contents == nil then
		local file = RageFileUtil.CreateRageFile()
		if file:Open(filename,1) then contents = file:Read() end
		file:destroy()
		contents = contents and contents:gsub("//[^\r\n]*","") or false
		simfileCache[filename] = contents
	end
	if not contents then return nil end
	local stepType = ToEnumShortString(steps:GetStepsType()):lower():gsub("_","-")
	local difficulty = ToEnumShortString(steps:GetDifficulty()):lower()
	local description = TrimStartText(steps:GetDescription())
	local meter = steps:GetMeter()
	local aliases = {basic="easy",another="medium",difficult="medium",maniac="hard",smaniac="challenge"}
	local function Matches(kind,desc,diff,level)
		diff = TrimStartText(diff):lower()
		return TrimStartText(kind):lower() == stepType
			and (aliases[diff] or diff) == difficulty
			and tonumber(TrimStartText(level)) == meter
			and TrimStartText(desc) == description
	end
	local notes
	if filename:lower():match("%.ssc$") then
		local block
		for key,value in contents:gmatch("#([%w_]+)%s*:(.-);") do
			local tag = key:upper()
			if tag == "NOTEDATA" then
				block = {}
			elseif block then
				block[tag] = value
				if tag == "NOTES" and Matches(block.STEPSTYPE,block.DESCRIPTION,block.DIFFICULTY,block.METER) then
					notes = value
					break
				end
			end
		end
	elseif filename:lower():match("%.sm$") then
		for key,value in contents:gmatch("#([%w_]+)%s*:(.-);") do
			if key:upper() == "NOTES" then
				local kind,desc,diff,level,radar,data = value:match("^%s*([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):(.*)$")
				if kind and Matches(kind,desc,diff,level) then notes=data; break end
			end
		end
	end
	if not notes then return nil end
	local timing = steps:GetTimingData()
	local measure = 0
	for data in (notes..","):gmatch("(.-),") do
		local rows = {}
		for rawLine in data:gmatch("[^\r\n]+") do
			local line = TrimStartText(rawLine)
			if line:match("^[01234MKLFAmklfa]+$") then rows[#rows+1] = line end
		end
		for row, line in ipairs(rows) do
			local beat = measure*4+(row-1)*4/#rows
			if not timing.IsJudgableAtBeat or timing:IsJudgableAtBeat(beat) then
				local columns = {}
				for col=1,#line do
					local kind = line:sub(col,col):upper()
					if kind=="1" or kind=="2" or kind=="4" or kind=="L" then columns[#columns+1]=col end
				end
				if #columns>0 then
					return {Time=timing:GetElapsedTimeFromBeat(beat),Columns=columns}
				end
			end
		end
		measure = measure+1
	end
	return nil
end

local function GetFirstNote(steps)
	if firstNoteCache[steps] ~= nil then
		return firstNoteCache[steps] or nil
	end
	-- Una sola consulta por chart. -1 incluye tambien notas tras pausas cortas.
	if not steps.GetColumnCues then
		local result = FirstNoteFromText(steps)
		firstNoteCache[steps] = result or false
		return result
	end
	local cues = steps:GetColumnCues(-1)
	local firstTime, firstColumns
	for _, cue in ipairs(cues) do
		local columns = {}
		for _, note in ipairs(cue.columns or {}) do
			local kind = note.noteType
			if kind == 1 or kind == 2 or kind == 5
				or kind == "TapNoteType_Tap"
				or kind == "TapNoteType_HoldHead"
				or kind == "TapNoteType_Lift"
				or (kind == nil and note.isMine == false) then
				columns[#columns+1] = note.colNum
			end
		end
		if #columns > 0 then
			firstTime = cue.startTime + cue.duration
			firstColumns = columns
			break
		end
	end
	local result = firstTime and {Time=firstTime, Columns=firstColumns} or false
	firstNoteCache[steps] = result
	return result or nil
end

local function StartColumnMapping(options, count)
	local unsupported = {
		"Shuffle", "SoftShuffle", "SuperShuffle", "Backwards",
		"Little", "Wide", "Big", "Quick", "BMRize", "Skippy", "Echo",
		"Stomp", "NoJumps", "NoHands", "NoQuads", "NoStretch",
		"NoLifts",
	}
	for _, name in ipairs(unsupported) do
		if options[name] and options[name](options) then return nil end
	end
	local map = {}
	for col=1,count do map[col] = col end
	if options:Left() or options:Right() then
		if count ~= 4 then return nil end
		if options:Left() then map = {2,4,1,3} end
		if options:Right() then map = {3,1,4,2} end
	end
	if options:Mirror() then
		for col=1,count do map[col] = count+1-map[col] end
	end
	return map
end

local function FirstStepIndicator(pn)
	local style = GAMESTATE:GetCurrentStyle(pn)
	local count = style:ColumnsPerPlayer()
	local state = GAMESTATE:GetPlayerState(pn)
	local active, player, field, options
	local enabled = false
	local elapsed = 0
	local standardY = THEME:GetMetric("Player", "ReceptorArrowsYStandard")
	local reverseY = THEME:GetMetric("Player", "ReceptorArrowsYReverse")
	local height = reverseY-standardY
	local sprites = {}
	local offsets = StartSettings

	local function Update(self, delta)
		if not enabled then return end
		elapsed = elapsed+delta
		if elapsed < 1/30 then return end
		elapsed = 0
		for _, col in ipairs(active) do
			local reverse = options:GetReversePercentForColumn(col-1) > 0.5
			local sprite = sprites[col]
			local zoomX, zoomY, x, y
			if field and player then
				zoomX = field:GetZoomX()*player:GetZoomX()
				zoomY = field:GetZoomY()*player:GetZoomY()
				x = player:GetX()+(field:GetX()
					+ArrowEffects.GetXPos(state,col,0)*field:GetZoomX())*player:GetZoomX()
				y = player:GetY()+(field:GetY()
					+ArrowEffects.GetYPos(state,col,0,height)*field:GetZoomY())*player:GetZoomY()
			else
				zoomX = 1-options:Mini()*0.5
				zoomY = zoomX
				local centerX = pn==PLAYER_1 and ScreenGameplay_P1X() or ScreenGameplay_P2X()
				if PREFSMAN:GetPreference("Center1Player") and GAMESTATE:GetNumPlayersEnabled()==1 then
					centerX = SCREEN_CENTER_X
				end
				x = centerX+style:GetColumnInfo(pn,col).XOffset*zoomX
				y = SCREEN_CENTER_Y+(reverse and reverseY or standardY)
			end
			local scaleY = StartSettings.Zoom*math.abs(zoomY)
			local distance = StartSettings.Gap*math.abs(zoomY)
			sprite:setstate(reverse and 1 or 0):valign(reverse and 1 or 0)
				:zoomx(StartSettings.Zoom*math.abs(zoomX)):zoomy(scaleY)
				:xy(x+offsets.X,y+(reverse and -60 or 20)+offsets.Y)
		end
	end

	local af = Def.ActorFrame{
		Name="FirstStep"..ToEnumShortString(pn),
		OnCommand=function(self) self:queuecommand("SetStart") end,
		CurrentSongChangedMessageCommand=function(self)
			self:stoptweening():diffusealpha(1):queuecommand("SetStart")
				:sleep(BeginReadyDelay()+SongMeasureSec())
				:decelerate(0.3):diffusealpha(0):queuecommand("StopStart")
		end,
		StopStartCommand=function(self)
			enabled = false
			self:SetUpdateFunction(nil)
		end,
		SetStartCommand=function(self)
			enabled = false
			self:SetUpdateFunction(nil)
			for _, sprite in ipairs(sprites) do
				sprite:stoptweening():diffusealpha(0)
			end
			-- ARROW START LANE PREVIEW = OFF in the player options
				if POMenu and POMenu.LanePreviewOn and not POMenu.LanePreviewOn(pn) then return end
				local screen = SCREENMAN:GetTopScreen()
			player = screen and screen:GetChild("Player"..ToEnumShortString(pn))
			field = player and player:GetChild("NoteField")
			options = state:GetPlayerOptions("ModsLevel_Current")
			local map = StartColumnMapping(options,count)
			if not map then return end
			local steps = GAMESTATE:GetCurrentSteps(pn)
			if GAMESTATE:IsCourseMode() then
				local trail = GAMESTATE:GetCurrentTrail(pn)
				local entries = trail and trail:GetTrailEntries()
				local index = GAMESTATE:GetLoadingCourseSongIndex()+1
				if entries and entries[index] then steps = entries[index]:GetSteps() end
			end
			if not steps then return end
			local note = GetFirstNote(steps)
			if not note then return end
			active = {}
			for _, track in ipairs(note.Columns) do
				for col=1,count do
					if style:GetColumnInfo(pn,col).Track == track then
						active[#active+1] = map[col]
					end
				end
			end
			if #active == 0 then return end
			elapsed = 1/30
			enabled = true
			Update(self,0)
			if enabled then
				for _, col in ipairs(active) do sprites[col]:diffusealpha(1) end
				self:SetUpdateFunction(Update)
			end
		end,
		OffCommand=function(self)
			enabled = false
			self:SetUpdateFunction(nil)
			for _, sprite in ipairs(sprites) do sprite:stoptweening():diffusealpha(0) end
		end,
	}
	for col=1,count do
		local column = col
		af[#af+1] = Def.Sprite{
			Texture=StartSettings.Texture,
			InitCommand=function(self)
				sprites[column] = self
				self:animate(false):setstate(0):diffusealpha(0)
			end,
		}
	end
	return af
end

return FirstStepIndicator(pn)
