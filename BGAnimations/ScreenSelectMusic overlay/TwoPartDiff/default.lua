--This file uses AddChildFromPath since I need to load as many actors as there are steps
--Thus there are no constructors, it will just take the current song and display for as many
--joined players. And do a lot of crazy stuff to handle two actorframes.
local X_SPACING, Y_SPACING = 5,149;
local function getXSpacing(pn)
	return pn == PLAYER_1 and X_SPACING*-9 or X_SPACING*9
end;


--local song = SONGMAN:FindSong("Ace For Aces")
local song = GAMESTATE:GetCurrentSong()
local songSteps = SongUtil.GetPlayableSteps(song)
assert(#songSteps>0,"Hey idiot, this song has no steps for your game mode")
local numDiffs = #songSteps
--Is defining this even necessary?
local center = math.ceil(numDiffs/2)

--This is the variable for holding the frame after it's compiled
local frame = {
	["PlayerNumber_P1"] = nil,
	["PlayerNumber_P2"] = nil
}
--Take a wild guess.
local selection = {
	["PlayerNumber_P1"] = 1,
	["PlayerNumber_P2"] = 1
}

-- LEVEL SORT (Scripts/08 LevelSort.lua): the screen opens on the chart whose level is the section's level.
local levelTarget = LevelSort and LevelSort.CurrentLevel and LevelSort.CurrentLevel()

for pn in ivalues(GAMESTATE:GetEnabledPlayers()) do
	local foundDiff = false
	if levelTarget then
		local best
		for i,steps in ipairs(songSteps) do
			if steps:GetMeter() == levelTarget
				and (not best or steps:GetDifficulty() == GAMESTATE:GetPreferredDifficulty(pn)) then
				best = i
			end
		end
		if best then
			selection[pn] = best
			GAMESTATE:SetCurrentSteps(pn,songSteps[best])
			foundDiff = true
		end
	end
	-- the chart selected on the wheel (a chart picked with the difficulty panel does not always update the preferred difficulty)
	if not foundDiff then
		local cur = GAMESTATE:GetCurrentSteps(pn)
		if cur then
			for i,steps in ipairs(songSteps) do
				if steps:GetDifficulty() == cur:GetDifficulty()
					and (cur:GetDifficulty() ~= 'Difficulty_Edit' or steps:GetDescription() == cur:GetDescription()) then
					selection[pn] = i
					GAMESTATE:SetCurrentSteps(pn,steps)
					foundDiff = true
					break
				end
			end
		end
	end
	if not foundDiff and GAMESTATE:GetPreferredDifficulty(pn) then
		for i,steps in ipairs(songSteps) do
			if steps:GetDifficulty() == GAMESTATE:GetPreferredDifficulty(pn) then
				selection[pn] = i
				GAMESTATE:SetCurrentSteps(pn,steps)
				foundDiff = true
			end;
		end;
	end;
	if not foundDiff then
		GAMESTATE:SetCurrentSteps(pn,songSteps[1])
	end;
end;


local function adjustScrollerFrame(pn, instant)
	for i = 1, numDiffs do
		local is_focus = (i == selection[pn])
		local item = frame[pn]:GetChild(i)

		item:playcommand("Focus", {focused = is_focus})
		item:stoptweening()

		if not instant then
			item:decelerate(0.2)
		end

		item:zoom(is_focus and 1 or 0.7)
		item:xy(
			math.abs(i-selection[pn])*getXSpacing(pn),
			(i-selection[pn])*Y_SPACING
		)
		item:GetChild("Highlight"):visible(is_focus)
	end
end

local function genScrollerFrame(pn)
	local f = Def.ActorFrame{};
	for i,steps in ipairs(songSteps) do
		local diff = steps:GetDifficulty();
		f[i] = Def.ActorFrame{
			InitCommand=cmd(xy,math.abs(i-center)*getXSpacing(pn),(i-center)*Y_SPACING);
			["OK"..pn.."MessageCommand"]=function(s)
				s:queuecommand("Out")
			end,
			OffCommand=function(s) s:playcommand("OK"..pn) end,
			-- StartSelectingStepsMessageCommand=function(s) end, --I don't know how this works
			Name=i;
			
			Def.ActorFrame{
				Def.Sprite{
					InitCommand=function(s)
						local player = (pn == PLAYER_1) and "P1_OFF_" or "P2_OFF_";
						local graph = player..ToEnumShortString(diff)..".png";
						s:Load(THEME:GetPathB("ScreenSelectMusic","overlay/TwoPartDiff/"..graph))
					end,
				};
				Def.Sprite{
					InitCommand=function(s) s:visible(false)
						local player = (pn == PLAYER_1) and "P1_ON_" or "P2_ON_";
						local graph = player..ToEnumShortString(diff)..".png";
						s:Load(THEME:GetPathB("ScreenSelectMusic","overlay/TwoPartDiff/"..graph))
					end,
					FocusCommand=function(s, params)
						s:visible(params.focused)
					end,
				};
			};
			Def.ActorFrame{
				Name="Highlight";
				StripeLine{
					Name = "Line", 
					w = 128, h = 6, x=pn==PLAYER_1 and -54 or 54, y = 43, count = 13, visible = true,
				},
				StripeLine{
					Name = "Line", 
					w = 107, h = 6, x=pn==PLAYER_1 and 64 or -64, y = 53, count = 11, visible = true,
				},
			};
			Def.ActorFrame{
				InitCommand=function(s) s:xy(pn==PLAYER_1 and 54 or -81,13) end,
				LoadFont("OFF_difficulty numbers")..{
					Text=steps:GetMeter();
				};
				LoadFont("ON_difficulty numbers")..{
					Text=steps:GetMeter();
					InitCommand=function(s) s:shadowlength(2.5):visible(false) end,
					FocusCommand=function(s, params)
						s:visible(params.focused)
					end,
				};
			};
			Def.ActorFrame{
				InitCommand=function(s) s:xy(pn==PLAYER_1 and -110 or -80,-59):zoom(1) end,
				-- FLARE earned on this chart, to the right of the clear mark (the textures are the music wheel's:
				-- Graphics/MusicWheelItem Song NormalPart/flare/flare_N.png, there is only one copy of them)
				Def.Sprite{
					InitCommand=function(s)
						-- player 2 is the mirror image: the FLARE goes to the LEFT of the clear mark (96 - 34) instead of the right (96 + 34)
						s:xy(pn==PLAYER_1 and 130 or 62,34):zoom(1.09):visible(false):queuecommand("Set")
					end,
					SetCommand=function(s)
						local st = GAMESTATE:GetCurrentStyle():GetStepsType()
						local steps = song:GetOneSteps(st,diff)
						local level = steps and FlareGauge.GetClear(pn, song, steps)
						local f = level and FlareGauge.WheelFile("flare/flare_"..level)
						if f then s:Load(f):visible(true) end
					end,
				};
				Def.Sprite{
					InitCommand=function(s) s:queuecommand("Set"):xy(96,20):zoom(0.16) end,
					SetCommand=function(s)
						local profile = MachineOrProfile(pn)
						local st = GAMESTATE:GetCurrentStyle():GetStepsType()
						local steps = song:GetOneSteps(st,diff)
						local scorelist = profile:GetHighScoreList(song,steps)
						local scores = scorelist:GetHighScores()
						local topgrade;
						if scores[1] then
						topgrade = scores[1]:GetGrade();
						assert(topgrade)
							local tier = topgrade
							if scores[1]:GetScore()>1  then
								if topgrade == 'Grade_Failed' then
									s:LoadBackground(THEME:GetPathG("","Grade/Grade_Failed"));
								else
									s:LoadBackground(THEME:GetPathG("","Grade/Grade_"..ToEnumShortString(tier)));
								end
								s:visible(true)
							else
								s:visible(false)
							end
						else
							s:visible(false)
						end
					end,
				};
				Def.Sprite{
					InitCommand=function(s) s:queuecommand("Set"):xy(96,38) end,
					SetCommand=function(s)
						local profile = MachineOrProfile(pn)
						local st = GAMESTATE:GetCurrentStyle():GetStepsType()
						local steps = song:GetOneSteps(st,diff)
						local scorelist = profile:GetHighScoreList(song,steps)
						local scores = scorelist:GetHighScores()
						local topscore;
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
									s:Load(THEME:GetPathG("","_shared/cleared/MarvelousFullCombo"))
								elseif greats == 0 then
									s:Load(THEME:GetPathG("","_shared/cleared/PerfectFullCombo"))
								elseif (misses+goods) == 0 then
									s:Load(THEME:GetPathG("","_shared/cleared/GreatFullCombo"))
								elseif (misses) == 0 then
									s:Load(THEME:GetPathG("","_shared/cleared/GoodFullCombo"))
									
								end
								s:visible(true)
							else
								if topscore:GetGrade() ~= 'Grade_Failed' then
									if hasUsedBattery then
										s:visible(true)
										s:Load(THEME:GetPathG("","_shared/cleared/Gauge"))
									else
										s:visible(true)
										s:Load(THEME:GetPathG("","_shared/cleared/LifeBar"))
									end
								else
									s:visible(false)
								end
							end
						else
							s:visible(false)
						end
					end
				};
				
			};
			Def.ActorFrame{
				InitCommand=function(s) s:x(pn==PLAYER_1 and 108 or -112):visible(false) end,				FocusCommand=function(s,p) s:visible(p.focused) end,
				Def.Sprite{
					Texture=THEME:GetPathB("ScreenSelectMusic", "overlay/Info/Shock"),
					InitCommand=function(s)
						s:y(-20):zoom(0.95):visible(false):queuecommand("Set")
					end,
					SetCommand = function(s)
						local song = GAMESTATE:GetCurrentSong()
						local steps = song and song:GetOneSteps(GAMESTATE:GetCurrentStyle():GetStepsType(),diff)
						local radar = steps and steps:GetRadarValues(pn)
						local mines = radar and radar:GetValue("RadarCategory_Mines")
						s:visible(mines and mines >= 1 or false)
					end,
				},
				Def.Sprite{
					Texture=THEME:GetPathB("ScreenSelectMusic", "overlay/Info/change"),
					InitCommand=function(s)
						s:x(2):zoom(0.95):visible(false):queuecommand("Set")
					end,
					SetCommand = function(s)
						local song = GAMESTATE:GetCurrentSong()
						local steps = song and song:GetOneSteps(GAMESTATE:GetCurrentStyle():GetStepsType(),diff)
						local info = GetChartBPMInfo(song, steps)
						s:visible(info and info.hasChange or false)
					end,
				},
				Def.Sprite{
					Texture=THEME:GetPathB("ScreenSelectMusic", "overlay/Info/pause"),
					InitCommand=function(s)
						s:y(20):zoom(0.95):visible(false):queuecommand("Set")
					end,
					SetCommand=function(s)
						local song = GAMESTATE:GetCurrentSong()
						local steps = song and song:GetOneSteps(GAMESTATE:GetCurrentStyle():GetStepsType(),diff)
						local timing = steps and steps:GetTimingData()
						local stops = timing and timing:GetStops()
						s:visible(stops and #stops > 0 or false)
					end,
				},
			};
			Def.ActorFrame{
				InitCommand=function(s) s:x(pn==PLAYER_1 and 0 or 55) end,
				Def.Sprite{
					Texture="best",
					InitCommand=function(s) s:xy(-5,17):visible(false):queuecommand("Set") end,
					SetCommand=function(self)
						local st = GAMESTATE:GetCurrentStyle():GetStepsType()
						local song = GAMESTATE:GetCurrentSong()
						if song then
							if song:HasStepsTypeAndDifficulty(st,diff) then
								local steps = song:GetOneSteps(st,diff)
								local profile = MachineOrProfile(pn)
								local scorelist = profile:GetHighScoreList(song,steps)
								local scores = scorelist:GetHighScores()
								local topscore = 0
								if scores[1] then
									topscore = scores[1]:GetScore()
								end;
								if topscore ~= 0 then
									self:visible(true)
								end;
							end;
						end;
					end;
				};
				Def.Sprite{
					Texture="base",
					InitCommand=function(s) s:xy(-25,29):setsize(90,16):visible(false):queuecommand("Set") end,
					SetCommand=function(self)
						local st = GAMESTATE:GetCurrentStyle():GetStepsType()
						local song = GAMESTATE:GetCurrentSong()
						if song then
							if song:HasStepsTypeAndDifficulty(st,diff) then
								local steps = song:GetOneSteps(st,diff)
								local profile = MachineOrProfile(pn)
								local scorelist = profile:GetHighScoreList(song,steps)
								local scores = scorelist:GetHighScores()
								local topscore = 0
								if scores[1] then
									topscore = scores[1]:GetScore()
								end;
								if topscore ~= 0 then
									self:visible(true)
								end;
							end;
						end;
					end;
				};
				Def.BitmapText{
					Font="Score Numbers",
					InitCommand=function(s) s:diffuse(Color.White):xy(10,52):halign(1):queuecommand("Set") end,
					SetCommand=function(self) self:settext("")
						local st = GAMESTATE:GetCurrentStyle():GetStepsType()
						local song = GAMESTATE:GetCurrentSong()
						if song then
							if song:HasStepsTypeAndDifficulty(st,diff) then
								local steps = song:GetOneSteps(st,diff)
								local profile = MachineOrProfile(pn)
								local scorelist = profile:GetHighScoreList(song,steps)
								local scores = scorelist:GetHighScores()
								local topscore = 0
								if scores[1] then
									topscore = scores[1]:GetScore()
								end;
								if topscore ~= 0 then
									self:settext(commify(topscore))
								end;
							end;
						end;
					end;
				};
			};
			Def.ActorFrame{
				Name="Ok",
				InitCommand=function(s) s:xy(pn==PLAYER_1 and -105 or -77,8) end,
                Def.Sprite{
					Texture="ready",
					InitCommand=function(s) s:diffusealpha(0):rotationy(-90):zoom(1.2):xy(63,58) end,
					OutCommand=function(s)
						if i == selection[pn] then
							s:diffusealpha(1):linear(0.1):zoom(1):rotationy(0)
						end
					end,
				};
				Def.Sprite{
					Texture="dot",
					InitCommand=function(s) s:diffusealpha(0):zoom(1):xy(166,69) end,
					AnimateCommand=function(s) s:sleep(0.2):diffusealpha(0):sleep(0.1):diffusealpha(1):sleep(0.3):queuecommand("Animate") end,
					OutCommand=function(s)
						if i == selection[pn] then
							s:sleep(0.2):diffusealpha(1):playcommand("Animate")
						end
					end,
				};
				Def.Sprite{
					Texture="dot",
					InitCommand=function(s) s:diffusealpha(0):zoom(1):xy(185,69) end,
					AnimateCommand=function(s) s:sleep(0.1):diffusealpha(0):sleep(0.2):diffusealpha(1):sleep(0.3):queuecommand("Animate") end,
					OutCommand=function(s)
						if i == selection[pn] then
							s:sleep(0.3):diffusealpha(1):playcommand("Animate")
						
						end
					end,
				};
				Def.Sprite{
					Texture="dot",
					InitCommand=function(s) s:diffusealpha(0):zoom(1):xy(203,69) end,
					AnimateCommand=function(s) s:diffusealpha(0):sleep(0.3):diffusealpha(1):sleep(0.3):queuecommand("Animate") end,
					OutCommand=function(s)
						if i == selection[pn] then
							s:sleep(0.4):diffusealpha(1):playcommand("Animate")
						
						end
					end,
				};
			};
		};
	end;
	
	f[#f+1] = Def.Sprite{
		InitCommand=function(s) s:y(-14)
			local player = (pn == PLAYER_1) and "P1_" or "P2_";
			s:Load(THEME:GetPathB("ScreenSelectMusic","overlay/TwoPartDiff/"..player.."text"))
		end,
	};
	return f;
end;

local keyset={0,0}

-- ============================================================================
-- OPTION / Back buttons and the SPEED / GAUGE box: to the left of the selected difficulty (to the right for player 2).
--   LEFT (RIGHT for player 2) moves the cursor onto the two buttons, UP / DOWN choose between them, START presses
--   the one chosen and RIGHT (LEFT for player 2) goes back to the difficulties. In the buttons UP / DOWN no longer
--   change the difficulty (the engine's screen input is switched off for that player, see SetRedirect). LEFT + RIGHT
--   together (the engine opens the player options) and UP + DOWN together (the engine goes back to the wheel) work from
--   the difficulties as before.
--   OPTION opens the player options, Back does what ESC does. Back is always there in Event Mode; with the timer on it
--   disappears BACK_HIDE_AFTER seconds after the difficulty selection opened.
-- Textures (this folder): diff_base, icon_options, icon_back, diff_options_txt 1x3, diff_back_txt 1x3 (frame = language:
-- en, jp, kor) and diff_options (the SPEED / GAUGE box). The SPEED and GAUGE values are the ones of the player options.
-- ============================================================================
local BOX_X, BOX_Y = 217.5, 211      -- centre of the base from the left edge (player 2: from the right edge), in theme units
local BACK_HIDE_AFTER = 30           -- seconds
local TEXT_COLOR = color("#3BE8D0")  -- the SPEED / GAUGE values
-- Selected button: a solid orange bar, no animation (colour measured 152,89,0 on the original's screenshot).
local HILITE_COLOR = color("#985900")
local openedAt = GetTimeSinceStart()
local btn = { [PLAYER_1] = { on = false, idx = 1 }, [PLAYER_2] = { on = false, idx = 1 } }   -- idx 1 = OPTION, 2 = Back
local held = { [PLAYER_1] = {}, [PLAYER_2] = {} }                                           -- buttons held down, per player
local btnUI = {}

local function BackAvailable()
	if GAMESTATE:IsEventMode() then return true end
	if not PREFSMAN:GetPreference("MenuTimer") then return true end
	return GetTimeSinceStart() - openedAt <= BACK_HIDE_AFTER
end

local function RefreshButtons(pn)
	local ui = btnUI[pn]
	if not ui then return end
	local backOn = BackAvailable()
	if btn[pn].idx > (backOn and 2 or 1) then btn[pn].idx = 1 end
	ui.back:visible(backOn)
	ui.hiOption:visible(btn[pn].on and btn[pn].idx == 1)
	ui.hiBack:visible(btn[pn].on and btn[pn].idx == 2)
end

-- SPEED: min ~ core ~ max of the scroll speed on this chart; GAUGE: the dance gauge chosen (Scripts/08 PlayerOptionsRows.lua)
local function RefreshInfo(pn)
	local ui = btnUI[pn]
	if not ui then return end
	local speed, gauge = "", ""
	pcall(function()
		local rows = POMenu and POMenu.Rows
		local info = rows and rows.SpeedInfo and rows.SpeedInfo.info(pn)
		if info then speed = string.format("%d ~ %d ~ %d", info.min, info.core, info.max) end
		local g = rows and rows.Gauge
		if g then gauge = tostring(g.text(pn, g.get(pn))) end
	end)
	ui.speed:settext(speed)
	ui.gauge:settext(gauge)
end

-- While the cursor is on the buttons the engine must not see the player's input (it would change the difficulty with
-- UP / DOWN and start the song with START). The input callbacks (this file) are still given everything: the engine's own
-- screen input is switched off for that player (SCREENMAN:set_input_redirected). A callback returning true does NOT keep
-- the event from the engine. Always switched back on when the cursor leaves the buttons, and when the screen goes away.
local redirected = { [PLAYER_1] = false, [PLAYER_2] = false }
local function SetRedirect(pn, on)
	if redirected[pn] == on then return end
	redirected[pn] = on
	pcall(function()
		if SCREENMAN.set_input_redirected then SCREENMAN:set_input_redirected(pn, on) end
	end)
end

local function ReleaseInput()
	setenv("DDRWORLD_TwoPartOpen", nil)   -- NUEVO
	for _, pn in ipairs({ PLAYER_1, PLAYER_2 }) do
		btn[pn].on = false
		SetRedirect(pn, false)
	end
end

-- What LEFT + RIGHT does: the player options, on top of this screen
local function OpenOptions(pn)
	SetRedirect(pn, false)
	btn[pn].on = false
	RefreshButtons(pn)
	SCREENMAN:AddNewScreenToTop(THEME:GetMetric("ScreenSelectMusic", "SelectMenuScreenName"), "SM_BackFromPlayerOptions")
end

local function PressButton(pn)
	local screen = SCREENMAN:GetTopScreen()
	if not screen then return end
	pcall(function() SOUND:PlayOnce(THEME:GetPathS("Common", "start")) end)
	if btn[pn].idx == 1 then
		OpenOptions(pn)
	elseif BackAvailable() then
		ReleaseInput()
		screen:Cancel()   -- what ESC does
	end
end

-- The engine may react to the LEFT / RIGHT that moves the cursor between the difficulties and the buttons (it can change the
-- difficulty): one frame later the difficulty is put back where the player left it.
local function QueueFix(pn)
	local ui = btnUI[pn]
	if ui and ui.ticker then ui.ticker:queuecommand("Fix") end
end

local function RestoreSteps(pn)
	local steps = songSteps[selection[pn]]
	local cur = GAMESTATE:GetCurrentSteps(pn)
	if steps and (not cur or cur:GetDifficulty() ~= steps:GetDifficulty()) then
		GAMESTATE:SetCurrentSteps(pn, steps)
		GAMESTATE:SetPreferredDifficulty(pn, steps:GetDifficulty())
		adjustScrollerFrame(pn)
	end
end

-- Returns true when the event was dealt with here, and then what the input callback must return (see above: it does not
-- matter for the engine, only for the other callbacks).
local function ButtonsInput(event)
	local pn, button = event.PlayerNumber, event.button
	if not (pn and held[pn]) then return false end
	if event.type == "InputEventType_Release" then
		held[pn][button] = nil
		return false
	end
	held[pn][button] = true
	if not GAMESTATE:IsPlayerEnabled(pn) or keyset[pn] == 1 then return false end

	local toButtons = (pn == PLAYER_1) and "MenuLeft" or "MenuRight"
	local toDiff = (pn == PLAYER_1) and "MenuRight" or "MenuLeft"
	local first = event.type == "InputEventType_FirstPress"
	local b = btn[pn]

	if button == toButtons or button == toDiff then
		if held[pn][toButtons] and held[pn][toDiff] then
			-- LEFT + RIGHT together: the player options (the engine's own code). The engine is given the input back; if it does
			-- not open the options by itself (it may not have seen this event) they are opened here a moment later.
			if first then
				b.on = false
				SetRedirect(pn, false)
				RefreshButtons(pn)
				local ui = btnUI[pn]
				if ui and ui.chord then ui.chord:queuecommand("Check") end
			end
			return true, false
		end
		if first then
			local on = (button == toButtons)
			if b.on ~= on then
				b.on = on
				if on then b.idx = 1 end
				SetRedirect(pn, on)
				SOUND:PlayOnce(THEME:GetPathS("","WORLD/SelectDifficulty side"))
				RefreshButtons(pn)
			end
			QueueFix(pn)
		end
		return true, true
	end

	if b.on then
		if button == "MenuUp" or button == "MenuDown" then
			local new = b.idx + (button == "MenuUp" and -1 or 1)
			if new >= 1 and new <= (BackAvailable() and 2 or 1) and new ~= b.idx then
				b.idx = new
				SOUND:PlayOnce(THEME:GetPathS("","WORLD/SelectDifficulty side"))
				RefreshButtons(pn)
			end
			return true, true
		elseif button == "Start" then
			if first then PressButton(pn) end
			return true, true
		elseif button == "Back" then
			-- ESC: the engine does not get it while it is redirected
			if first then
				ReleaseInput()
				local screen = SCREENMAN:GetTopScreen()
				if screen then screen:Cancel() end
			end
			return true, true
		end
		return true, true   -- (anything else is ignored while the cursor is on the buttons)
	end
	return false
end
local function genButtons(pn)
	local side = (pn == PLAYER_1) and 1 or -1
	local ui = {}
	btnUI[pn] = ui
	local text = function(file, x, y)
		return Def.Sprite{
			Texture=file,
			InitCommand=function(s) s:xy(x, y):pause():setstate(GetCurrentLanguage()) end,
		}
	end
	local hilite = function(y, key)
		return Def.Quad{
			InitCommand=function(s)
				ui[key] = s
				s:setsize(110, 30):xy(0, y):visible(false)   -- 110 x 30 px at 720p, centred on the base (measured)
				s:diffuse(HILITE_COLOR)
			end,
		}
	end
	-- everything is placed in pixels of the 720p picture (the original's), hence the 0.667 zoom of the whole frame
	return Def.ActorFrame{
		InitCommand=function(s)
			s:xy(pn == PLAYER_1 and SCREEN_LEFT + BOX_X or SCREEN_RIGHT - BOX_X, BOX_Y):zoom(0.667):diffusealpha(0)
			s:queuecommand("Entrance")
		end,
		EntranceCommand=function(s)
			s:addx(-100 * side):decelerate(0.2):addx(100 * side):diffusealpha(1)
		end,
		Def.Sprite{ Texture="diff_base.png" },
		hilite(-28.5, "hiOption"),
		Def.Sprite{ Texture="icon_options.png", InitCommand=function(s) s:xy(-36.5, -28.5) end },
		text("diff_options_txt 1x3.png", 13.5, -28),
		Def.ActorFrame{
			InitCommand=function(s) ui.back = s end,
			hilite(7.5, "hiBack"),
			Def.Sprite{ Texture="icon_back.png", InitCommand=function(s) s:xy(-36.5, 7.5) end },
			text("diff_back_txt 1x3.png", 15.5, 8),
		},
		-- SPEED / GAUGE: white box that overlaps the bottom of the base; the values sit on its two black bars
		Def.ActorFrame{
			InitCommand=function(s) s:xy(-19 * side, 46.3) end,
			Def.Sprite{ Texture="diff_options.png" },
			Def.BitmapText{
				Font="Options Text",
				InitCommand=function(s)
					ui.speed = s
					s:xy(14, -6.5):zoom(0.55):maxwidth(88 / 0.55):diffuse(TEXT_COLOR)
				end,
			},
			Def.BitmapText{
				Font="Options Text",
				InitCommand=function(s)
					ui.gauge = s
					s:xy(14, 6.5):zoom(0.55):maxwidth(88 / 0.55):diffuse(TEXT_COLOR)
				end,
			},
		},
		-- LEFT + RIGHT: if the engine has not opened the player options a second after the chord, they are opened here
		Def.Actor{
			InitCommand=function(s) ui.chord = s end,
			CheckCommand=function(s) s:sleep(1):queuecommand("Open") end,
			OpenCommand=function(s)
				local screen = SCREENMAN:GetTopScreen()
				if not getenv("DDRWORLD_POMenuOpen") and screen and screen:GetName() == "ScreenSelectMusic" then OpenOptions(pn) end
			end,
		},
		-- keeps the box up to date (the back button goes away with the timer; the speed follows the chart; the options
		-- menu may have changed both)
		Def.Actor{
			InitCommand=function(s) ui.ticker = s; s:queuecommand("Boot") end,
			FixCommand=function(s) RestoreSteps(pn) end,
			BootCommand=function(s) RefreshInfo(pn); RefreshButtons(pn); s:queuecommand("Tick") end,
			TickCommand=function(s) RefreshButtons(pn); s:sleep(0.5):queuecommand("Tick") end,
			["CurrentSteps"..ToEnumShortString(pn).."ChangedMessageCommand"]=function(s) RefreshInfo(pn) end,
			-- the options menu takes the input: nothing is held when it closes, and the cursor goes back to the difficulties
			POMenuOpenedMessageCommand=function(s) held[pn] = {}; SetRedirect(pn, false) end,
			POMenuClosingMessageCommand=function(s)
				held[pn] = {}
				btn[pn].on = false
				RefreshInfo(pn)
				RefreshButtons(pn)
			end,
		},
	}
end

local function DiffInputHandler(event)
	local pn= event.PlayerNumber
	local button = event.button
	local handled, result = ButtonsInput(event)
	if handled then return result end
	if event.type == "InputEventType_Release" then return end
	-- going back to the wheel (ESC): the screen is reloaded by the engine; it is done without the doors, see
	-- "Screen cancel.lua" and "ScreenSelectMusic in.lua"
	if button == "MenuUp" and selection[pn] > 1 and GAMESTATE:IsPlayerEnabled(pn) and keyset[pn] ~= 1 then
		SOUND:PlayOnce(THEME:GetPathS("","WORLD/SelectDifficulty Change"));
		selection[pn] = selection[pn] - 1
		GAMESTATE:SetCurrentSteps(pn,songSteps[selection[pn]])
		GAMESTATE:SetPreferredDifficulty(pn,songSteps[selection[pn]]:GetDifficulty())
		adjustScrollerFrame(pn)
		MESSAGEMAN:Broadcast("TwoDiffLeft"..pn)
		return false;
	elseif button == "MenuDown" and selection[pn] < numDiffs and GAMESTATE:IsPlayerEnabled(pn) and keyset[pn] ~= 1 then
		SOUND:PlayOnce(THEME:GetPathS("","WORLD/SelectDifficulty Change"));
		selection[pn] = selection[pn] + 1
		GAMESTATE:SetCurrentSteps(pn,songSteps[selection[pn]])
		GAMESTATE:SetPreferredDifficulty(pn,songSteps[selection[pn]]:GetDifficulty())
		MESSAGEMAN:Broadcast("TwoDiffRight"..pn)
		adjustScrollerFrame(pn)
		return true;
	elseif (button == "Start") and GAMESTATE:IsPlayerEnabled(pn) then
		keyset[pn] = 1
		MESSAGEMAN:Broadcast("OK"..pn)
	else
	end;
end;

local t = Def.ActorFrame{
	InitCommand=function(s)
		setenv("DDRWORLD_BackToWheel", nil)
		setenv("DDRWORLD_TwoPartOpen", true)   -- NUEVO
		s:sleep(0.5):queuecommand("Add")
		SCREENMAN:GetTopScreen():SetPrevScreenName("ScreenSelectMusic")
	end,
	AddCommand=function(s)
		SCREENMAN:GetTopScreen():AddInputCallback(DiffInputHandler)
	end,
	SongUnchosenMessageCommand=function(s) 
		setenv("DDRWORLD_TwoPartOpen", nil)    -- NUEVO
		SCREENMAN:GetTopScreen():RemoveInputCallback(DiffInputHandler)
		ReleaseInput()
		s:sleep(0.1):linear(0.2):diffusealpha(0) 
	end,
	OffCommand=function(s)
		setenv("DDRWORLD_TwoPartOpen", nil)    -- NUEVO
		SCREENMAN:GetTopScreen():RemoveInputCallback(DiffInputHandler)
		ReleaseInput()
		s:sleep(0.5):linear(0.05):diffusealpha(0) end,
	
	genScrollerFrame(PLAYER_1)..{
		Condition=GAMESTATE:IsSideJoined(PLAYER_1);
		InitCommand=function(self)
			frame[PLAYER_1] = self
			adjustScrollerFrame(PLAYER_1, true)
			self:xy(SCREEN_LEFT+344, SCREEN_CENTER_Y-26)
			self:zoom(0.667)
			self:diffusealpha(0)
			self:queuecommand("Entrance")
		end;

		EntranceCommand=function(self)
			self:addx(-100)
			self:decelerate(0.2)
			self:addx(100):diffusealpha(1)
		end;
	};

	genScrollerFrame(PLAYER_2)..{
		Condition=GAMESTATE:IsSideJoined(PLAYER_2);

		InitCommand=function(self)
			frame[PLAYER_2] = self
			adjustScrollerFrame(PLAYER_2, true)

			self:xy(SCREEN_RIGHT-344, SCREEN_CENTER_Y-26)
			self:zoom(0.667)
			self:diffusealpha(0)
			self:queuecommand("Entrance")
		end;

		EntranceCommand=function(self)
			self:addx(100)
			self:decelerate(0.2)
			self:addx(-100):diffusealpha(1)
		end;
	};
	Def.Sprite{
		Texture="text",
		InitCommand=function(s) s:xy(_screen.cx,_screen.b-70):zoom(0.667):pause():setstate(GetCurrentLanguage()) end,
	};
	genButtons(PLAYER_1)..{ Condition=GAMESTATE:IsSideJoined(PLAYER_1) };
	genButtons(PLAYER_2)..{ Condition=GAMESTATE:IsSideJoined(PLAYER_2) };
	SOUND:PlayOnce(THEME:GetPathS("WORLD/SelectDifficulty","in"));
}

t[#t+1] = Def.ActorFrame{
	InitCommand=function(s) s:xy(_screen.cx,_screen.b-40) end,
	Def.Quad{
		InitCommand=function(s) s:diffuse(Color.Black):setsize(SCREEN_WIDTH,40):y(21) end,
	};
	Def.Sprite{
		Texture=THEME:GetPathG("ScreenWithMenuElements","footer/"..GetLanguage().."tex"),
		InitCommand=function(s) s:zoom(0.667):y(15):pause():setstate(4) end,
	};
};

return t;
