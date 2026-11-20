-- coming back from the difficulty selection with ESC (see TwoPartDiff): the wheel is shown without the doors
local function BackToWheelRecent() local v = getenv("DDRWORLD_BackToWheel"); return type(v) == "number" and GetTimeSinceStart() - v < 1.5 end
-- the filter menu closed with a new filter (BGAnimations/ScreenSortList overlay): the screen is loaded again, no doors
local function FilterReloadRecent() local v = getenv("DDRWORLD_FilterReload"); return type(v) == "number" and GetTimeSinceStart() - v < 1.5 end
if BackToWheelRecent() or FilterReloadRecent() then
	return Def.ActorFrame{}
end

return Def.ActorFrame {
	loadfile(THEME:GetPathB("","_doors"))()..{
		StartTransitioningCommand=function(s) s:playcommand("Open") end,
	};
};