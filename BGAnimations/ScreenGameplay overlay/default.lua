local t = Def.ActorFrame{}

-- DDR timing (see Scripts/00 ArcadeTiming.lua): set again here in case something changed it, and per player
ArcadeTiming.Apply()
ArcadeTiming.ApplyPerPlayer()

for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
	t[#t+1] = LoadActor("FullCombo", pn)
end

-- CONSTANT arrow visibility (see Scripts/08 ConstantVisibility.lua): keeps the Sudden line at the
-- distance that matches the chosen display time.
for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
	local constant = ConstantVis.Actor(pn)
	if constant then t[#t+1] = constant end
end

-- FLARE gauge (see Scripts/08 FlareGauge.lua): tracks the gauge from the judgments and mirrors it onto the
-- engine's life meter so the song fails exactly when the FLARE is lost.
for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
	if FlareGauge.Init(pn) then
		t[#t+1] = Def.Actor{
			OnCommand=function(self) self:queuecommand("Sync") end,
			JudgmentMessageCommand=function(self, param)
				if param.Player ~= pn then return end
				if FlareGauge.Judge(pn, param.TapNoteScore, param.HoldNoteScore) then
					self:playcommand("Apply")
				end
			end,
			ApplyCommand=function(self)
				local screen = SCREENMAN:GetTopScreen()
				local st = FlareGauge.State[pn]
				if not (screen and screen.GetLifeMeter and st) then return end
				-- SetLife lives on the Player actor (not on the LifeMeter) and moves the engine's bar.
				local player = screen:GetChild("Player" .. ToEnumShortString(pn))
				local lm = screen:GetLifeMeter(pn)
				-- The engine takes up to 8% off for a Miss or NG before we can correct it, so a bar close to
				-- zero would end the song on its own. The engine's bar therefore never goes below 9%
				-- (0.09 + 0.91 * gauge) and only empties when the FLARE is really lost.
				local target = st.failed and 0 or (0.09 + 0.91 * st.gauge)
				if player and player.SetLife and math.abs(lm:GetLife() - target) > 0.0005 then
					player:SetLife(target)
				end
			end,
			-- The engine raises life on every hit, so the value is corrected every frame.
			SyncCommand=function(self)
				self:playcommand("Apply")
				self:sleep(1/60):queuecommand("Sync")
			end,
		}
	end
end

return t
