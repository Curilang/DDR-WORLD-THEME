-- Coming back from the difficulty selection with ESC (see BGAnimations/ScreenSelectMusic overlay/TwoPartDiff and
-- "Screen cancel.lua"): the panels that are already on screen in the difficulty selection (groove radar, scores,
-- footer) must not animate again. The select music overlay stores the moment of that return.
function ReturnedFromDiff()
	local v = getenv("DDRWORLD_ReturnedFromDiff")
	return type(v) == "number" and GetTimeSinceStart() - v < 2
end

-- seconds the footer takes to come up (metrics.ini, FooterOnCommand)
function FooterShowTime()
	return ReturnedFromDiff() and 0 or 0.2
end

-- FooterOnCommand: the footer is moved up at once when coming back (a tween of 0 s is only applied one frame later,
-- and the footer was missing for that frame)
function FooterPreOffset()
	return ReturnedFromDiff() and -100 or 0
end

function FooterPostOffset()
	return ReturnedFromDiff() and 0 or -100
end

-- MusicWheelPOMenuClosingMessageCommand: when the options menu is closed from the difficulty selection the wheel must
-- stay transparent (only the difficulty selection is shown), otherwise it appears behind it
function WheelClosingAlpha()
	return getenv("DDRWORLD_InDiff") and 0 or 1
end

function WheelClosingTime()
	return getenv("DDRWORLD_InDiff") and 0 or 0.15
end