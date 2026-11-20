-- ============================================================================
-- TEXTURE SLOTS OF THE OPTIONS MENU (DDR WORLD style)
-- ============================================================================
-- Every entry in POTextures is ONE slot (a place where an image goes).
--
-- HOW TO ADD A TEXTURE:
--   1. Copy your PNG into:  BGAnimations/ScreenPlayerOptions overlay/textures/
--   2. Name it EXACTLY like the slot plus ".png" (for example panel_base.png)
--   3. Restart the theme (or press Shift+F2 in game to reload).
--
-- If the PNG does not exist, a colored rectangle (placeholder) is drawn and the menu still works.
-- Sizes (w, h) are in pixels of a 1920x1080 screenshot of the original DDR WORLD; the menu scales itself
-- to the theme's resolution.
--
-- Slot fields:
--   w, h      size of the slot (also the size of the placeholder)
--   color     placeholder color
--   native    true = draw the PNG at its own size times 'scale' instead of stretching it to w x h
--   scale     multiplier used with native
--   ox, oy    PNG pixels where the solid part starts; the PNG is shifted so that corner lands on (0,0)
--   crop      PNG pixels trimmed from each side (left, top, right, bottom)
--   center    PNG pixel that goes to the CENTER of the tab (tab icons)
--   file      PNG file name when it differs from the slot name (slots can share one PNG)
--   lang      true = the PNG has the 3 languages stacked (EN on top, JP, KR): it is named "<slot> 1x3.png" and the\n--             frame of the language of the theme is shown (GetCurrentLanguage: 0 EN, 1 JP, 2 KR)
-- ============================================================================

