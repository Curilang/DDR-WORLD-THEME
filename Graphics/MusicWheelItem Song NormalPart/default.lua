-- Lamp system inherited from DDR A3 (card background by FC / MFC / Risky / Life4...). DDR WORLD no longer has
-- it, so it is turned off. Set USE_LAMPS = true to bring it back (the files in lamp/ are still here).
local USE_LAMPS = false

local lamp = Def.ActorFrame{}
local cards = Def.ActorFrame{}   -- FLARE cards: card background of songs cleared with a FLARE
local cleared = Def.ActorFrame{}
local diff = Def.ActorFrame{ Name="Diff" }

-- Wheel index of the first song of the open section (the songs form a grid of three per row from there): see
-- WheelCache.Block, worked out once per frame.
local function GetExpandedSectionIndex()
	return WheelCache.FirstSong()
end
local function SetXYPosition(self, p)
	-- Scripts/08 WheelLayout.lua: the item is placed as a whole (the engine's wheel item), so the card sits at its origin
	if WheelLayout and WheelLayout.Active() then
		self:xy(0, 0)
		return
	end
	local index = (p.Index - GetExpandedSectionIndex()) % 3
	local w, h = 225, 105
	local shift = 105 * WheelCache.RowShift(p.Index, self)   -- room for the blank cells of the open section's last row

	if index == 0 then
		self:xy(-w, h + shift)
	elseif index == 1 then
		self:xy(0, shift)
	else
		self:xy(w, -h + shift)
	end
end
-- Blank tile of an empty cell in the last row of the open section: the n-th cell to the right of the last song.
-- Change the texture here (Graphics/MusicWheelItem Song NormalPart/) to change how the empty cells look.
local FILLER_TEXTURE = "blank"
local function Filler(n)
	return Def.Sprite{
		Texture=FILLER_TEXTURE,
		InitCommand=function(s) s:zoom(0.94):visible(false) end,
		SetMessageCommand=function(s, p)
			if p.Index == nil then return end
			local b = WheelCache.Block()
			local show = false
			if b and p.Index == b.last then
				local cell = (p.Index - b.first) % 3
				show = n <= 2 - cell
				if show then
					-- the next cell is 225 to the right, on the same row (the cells of a row sit at different
					-- heights in the grid only because they are different items); this frame is drawn at zoom 1.755
					s:xy(225 * n / 1.755, 0)
				end
			end
			s:visible(show)
		end,
	}
end

for _, pn in pairs(GAMESTATE:GetEnabledPlayers()) do
	if USE_LAMPS then
		lamp[#lamp+1] =
			loadfile(THEME:GetPathG("MusicWheelItem", "Song NormalPart/lamp"))(pn)
	end

	cards[#cards+1] =
		loadfile(THEME:GetPathG("MusicWheelItem", "Song NormalPart/flare_card.lua"))(pn)

	cleared[#cleared+1] =
		loadfile(THEME:GetPathG("MusicWheelItem", "Song NormalPart/cleared.lua"))(pn)..{
			InitCommand=function(s)
				s:xy(pn == PLAYER_1 and -25 or 26, 45)
			end,
		}

	-- FLARE icon: right next to the clear mark and grade, on the same row as the difficulty number (mirrored
	-- for P2). With two players there is no room, so it is skipped. Position is in item units; the item is
	-- drawn at zoom 1.755, so 1 screen pixel is about 0.57 units.
	if #GAMESTATE:GetEnabledPlayers() == 1 then
		local FLARE_X, FLARE_Y = -8 + 2/1.755, 45 - 2/1.755   -- the clear mark spans about -35..-15
		cleared[#cleared+1] =
			loadfile(THEME:GetPathG("MusicWheelItem", "Song NormalPart/flare_icon.lua"))(pn)..{
				InitCommand=function(s)
					s:xy(pn == PLAYER_1 and FLARE_X or -FLARE_X, FLARE_Y)
				end,
			}
	end

	diff[#diff+1] =
		loadfile(THEME:GetPathG("MusicWheelItem", "Song NormalPart/diff.lua"))(pn)..{
			InitCommand=function(s)
				s:xy(pn == PLAYER_1 and -66 or 28, 71)
			end,
		}
end

-- The selected card has no turn animation: every attempt (inside the wheel items or in an overlay actor) broke or
-- did not blend with the wheel, so it was dropped.
return Def.ActorFrame{
	Def.ActorFrame{
		Name="Inner",
		SetMessageCommand=function(self, p)
			if p.Index ~= nil then
				-- the wheel item remembers which song it shows (the layout needs it before the next Set message)
				local part = self:GetParent()
				local item = part and part:GetParent()
				if item then item.dataIndex = p.Index end
				if WheelLayout then WheelLayout.Touch() end
				if p.HasFocus and WheelLayout then WheelLayout.NoteFocus(p.Index) end
				if p.HasFocus and WheelCache.NoteIndexDelta then
					local b = WheelCache.Block()
					if b then WheelCache.NoteIndexDelta(p.Index, b.sel, b.total) end
				end
				SetXYPosition(self, p)
				if item then
					-- (the layout takes the card back to its origin if it was shifted before the layout was ready)
					item.inner = self
					item.innerShifted = not (WheelLayout and WheelLayout.Active())
				end
				self:zoom(1.755)
				self:name(tostring(p.Index))
			end
		end;

		-- Blank tiles of the empty cells of the last row. They are NOT part of the turning card: they belong to the cells
		-- next to the last song, not to this card (they sit in other cells, so the order does not matter).
		Filler(1);
		Filler(2);

		-- Everything of the card is inside "Turn": the card turns when the cursor lands on it. The turn lives on its own
		-- frame because the Set message above moves and zooms "Inner" every time, and a command sent to an actor that
		-- is tweening changes the END of its tween instead of the actor (that is what broke the earlier turns).
		-- The turn is NOT started from the Set message: the Set of the item that loses the focus can arrive before the
		-- Set of the one that gains it (or never), which left cards turned or dark. Scripts/08 WheelLayout.lua starts and
		-- ends every turn each frame from where the cursor is; here the frame only tells the item where it is.
		Def.ActorFrame{
		Name="Turn",
		SetMessageCommand=function(self, p)
			if self.bound then return end
			local item = self:GetParent() and self:GetParent():GetParent() and self:GetParent():GetParent():GetParent()
			if item then
				item.turn = self
				-- the parts the entry animation drives by hand (Scripts/08 WheelLayout.lua, WheelLayout.INTRO)
				item.introParts = {
					under = self:GetChild("Under"), dark = self:GetChild("Dark"), title = self:GetChild("Title"),
					seldeco = self:GetChild("SelDeco"), banner = self:GetChild("Banner"), diff = self:GetChild("Diff"),
				}
				self.bound = true
			end
		end;

		-- Card background, FLARE card, lamps and clear marks (everything under the title). The entry animation hides the
		-- whole frame at once.
		Def.ActorFrame{
			Name="Under",
			Def.Sprite{
				Texture="normal",
				InitCommand=function(s)
					s:zoom(0.94)
				end,
			};

			cards;   -- FLARE cards: above normal.png, behind the jacket
			lamp;
			cleared;
		};

		-- The dark cell of the entry animation: a black box with a gradient that lights up at the bottom for a moment
		-- (hidden the rest of the time). It sits under the title, which the original shows on it.
		Def.Quad{
			Name="Dark",
			InitCommand=function(s) s:setsize(128, 181):visible(false):diffuse(color("0,0,0,1")) end,
		};

		Def.BitmapText{
			Name="Title",
			Font="_wheelnames 28px",
			InitCommand=function(s)
				s:xy(-58, 60):zoom(0.5):halign(0):maxwidth(235)
			end,
			SetMessageCommand=function(s, p)
				local song = p.Song

				if song then
					local title = song:GetDisplayMainTitle()   -- the same text is not set again
					if s.shownTitle ~= title then s:settext(title); s.shownTitle = title end

					if p.Index ~= nil and not p.HasFocus then
						s:diffuse(SongAttributes.GetMenuColor(song))
					end
				end
			end;
		};

		-- (the cyan frame and the stripes of the selected card; one frame so the entry animation can hide both)
		Def.ActorFrame{
			Name="SelDeco",
			Def.Sprite{
				Texture="selected",
				InitCommand=function(s)
					s:zoom(0.94):pause():setstate(GetCurrentLanguage()):visible(false)
				end,
				SetCommand=function(s, p)
					if p.Index ~= nil then
						s:visible(p.HasFocus and true or false)
					end
				end,
			};
			StripeLine{
				Name = "Line", 
				w = 120, h = 6, y = 83, count = 10, visible = false,
				SetCommand=function(s, p)
					if p.Index ~= nil then
						s:visible(p.HasFocus and true or false)
					end
				end,
			},
		};
		Def.Sprite{
			Name="Banner",
			InitCommand=function(s)
				s:xy(0, -26)
			end,
			SetMessageCommand=function(s, p)
				local song = p.Song

				if song then
					local image = WheelCache.JacketInfo(song)
					if s.jacketPath ~= image.path then
						s:LoadFromCached(image.cache, image.path)
						s.jacketPath = image.path
						-- loading a texture resets the size; otherwise it does not change.
						-- A banner is wide: it is drawn whole, centered in the card, at its own proportions.
						local texture = s:GetTexture()
						local w = texture and texture.GetSourceWidth and texture:GetSourceWidth() or 0
						local h = texture and texture.GetSourceHeight and texture:GetSourceHeight() or 0
						if image.kind == "banner" and w > 0 and h > 0 then
							s:setsize(115, 115 * h / w)
						else
							s:setsize(115, 115)
						end
					end
				elseif not s.sizeSet then
					s:setsize(115, 115)
				end
				s.sizeSet = true
			end,
		};

		diff;
		};   -- (end of Turn)
	};
}
