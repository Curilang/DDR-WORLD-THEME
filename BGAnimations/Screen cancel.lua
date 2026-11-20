local c = Def.ActorFrame{};
local s = Var "LoadingScreen"
local l = s == "ScreenLogo";

-- ESC in the difficulty selection of the select music screen only goes back to the wheel: no doors.
-- The overlay sets DDRWORLD_InDiff while the difficulty selection is open; when the cancel transition starts
-- (this file is loaded when the screen is built, so it is checked then) the moment is remembered so the next
-- ScreenSelectMusic (in.lua, overlay) is shown without doors and with the wheel fade instead of the entry animation.
c[#c+1] = loadfile(THEME:GetPathB("","_doors"))()..{
	StartTransitioningCommand=function(self)
		if s == "ScreenSelectMusic" and getenv("DDRWORLD_InDiff") then
			setenv("DDRWORLD_BackToWheel", GetTimeSinceStart())
			Trace("Screen cancel: back from the difficulty selection, no doors")
			return
		end
		self:playcommand("Close")
	end,
};
-- c[#c+1] = Def.Quad {
	-- Condition=(Branch.TitleMenu() == "ScreenTitleMenu" or Branch.TitleMenu() == "ScreenTitleJoin");
	-- InitCommand=function(s) s:FullScreen():diffuse(Color.White):diffusealpha(0) end,
	-- OnCommand=function(s) s:linear(0.25):diffusealpha(1) end, 
-- };

return c;