POTextures = {
	-- ---------- MAIN PANEL ----------
	-- The PNG is 464x528 and its white part is 430x486; times 1.5 that is 645x729. ox/oy hide the shadow
	-- margin so the shadow ends up outside the panel, like the original.
	panel_base          = { w=645, h=727, native=true, scale=1.5, ox=14, oy=25, color="#f4f4f4", desc="White background of the whole panel (with shadow)" },
	title_option_text   = { lang=true, w=112, h=24, native=true, scale=1.5, color="#00000000", desc="'OPTION' text of the header" },

	-- ---------- "P1 Option" / "P2 Option" LOGOS ----------
	title_option_logo_p1 = { w=270, h=180, native=true, scale=1.5, color="#ff5aa000", desc="'P1 Option' logo (top left of the P1 panel)" },
	title_option_logo_p2 = { w=270, h=180, native=true, scale=1.5, color="#ff5aa000", desc="'P2 Option' logo (top right of the P2 panel)" },

	-- ---------- HEADER ICONS (next to 'OPTION') ----------
	-- These PNGs already contain the tab name ("Basic", "Arrows"...), so the menu does not write text over them.
	header_icon_basic   = { lang=true, w=70, h=40, native=true, scale=1.5, color="#00000000", desc="Basic tab icon + name (header)" },
	header_icon_arrows  = { lang=true, w=70, h=40, native=true, scale=1.5, color="#00000000", desc="Arrows tab icon + name (header)" },
	header_icon_lane    = { lang=true, w=70, h=40, native=true, scale=1.5, color="#00000000", desc="Lane tab icon + name (header)" },
	header_icon_judge   = { lang=true, w=70, h=40, native=true, scale=1.5, color="#00000000", desc="Judge tab icon + name (header)" },
	header_icon_assist  = { lang=true, w=70, h=40, native=true, scale=1.5, color="#00000000", desc="Assist tab icon + name (header)" },

	-- ---------- TABS (backgrounds in 'off' and 'on' state) ----------
	-- scale=1.446 turns the 56x24 and 80x24 PNGs into tabs 81 and 116 wide, the reference size (87 apart;
	-- Back ends right at the edge of the frame).
	tab_bg_off          = { w=81,  h=35, native=true, scale=1.446, color="#f0f0f0", desc="Inactive tab background (Basic/Arrows/Lane/Judge/Assist)" },
	tab_bg_on           = { w=81,  h=35, native=true, scale=1.446, color="#2de8c3", desc="Active tab background (Basic/Arrows/Lane/Judge/Assist)" },
	tab_back_bg_off     = { w=116, h=35, native=true, scale=1.446, color="#f0f0f0", desc="Inactive Back button background" },
	tab_back_bg_on      = { w=116, h=35, native=true, scale=1.446, color="#2de8c3", desc="Active Back button background" },

	-- ---------- TAB ICONS ----------
	-- One PNG per tab, always the same, drawn centered over the active/inactive background.
	-- 'center' is the point of the PNG (in PNG pixels) that goes in the middle of the tab: the center of the
	-- visible drawing, not of the whole PNG, so each icon looks centered. If one looks off, adjust its x
	-- (left/right) or y (up/down); raising x moves the icon left, raising y moves it up.
	tab_basic           = { w=48, h=32, native=true, scale=1.5, center={ x=22.5, y=15 },   color="#00000000", desc="Basic tab icon" },
	tab_arrows          = { w=48, h=32, native=true, scale=1.5, center={ x=23,   y=14 },   color="#00000000", desc="Arrows tab icon" },
	tab_lane            = { w=48, h=32, native=true, scale=1.5, center={ x=22.5, y=15.5 }, color="#00000000", desc="Lane tab icon" },
	tab_judge           = { w=48, h=32, native=true, scale=1.5, center={ x=22,   y=15.5 }, color="#00000000", desc="Judge tab icon" },
	tab_assist          = { w=48, h=32, native=true, scale=1.5, center={ x=23.5, y=14.5 }, color="#00000000", desc="Assist tab icon" },
	tab_back            = { lang=true, w=80, h=32, native=true, scale=1.5, center={ x=36,   y=18 }, color="#00000000", desc="Back button text/icon (optional; 'Back' is written if missing)" },

	-- ---------- ROW AREA ----------
	-- section_box comes from panel_section.png (372x400: cyan frame on top, dark box below); 'crop' trims
	-- the part that is not used. scale=1.485 gives 552x254.
	-- The cyan frame itself is drawn in code (see POSettings below).
	content_bg          = { w=546, h=315, color="#ececec", desc="Gray fill of the frame (only used while panel_section.png is missing)" },
	row_bg_focus        = { w=546, h=45,  color="#00ffbd", desc="Strip of the selected row (solid cyan; 45 high = the whole row)" },
	value_bg            = { w=249, h=36,  color="#141414", desc="Black value box (normal)" },
	value_bg_focus      = { w=249, h=36,  color="#141414", desc="Black value box (selected row)" },
	value_bar           = { w=249, h=4,   color="#2de8c3", desc="Cyan bar under the value (its position follows the value)" },

	-- Box of the 'scroll speed  MIN ~ CORE ~ MAX' line. It turns 'on' while the second Scroll Speed line
	-- (the value) is selected and 'off' otherwise. crop: the 264x28 texture has a spare border; the original
	-- trims it (4 px left, 2 top, 2 bottom), leaving a 260x24 box (390x36 in menu units).
	info_bg_off         = { lang=true, w=390, h=36, native=true, scale=1.5, crop={ left=4, top=2, bottom=2 }, color="#b4b4b4", desc="min~core~max line box (off)" },
	info_bg_on          = { lang=true, w=390, h=36, native=true, scale=1.5, crop={ left=4, top=2, bottom=2 }, color="#1f9c85", desc="min~core~max line box (on: speed value selected)" },

	-- ---------- EXPLANATION BOX (dark part at the bottom) ----------
	section_box         = { file="panel_section", w=552, h=254, native=true, scale=1.485,
	                        crop={ top=229, bottom=0 }, color="#2a2a2a", desc="Dark explanation box (bottom part of panel_section.png)" },
}

-- ============================================================================
-- LOOK OF THE OPTIONS AREA
-- ============================================================================
-- frame_border   thickness of the 4 sides of the cyan frame (panel units). The frame is drawn in code
--                because the PNG's borders are uneven (left 3 px, right 5, top 4, bottom 2).
-- frame_color    color of the frame
-- row_band_odd / row_band_even
--                The option area has alternating bands with no gaps, one per row (measured from the
--                reference: even rows are about 16 levels darker than odd rows).
--                row_band_odd = rows 1, 3, 5, 7: white with opacity. row_band_even = rows 2, 4, 6: dark gray.
--                'alpha' is opacity (0 invisible, 1 solid). Raise row_band_even's alpha to make the difference
--                between rows stronger, lower it to soften it.
-- header_bg      white strip behind "OPTION" and the tab icon/name (drawn in code). x, y = top-left corner
--                inside the panel; w, h = size.
POSettings = {
	frame_border   = 4.5,
	frame_color    = "#00ffbd",

	row_band_odd  = { color = "#ffffff", alpha = 0.5 },
	row_band_even = { color = "#333333", alpha = 0.09 },

	header_bg = { x = 54, y = 28, w = 552, h = 42, color = "#ffffff" },
}

