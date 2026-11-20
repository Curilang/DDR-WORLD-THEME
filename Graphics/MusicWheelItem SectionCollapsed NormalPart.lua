-- The text of a section header only depends on the sort and the section, so it is worked out once.
local labels = {}
local function Label(sortOrder, group)
	local levelList = LevelSort and LevelSort.Loaded and true or false   -- the LEVEL list is in use (names are "LEVEL 005")
	local key = sortOrder .. "\n" .. tostring(SongOrder and SongOrder.GroupMode) .. "\n" .. tostring(levelList) .. "\n" .. group
	local text = labels[key]
	if not text then
		if levelList then
			text = SongAttributes.GetGroupName(LevelSort.DisplayName and LevelSort.DisplayName(group) or group)
		elseif SongOrder and (SongOrder.Mode == "Title" or SongOrder.Mode == "Artist" or SongOrder.Mode == "Genre") and sortOrder == "SortOrder_Preferred" then
			text = group   -- the sections of these lists are already the letters / the genre
		elseif sortOrder == "SortOrder_Group" or (SongOrder and SongOrder.GroupMode and sortOrder == "SortOrder_Preferred") then
			text = string.gsub(SongAttributes.GetGroupName(group), "^%d%d? ?%- ?", "")
		elseif sortOrder == "SortOrder_TopGrades" then
			text = string.gsub(group, "AAAA", "AAA+")
		else
			text = SongAttributes.GetGroupName(LevelSort and LevelSort.DisplayName and LevelSort.DisplayName(group) or group)
		end
		labels[key] = text
	end
	return text
end

-- true when the header is drawn as the two buttons of the main list
local function Buttons(p)
	return WheelButtons ~= nil and WheelButtons.IsHeader(p.Text)
end

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

	Def.Sprite{
		InitCommand=function(s) s:y(1):zoom(1.3) end,
		SetCommand=function(s,p)
			if p.Index ~= nil then
				s:visible(not Buttons(p))
				-- the texture is only loaded when it is not the one already shown
				if p.HasFocus then
					WheelCache.LoadOnce(s, WheelCache.PathG("", "MusicWheelItem/selected"))
				else
					WheelCache.LoadOnce(s, WheelCache.PathG("", "MusicWheelItem/normal"))
				end
			end
		end,
	};

	Def.Sprite{
		Texture=THEME:GetPathG("","_shared/line"),
		InitCommand=function(s) s:y(49):setsize(678,14):texcoordvelocity(-0.1,0) end,
		SetCommand=function(s,p)
			if p.Index ~= nil then
				s:visible(p.HasFocus and not Buttons(p))
			end
		end,
	};

	LoadFont("MusicWheelItem GroupNames")..{
		InitCommand=function(s) s:maxwidth(320):zoom(2) end,
		SetCommand=function(s,p)
			s:stoptweening()
			if LevelSort and LevelSort.NoteHeader then LevelSort.NoteHeader(p) end
			s:visible(not Buttons(p))   -- (the two buttons say it all)

			local text = Label(GAMESTATE:GetSortOrder(), p.Text or "")
			if s.shownText ~= text then
				s:settext(text)
				s.shownText = text
			end

			if p.Index ~= nil then
				if p.HasFocus then
					s:diffuse(color("#000000"))
				else
					s:diffuse(color("#ffffff"))
				end
			end
		end;
	};

	-- the header of the main list is the "Change folder" card: START on it opens the folder screen
	LoadFont("MusicWheelItem GroupNames")..{
		InitCommand=function(s) s:xy(0,34):zoom(0.8):maxwidth(380) end,
		SetCommand=function(s,p)
			local show = p.HasFocus and Filter and Filter.FlatByDefault and Filter.Folders and LevelSort and LevelSort.Loaded
				and string.find(p.Text or "", "%(%d+ %u+%)") ~= nil and not Buttons(p)
			s:visible(show and true or false)
			if show then
				s:settext("CHANGE FOLDER: START"):diffuse(color("#000000"))
			end
		end;
	};

	-- the two buttons of the main list: "Change folder" and "MUSIC FILTER" (Scripts/08 WheelButtons.lua)
	(WheelButtons and WheelButtons.Make) and WheelButtons.Make() or Def.Actor{};
};
