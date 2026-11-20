local pn = ...
local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(pn)

-- ================= LIFE =================
local options = GAMESTATE:GetPlayerState(pn):GetPlayerOptionsArray("ModsLevel_Preferred")
local is4Lives = table.search(options, '4Lives')
local is1Life  = table.search(options, '1Lives')
local flare = FlareGauge.State[pn]

-- ================= DELTA =================
local function FormatWithCommas(n)
	local s = tostring(math.floor(n))
	local sign = ""
	if s:sub(1,1) == "-" then sign = "-" s = s:sub(2) end
	for i = #s - 3, 1, -3 do s = s:sub(1,i) .. "," .. s:sub(i+1) end
	return sign .. s
end

-- ================= COMBO =================
local Steps = GAMESTATE:GetCurrentSteps(pn)
local MaxCombo = pss:MaxCombo()
local SongCombo = 0
if Steps then
	SongCombo = Steps:GetRadarValues(pn):GetValue("RadarCategory_TapsAndHolds")
	-- Con AvoidMineIncrementsCombo cada fila de minas suma 1 al combo.
	-- La función solo existe en tu build; en ITGmania/OutFox se omite.
	if Steps.GetMineRows and THEME:GetMetric("Gameplay", "AvoidMineIncrementsCombo") then
		SongCombo = SongCombo + Steps:GetMineRows()
	end
end

-- ================= SCORE =================
local Score   = pss:GetScore()
local EXScore = math.floor(pss:GetPossibleDancePoints()) * pss:GetPercentDancePoints() + 0.5

-- ================= JUDGES =================
local Marvelous = pss:GetTapNoteScores("TapNoteScore_W1")
local Perfect   = pss:GetTapNoteScores("TapNoteScore_W2")
local Great     = pss:GetTapNoteScores("TapNoteScore_W3")
local Good      = pss:GetTapNoteScores("TapNoteScore_W4")
local Miss      = pss:GetTapNoteScores("TapNoteScore_W5") +
				  pss:GetTapNoteScores("TapNoteScore_Miss")
local MineHit	= pss:GetTapNoteScores("TapNoteScore_HitMine")

local Ok        = pss:GetHoldNoteScores("HoldNoteScore_Held")
				  + (tonumber(getenv("numMineOk"..ToEnumShortString(pn))) or 0) -- avoided mines (one per row) count as O.K.
local NG 		= pss:GetHoldNoteScores("HoldNoteScore_LetGo")

local Fast = getenv("numFast"..ToEnumShortString(pn))
local Slow = getenv("numSlow"..ToEnumShortString(pn))

-- ================= FONTS =================
local function TextFont(font, zoom, halign)
	return Def.BitmapText{ Font=font, InitCommand=function(s) s:zoom(zoom):halign(halign) end }
end
local data = TextFont("_swis721 blk bt 28px",0.667,1)
local fs   = TextFont("_swis721 blk bt 28px",0.667,0.5)
local rolnum = Def.RollingNumbers{ Font="_swis721 blk bt 28px", InitCommand=function(s) s:zoom(0.667):halign(1):Load("RollingNumbersSongData") end }