-- Draws a rectangular frame (border only). x, y = top-left corner, w, h = OUTER size.
function POFrameQuads(x, y, w, h)
	local b = POSettings.frame_border
	local c = color(POSettings.frame_color)
	local function bar(bx, by, bw, bh)
		return Def.Quad{
			InitCommand = function(self) self:xy(bx, by):halign(0):valign(0):setsize(bw, bh):diffuse(c) end,
		}
	end
	return Def.ActorFrame{
		Name = "FrameQuads",
		InitCommand = function(self) self:xy(x, y) end,
		bar(0, 0, w, b),            -- top
		bar(0, h - b, w, b),        -- bottom
		bar(0, 0, b, h),            -- left
		bar(w - b, 0, b, h),        -- right
	}
end

-- If the slot has 'file', its PNG is named differently from the slot (several slots can share one PNG).
local function TexturePath(name)
	local spec = POTextures[name]
	local file = (spec and spec.file) or name
	if spec and spec.lang then file = file .. " 1x3" end
	return "/" .. THEME:GetCurrentThemeDirectory() .. "BGAnimations/ScreenPlayerOptions overlay/textures/" .. file .. ".png"
end

-- true when the slot's PNG exists (used to hide placeholder texts)
function POTexExists(name)
	return FILEMAN:DoesFileExist(TexturePath(name))
end

-- POTex(name [, extra])
-- Returns an ActorFrame with the texture (or its placeholder), anchored TOP-LEFT.
-- 'extra' is an optional table with commands for the frame (InitCommand, etc.).
function POTex(name, extra)
	local spec = POTextures[name]
	local frame = extra or {}
	frame.Name = frame.Name or name

	if not spec then
		Trace("[PlayerOptions] unknown texture slot: " .. tostring(name))
		frame[#frame + 1] = Def.Actor{}
		return Def.ActorFrame(frame)
	end

	local path = TexturePath(name)
	if FILEMAN:DoesFileExist(path) then
		frame[#frame + 1] = Def.Sprite{
			Name = "Tex",
			Texture = path,
			InitCommand = function(self)
				self:halign(0):valign(0)
				-- the 3 languages are stacked in the PNG (1x3): show the frame of the theme's language
				if spec.lang then self:animate(false):setstate(GetCurrentLanguage()) end
				if spec.native then
					-- the PNG's own size times the scale (not distorted)
					local sc = spec.scale or 1
					self:zoom(sc)
					local ox, oy = spec.ox, spec.oy
					-- crop: trims PNG pixels (used to take one part out of a PNG that holds several)
					if spec.crop then
						local c = spec.crop
						local W, H = self:GetWidth(), self:GetHeight()
						self:cropleft((c.left or 0) / W):cropright((c.right or 0) / W)
						self:croptop((c.top or 0) / H):cropbottom((c.bottom or 0) / H)
						ox = ox or (c.left or 0)
						oy = oy or (c.top or 0)
					end
					-- ox/oy: shifts the PNG so its visible part lines up with (0,0) (see panel_base)
					if ox or oy then
						self:xy(-(ox or 0) * sc, -(oy or 0) * sc)
					end
				else
					-- stretched to the slot size
					self:setsize(spec.w, spec.h)
				end
			end,
		}
	else
		frame[#frame + 1] = Def.Quad{
			Name = "Tex",
			InitCommand = function(self)
				self:halign(0):valign(0):setsize(spec.w, spec.h):diffuse(color(spec.color))
			end,
		}
	end
	return Def.ActorFrame(frame)
end

-- ============================================================================
-- EXPLANATION IMAGES (box at the bottom of the menu)
-- ============================================================================
-- One PNG per option value, in textures/explanation/<tab>/<option>/explanation_<value> 1x3.png. The 3 languages
-- are stacked (EN, JP, KR) and the frame of the language of the theme is shown. The PNG already has the text, the
-- drawing and the dotted line. Which one each value uses: the 'image' field of every row in
-- Scripts/08 PlayerOptionsRows.lua.
function POExplanationPath(rel)
	return "/" .. THEME:GetCurrentThemeDirectory() .. "BGAnimations/ScreenPlayerOptions overlay/textures/explanation/" .. rel .. " 1x3.png"
end

function POExplanationExists(rel)
	return rel ~= nil and FILEMAN:DoesFileExist(POExplanationPath(rel))
end