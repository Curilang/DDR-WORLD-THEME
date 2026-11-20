local lap = 2.3
local pos = 228
local zo = 0.667
local za = zo+0.04
local zx = zo-0.005
local rz = 0.8

-- The dark panel behind the music wheel (the original has it as a black texture): solid, it does not move with the wheel,
-- and it hides the background behind the cards while they turn. Drawn here, in the background layer, so it is below the wheel.
local PANEL_ALPHA = 0.8
local PANEL_WIDTH = 0.325    -- fraction of the screen width (the three columns of cards are 0.311 wide)


return Def.ActorFrame{
	LoadActor(THEME:GetPathB("ScreenWithMenuElements","background")); 
	Def.Sprite{
		Texture="P1",
		InitCommand=function(s) s:xy(_screen.cx-pos,_screen.cy):zoom(zo):queuecommand("Anim") end,
		AnimCommand=function(s) 
			s:linear(lap):rotationz(-rz):zoomx(zx):zoomy(za):addy(-2)
			s:linear(lap):rotationz(0):zoom(zo):addy(2)
			s:linear(lap):rotationz(rz):zoomx(zx):zoomy(za):addy(-2)
			s:linear(lap):rotationz(0):zoom(zo):addy(2)
			s:queuecommand("Anim") 
		end,
	};
	Def.Sprite{
		Texture="P2",
		InitCommand=function(s) s:xy(_screen.cx+pos,_screen.cy):zoom(zo):sleep(0.4):queuecommand("Anim") end,
		AnimCommand=function(s) 
			s:linear(lap):rotationz(rz):zoomx(zx):zoomy(za):addy(-2)
			s:linear(lap):rotationz(0):zoom(zo):addy(2)
			s:linear(lap):rotationz(-rz):zoomx(zx):zoomy(za):addy(-2)
			s:linear(lap):rotationz(0):zoom(zo):addy(2)
			s:queuecommand("Anim")
		end,
	};
	-- (it goes away and comes back together with the wheel: see [ScreenSelectMusic] in metrics.ini)
	Def.Quad{
		InitCommand=function(s)
			s:xy(_screen.cx, 0):valign(0):setsize(SCREEN_WIDTH * PANEL_WIDTH, SCREEN_HEIGHT):diffuse(color("0,0,0,1")):diffusealpha(PANEL_ALPHA)
		end,
		OnCommand=function(s) Trace("Panel: created, visible") end,
		-- sent every time the select music screen starts (BGAnimations/ScreenSelectMusic overlay/default.lua): the background
		-- is kept when the screen loads again (coming back from the difficulty selection, a new filter), so the panel can be
		-- left hidden or transparent by the screen that was there before
		WheelPanelShowMessageCommand=function(s) Trace("Panel: shown at screen start"); s:stoptweening():visible(true):diffusealpha(PANEL_ALPHA) end,
		POMenuOpenedMessageCommand=function(s) Trace("Panel: PO opened"); s:visible(false) end,
		POMenuClosingMessageCommand=function(s) Trace("Panel: PO closing"); s:visible(true) end,
		FilterOpenedMessageCommand=function(s) Trace("Panel: FilterOpened"); s:visible(false) end,
		FilterClosedMessageCommand=function(s) Trace("Panel: FilterClosed"); s:visible(true) end,
		StartSelectingStepsMessageCommand=function(s) Trace("Panel: StartSelectingSteps"); s:stoptweening():linear(0.25):diffusealpha(0) end,
		SongUnchosenMessageCommand=function(s) Trace("Panel: SongUnchosen"); s:stoptweening():diffusealpha(0):sleep(0.4):linear(0.2):diffusealpha(PANEL_ALPHA) end,
	};
};