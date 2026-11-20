-- The menu timer drawn with the original's digits (red from 10). The actor and its textures are in
-- BGAnimations/ScreenSelectMusic overlay/Timer; every screen that has a timer adds it with this function and hides the
-- engine's one in metrics.ini (TimerOnCommand=visible,false). Positions (theme units, centre of the LEFT digit's 64x72 cell)
-- were measured on 720p screenshots of the original; see MenuTimerPositions below.
--
--   DDRWORLD_MenuTimer("ScreenSelectLanguage", MenuTimerPositions.Language.x, MenuTimerPositions.Language.y)
--   DDRWORLD_MenuTimerPerPlayer("ScreenSelectProfile", MenuTimerPositions.Profile, MenuTimerPositions.ProfileP2)
MenuTimerPositions = {
	-- 720p px of the cell (x, y): theme x = (x + 32) / 1.5, theme y = (y + 36) / 1.5
	SelectMusic = { x = 789.33, y = 78.67 },   -- (1152, 82)  wheel and difficulty selection
	Language    = { x = 799.33, y = 45.33 },   -- (1167, 32)
	Results     = { x = 799.33, y = 45.33 },   -- (1167, 32)  ScreenEvaluation and ScreenEvaluationSummary
	Mode        = { x = 510.67, y = 46.00 },   -- (734, 33)   ScreenSelectStyle ("SELECT MODE")
	Profile     = { x = 364.00, y = 64.00 },   -- (514, 60)   ScreenSelectProfile and ScreenDataSaveSummary, player 1
	ProfileP2   = { x = 656.00, y = 64.00 },   -- the player 2 card is 292 units (438 px) to the right of the player 1 card
}

-- player: PLAYER_1 / PLAYER_2 = shown only while that side is joined; nil = always shown
function DDRWORLD_MenuTimer(screenName, x, y, player)
	local path = THEME:GetPathB("ScreenSelectMusic", "overlay/Timer")
	return loadfile(path)({ screen = screenName, x = x, y = y, player = player })
end

-- The copy of the select music screen's timer that the filter / folder menus (ScreenSortList) draw above their dark layer; onZero is
-- called once when the time runs out while the menu is open. See BGAnimations/ScreenSelectMusic overlay/Timer/default.lua.
function DDRWORLD_MenuTimerMirror(onZero)
	local path = THEME:GetPathB("ScreenSelectMusic", "overlay/Timer")
	return loadfile(path)({ screen = "ScreenSelectMusic", mirror = true, onZero = onZero,
		x = MenuTimerPositions.SelectMusic.x, y = MenuTimerPositions.SelectMusic.y })
end

-- one timer per player, each over its own card: P1 only -> the P1 one, P2 only -> the P2 one, both -> both
function DDRWORLD_MenuTimerPerPlayer(screenName, p1, p2)
	return Def.ActorFrame{
		DDRWORLD_MenuTimer(screenName, p1.x, p1.y, PLAYER_1),
		DDRWORLD_MenuTimer(screenName, p2.x, p2.y, PLAYER_2),
	}
end