-- ================= ACTORFRAME =================
return Def.ActorFrame{
	Def.Sprite{ Texture=THEME:GetPathB("ScreenEvaluation","decorations/frame/2/data"), },

	-- LIFE BAR BACKGROUND
	Def.Quad{
		InitCommand=function(s) s:xy(0.5,-45):setsize(498,30):diffuse(color("#525252")) end
	},

	Def.Sprite{
		InitCommand=function(s) s:xy(-4,-45):queuecommand("Set") end,
		SetCommand=function(s)
			local life = _G.FinalLife[pn] or 0
			local visual = is1Life and (life > 0 and 0.25 or 0) or life
			local state
			if is1Life or life <= 0.25 then
				state = "danger"
			elseif life >= 0.999 then
				state = "full"
			else
				state = "normal"
			end
			local ftex = flare and FlareGauge.StreamTex(flare.level)   -- the results screen never uses the danger texture
			s:Load(ftex or THEME:GetPathB("ScreenGameplay","decorations/lifeframe/stream/"..state))
			s:setsize(277,26)
			s:cropright(1 - visual)
			if flare and state ~= "danger" and not ftex then s:diffuse(color(FlareGauge.Colors[flare.level])) end
		end
	},

	-- FLARE effect layer (flare_N_ef) over the final bar.
	Def.Sprite{
		InitCommand=function(s) s:xy(-4,-45):queuecommand("Set") end,
		SetCommand=function(s)
			local life = _G.FinalLife[pn] or 0
			local f = flare and FlareGauge.StreamTex(flare.level, "_ef")
			if not f then s:visible(false) return end
			s:Load(f):setsize(277,26):cropright(1 - life)
		end
	},
	Def.Sprite{
		Texture=THEME:GetPathB("ScreenEvaluation","decorations/frame/2/bar"),
		InitCommand=function(s) s:pause():setstate((is4Lives or is1Life) and 1 or 0) end,
	},

	Def.Sprite{
		Texture=THEME:GetPathB("ScreenEvaluation","decorations/frame/2/gauge 1x13"),
		InitCommand=function(s)s:pause():xy(-175,-45):queuecommand("Set") end,
		SetCommand=function(s)
			-- 13 frames: 0 NORMAL, 1..10 FLARE I..EX, 11 LIFE4, 12 RISKY (for FLOATING, the level it finished with)
			s:setstate(flare and flare.level or (is4Lives and 11 or (is1Life and 12 or 0)))
		end
	},

	data..{
		InitCommand=function(s)s:xy(182,-45):zoom(0.5):halign(0.5):queuecommand("Set") end,
		SetCommand=function(s)
			local life = (_G.FinalLife[pn] or 0) * 100
			s:settext(string.format("%.1f%%", life))
		end
	},
	
	
	Def.ActorFrame{
		InitCommand=function(s) s:y(-3) end,
		-- JUDGMENTS
		data..{ InitCommand=function(s) s:xy(-80,-14):settext(Marvelous) end },
		data..{ InitCommand=function(s) s:xy(-80,4):settext(Perfect) end },
		data..{ InitCommand=function(s) s:xy(-80,21):settext(Great) end },
		data..{ InitCommand=function(s) s:xy(-80,40):settext(Good) end },
		data..{ InitCommand=function(s) s:xy(-80,60):settext(Ok) end },
		data..{ InitCommand=function(s) s:xy(-80,79):settext(Miss) end },
		fs..{ InitCommand=function(s) s:xy(-44,4):settext(Fast) end },
		fs..{ InitCommand=function(s) s:xy(-44,49):settext(Slow) end },

		-- SCORE
		rolnum..{ Name="Score", InitCommand=function(s) s:xy(240,-18):targetnumber(Score) end },

		-- BEST + DELTA
		Def.ActorFrame{
			Name="BestDeltaContainer",
			InitCommand=function(s) s:xy(240,1):queuecommand("Set") end,
			SetCommand=function(s)
				local Song, Steps = GAMESTATE:GetCurrentSong(), GAMESTATE:GetCurrentSteps(pn)
				if not Song or not Steps then return end

				local profile = PROFILEMAN:IsPersistentProfile(pn) and PROFILEMAN:GetProfile(pn) or PROFILEMAN:GetMachineProfile()
				local scores = (profile:GetHighScoreList(Song, Steps) or {GetHighScores=function() return {} end}):GetHighScores()
				local AbsoluteBest = 0
				for _,hs in ipairs(scores) do AbsoluteBest = math.max(AbsoluteBest, hs:GetScore()) end

				local BestScore = Score >= AbsoluteBest and (function()
					local best = 0
					for _,hs in ipairs(scores) do
						local s = hs:GetScore()
						if s < Score and s > best then best = s end
					end
					return best
				end)() or AbsoluteBest

				local DeltaScore = Score - BestScore
				s.DeltaScore = DeltaScore
				s:GetChild("BestScore"):targetnumber(BestScore)
				s:GetChild("DeltaText"):playcommand("Update")
			end,
			rolnum..{ Name="BestScore" },
			data..{
				Name="DeltaText",
				InitCommand=function(s) s:y(20):halign(1) end,
				UpdateCommand=function(s)
					local delta = s:GetParent().DeltaScore or 0
					local sign, col = delta>0 and "+" or delta<0 and "-" or "", delta>0 and color("#28e1af") or delta<0 and color("#d44c19") or Color.White
					s:settext(sign .. FormatWithCommas(math.abs(delta))):diffuse(col)
				end,
			},
		},

		-- EX SCORE
		rolnum..{ InitCommand=function(s) s:xy(240,40):targetnumber(EXScore) end },

		-- COMBO
		data..{ InitCommand=function(s) s:xy(240,58):settext(string.format("%d / %d", MaxCombo, SongCombo)) end },
	},
}