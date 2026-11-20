local StageDisplay = Def.ActorFrame{
	BeginCommand=function(s) s:playcommand("Set") end,
	CurrentSongChangedMessageCommand=function(s) s:finishtweening():playcommand("Set") end,
};

if GAMESTATE:IsCourseMode() then
	StageDisplay[#StageDisplay+1] = LoadFont("_gibson bold")..{
		Text="",
		SetCommand=function(self)
			local CourseIndex = GAMESTATE:GetCourseSongIndex()+1
			local TrailEntries = #GAMESTATE:GetCurrentTrail(GAMESTATE:GetMasterPlayerNumber()):GetTrailEntries()
			if CourseIndex == TrailEntries then 
				self:settext("FINAL")
			else
				self:settext(FormatNumberAndSuffix(tostring(CourseIndex)))
			end
		end,
		DoneLoadingNextSongMessageCommand=function(s) s:queuecommand("Set") end,
	};
end

return Def.ActorFrame {
	Def.Sprite{
		InitCommand=function(s) s:xy(_screen.cx,SCREEN_TOP+10):zoom(0.667):queuecommand("Set") end,
		SetCommand=function(s) 
			if GAMESTATE:IsDemonstration() then
				s:Load(THEME:GetPathB("ScreenGameplay","decorations/StageFrame/demo"))
			else
				s:Load(THEME:GetPathB("ScreenGameplay","decorations/StageFrame/gameplay"))
			end
		end,
	};
	
	Def.Sprite {
		Texture="stages",
		BeginCommand=function(s) s:playcommand("Set") end,
		CurrentSongChangedMessageCommand=function(s) s:finishtweening():playcommand("Set") end,
		InitCommand = function(self) self:zoom(0.667):xy(_screen.cx, SCREEN_TOP+22):pause() end,
		SetCommand = function(self)
			if GAMESTATE:IsDemonstration() then self:visible(false) return end
			self:visible(true)
			local stage = 0
			if GAMESTATE:IsEventMode() then
				stage = 7
			else
				local thed_stage = thified_curstage_index(false)
				if thed_stage == "1st" then
					stage = 0
				elseif thed_stage == "2nd" then
					stage = 1
				elseif thed_stage == "3rd" then
					stage = 2
				elseif thed_stage == "4th" then
					stage = 3
				elseif thed_stage == "Final" then
					stage = 4
				elseif thed_stage == "Extra1" then
					stage = 5
				elseif thed_stage == "Extra2" then
					stage = 6
				end
			end
			self:setstate(stage)
		end
	};
};