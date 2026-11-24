return Def.ActorFrame {
	-- the headers after the open section move down to leave room for the blank cells of its last row
	SetMessageCommand=function(s,p)
		if p.Index ~= nil then
			-- the wheel item remembers which row it shows (Scripts/08 WheelLayout.lua)
			local item = s:GetParent()
			s:y(105 * WheelCache.RowShift(p.Index, s))
			if WheelLayout then WheelLayout.Touch() end
			if p.HasFocus and WheelLayout then WheelLayout.NoteFocus(p.Index) end
			if item then
				item.dataIndex = p.Index
				-- (not item.inner: that one is the card of the song, and this part also gets the messages of the songs, so the
				-- two fought over it and the layout reset the wrong one, leaving the cards in the engine's diagonal)
				item.headInner = s
				item.headShifted = not (WheelLayout and WheelLayout.Active())
			end
		end
	end,
	
	-- the two buttons of the main list: "Change folder" and "MUSIC FILTER" (Scripts/08 WheelButtons.lua)
	(WheelButtons and WheelButtons.Make) and WheelButtons.Make() or Def.Actor{};
};
