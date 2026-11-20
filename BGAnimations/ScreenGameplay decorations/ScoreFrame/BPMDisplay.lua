local pn = ({...})[1]

local function UpdateSingleBPM(self)
	local bpmDisplay = self:GetChild("BPMDisplay")
	local ps = GAMESTATE:GetPlayerState(pn)
	local songPos = ps:GetSongPosition()
	local po = ps:GetPlayerOptions("ModsLevel_Current")

	if songPos:GetFreeze() or songPos:GetDelay() then
		bpmDisplay:settext("0000")
		return
	end

	local curBPM = songPos:GetCurBPS() * 60
	local displayBPM = curBPM * po:ScrollSpeed()

	if displayBPM > 9999 then
		bpmDisplay:settext("9999")
	else
		bpmDisplay:settext(string.format("%04.0f", displayBPM))
	end
end

return Def.ActorFrame{
	InitCommand=function(s) s:SetUpdateFunction(UpdateSingleBPM) end,

	Def.BitmapText{
		Name="BPMDisplay",
		Font="_arial black 28px",
		InitCommand=function(s)
			s:draworder(101):zoomx(0.6):zoomy(0.7):y(-1):diffuse(color("#14caac"))
		end,
	},

	Def.BitmapText{
		Font="_arial black 28px",
		InitCommand=function(s)
			s:settext("SPEED"):zoom(0.4):y(13):diffuse(color("#14caac"))
		end,
	},
}
