-- Measured from a video of the original (60 fps): when the wheel moves the panel disappears at once, and when the
-- cursor stops it waits about 0.30 s and then fades in over about 0.40 s.
local SHOW_DELAY = 0.30
local SHOW_FADE = 0.40
local AnimPlayed = true

local function GetCurrentSteps()
	for _, pn in ipairs({PLAYER_1, PLAYER_2}) do
		if GAMESTATE:IsHumanPlayer(pn) then
			local steps = GAMESTATE:GetCurrentSteps(pn)

			if steps then
				return steps
			end
		end
	end

	return nil
end

-- BPM changes, stops and mines only depend on the chart, so they are worked out once (Scripts/08 WheelCache.lua)
-- and not every time the song, a difficulty or the other player's difficulty changes.
local function Facts()
	local song = GAMESTATE:GetCurrentSong()
	local steps = GetCurrentSteps()

	if not song or not steps then
		return nil
	end

	return WheelCache.ChartFacts(song, steps)
end

local function HasBPMChanges()
	local facts = Facts()

	return facts and facts.bpm and facts.bpm.hasChange or false
end

local function HasStops()
	local facts = Facts()

	return facts and facts.stops or false
end

local function HasShockArrows()
	local facts = Facts()

	return facts and facts.mines or false
end

-- Several messages can arrive in the same frame (song and difficulties changing together): the update is queued
-- once.
local function QueueOnce(actor, command)
	local pending = actor["_pending" .. command]

	if not pending then
		actor["_pending" .. command] = true
		actor:queuecommand(command)
	end
end

local function TimingIcon(texture, checkFunction, x)
	return Def.Sprite{
		Texture = texture,

		InitCommand = function(s)
			s:xy(x, 67):zoom(0.667):diffusealpha(0)
		end,

		CurrentSongChangedMessageCommand = function(s)
			QueueOnce(s, "Set")
		end,

		CurrentStepsP1ChangedMessageCommand = function(s)
			QueueOnce(s, "Set")
		end,

		CurrentStepsP2ChangedMessageCommand = function(s)
			QueueOnce(s, "Set")
		end,

		SetCommand = function(s)
			s._pendingSet = false
			local song = GAMESTATE:GetCurrentSong()
			local show = false

			if song and GetCurrentSteps() then
				show = checkFunction()
			end

			s:stoptweening()
			s:diffusealpha(show and 1 or 0)
		end,
	}
end

return Def.ActorFrame{
	InitCommand = function(s)
		-- size and position are set here, not in an OnCommand: a command that comes after the fade tweens would
		-- wait for them (and a stoptweening would drop it), leaving the panel at full size
		s:xy(_screen.cx, 57):zoom(0.667)
	end,

	CurrentSongChangedMessageCommand = function(s)
		local song = GAMESTATE:GetCurrentSong()

		-- Set (the texts) runs at once: a queued command would wait behind the fade tweens of Show, and Show
		-- stops them on the next move, so the texts would never be written
		if song then
			s:playcommand("Set")
			s:playcommand("Show")
		else
			s:playcommand("Hide")
		end
	end,

	ShowCommand = function(s)
		-- every move of the wheel: hidden right away, back after the cursor rests
		s:stoptweening():diffusealpha(0)
		s:sleep(SHOW_DELAY):linear(SHOW_FADE):diffusealpha(1)
		s:queuecommand("UpdateShow")
	end,

	UpdateShowCommand = function(s)
		AnimPlayed = true
	end,

	HideCommand = function(s)
		-- on a group title there is no song: the panel flickers out (it is not shown again until a song is)
		s:stoptweening()
		if s:GetDiffuseAlpha() > 0 then
			s:diffusealpha(1)
			s:sleep(0.05):diffusealpha(0)
			s:sleep(0.05):diffusealpha(0.5)
			s:sleep(0.05):diffusealpha(0)
			s:sleep(0.05):diffusealpha(0.25)
			s:sleep(0.05):diffusealpha(0)
			s:linear(0.05):diffusealpha(0)
		end
		s:queuecommand("UpdateHide")
	end,

	UpdateHideCommand = function(s)
		AnimPlayed = false
	end,

	Def.ActorFrame{
		Def.Sprite{
			Texture = "info",

			InitCommand = function(s)
				s:y(4)
			end,
		},

		LoadFont("_swis721 blk bt 28px")..{
			Name = "Title",

			InitCommand = function(s)
				s:xy(-155, -15):zoom(0.8):halign(0):maxwidth(560):diffuse(Color.Black)
			end,

			SetCommand = function(s)
				local song = GAMESTATE:GetCurrentSong()

				if song then
					s:settext(song:GetDisplayMainTitle())
				end
			end,
		},

		LoadFont("_swis721 blk bt 28px")..{
			Name = "Artist",

			InitCommand = function(s)
				s:xy(-155, 12):zoom(0.5):halign(0):maxwidth(800):diffuse(Color.Black)
			end,

			SetCommand = function(s)
				local song = GAMESTATE:GetCurrentSong()

				if song then
					s:settext(GetArtistName(song))
				end
			end,
		},

		Def.Sprite{
			InitCommand = function(s)
				s:xy(-229, -1)
			end,

			SetCommand = function(s)
				local song = GAMESTATE:GetCurrentSong()

				if song then
					s:LoadSongImage(song, 128, 128, true)
				else
					s:setsize(128, 128)
				end
			end,
		},
	},

	Def.BitmapText{
		Font = "bpm",

		InitCommand = function(s)
			s:xy(-115, 48):halign(0):queuecommand("UpdateBPM")
		end,

		UpdateBPMCommand = function(self)
			self._pendingUpdateBPM = false
			local song = GAMESTATE:GetCurrentSong()

			if not song then
				self:settext("")
				return
			end

			local bpms = {}

			for _, pn in ipairs({PLAYER_1, PLAYER_2}) do
				if GAMESTATE:IsHumanPlayer(pn) then
					local steps = GAMESTATE:GetCurrentSteps(pn)
					local facts = steps and WheelCache.ChartFacts(song, steps)
					local info = facts and facts.bpm

					if info then
						table.insert(bpms, info.min)
						table.insert(bpms, info.max)
					end
				end
			end

			if #bpms == 0 then
				self:settext("")
				return
			end

			table.sort(bpms)

			local min = round(bpms[1], 0)
			local max = round(bpms[#bpms], 0)

			if min == max then
				self:settext(min)
			else
				self:settext(string.format("%d x %d", min, max))
			end
		end,

		CurrentStepsP1ChangedMessageCommand = function(s)
			QueueOnce(s, "UpdateBPM")
		end,

		CurrentStepsP2ChangedMessageCommand = function(s)
			QueueOnce(s, "UpdateBPM")
		end,

		CurrentSongChangedMessageCommand = function(s)
			QueueOnce(s, "UpdateBPM")
		end,
	},

	TimingIcon("shock", HasShockArrows, -148),
	TimingIcon("change", HasBPMChanges, -133),
	TimingIcon("pause", HasStops, -118),
}