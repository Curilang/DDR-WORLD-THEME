-- Animation played when the options menu is CANCELLED (ESC / Back).
-- Without this file the engine uses "Screen cancel.lua", which is the doors animation.
-- Here the menu closes itself instead: the dark background and the panels fade out
-- ("ScreenPlayerOptions overlay/default.lua" listens for the POMenuClosing message).
return Def.ActorFrame {
	StartTransitioningCommand=function(self)
		MESSAGEMAN:Broadcast("POMenuClosing")
		self:sleep(0.03)   -- the original closes in one frame: the menu is gone and the wheel is back at once
	end,
};
