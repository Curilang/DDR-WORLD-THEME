-- ============================================================================
-- SONG IMAGE: the picture of a song inside a square (or any) box, the same way everywhere
-- ============================================================================
-- A song shows its jacket, stretched to the box. A song without a jacket shows its banner (small) before its
-- background (large): the banner is wide, so it is drawn whole, centered in the box and at its own proportions,
-- not stretched. Used by the music wheel, the select music info panel, the stage information, the evaluation...
--
--   sprite:LoadSongImage(song, width, height [, cached [, fallback]])
--     cached    true to load from the engine's image cache (low resolution, faster); default false
--     fallback  image used when the song has no jacket, banner or background (default: the fallback jacket)
-- Returns the sprite, so it can be chained like Load: s:LoadSongImage(song, 141, 141):xy(...)
-- ============================================================================

-- True when the file name is a video. The gameplay scripts look in the song folder for the video of the song: only
-- real video extensions count (before, any file that was not a known image or sound did, such as the Thumbs.db that
-- Windows leaves in the folders, which the engine then failed to load as a texture).
local VIDEO_EXTENSIONS = {
	[".mp4"] = true, [".avi"] = true, [".mpg"] = true, [".mpeg"] = true, [".mkv"] = true, [".mov"] = true,
	[".wmv"] = true, [".webm"] = true, [".m4v"] = true, [".ogv"] = true, [".flv"] = true, [".divx"] = true,
	[".3gp"] = true, [".vob"] = true, [".ts"] = true,
}
function IsVideoFile(name)
	local ext = name:match("^.+(%..+)$")
	return ext ~= nil and VIDEO_EXTENSIONS[ext:lower()] == true
end

local function Info(song, fallback)
	if not fallback and WheelCache and song then
		return WheelCache.JacketInfo(song)   -- the same answer the wheel uses, worked out once per song
	end
	if song and song:HasJacket() then
		return { path = song:GetJacketPath(), kind = "jacket", cache = "Jacket" }
	elseif song and song:HasBanner() then
		return { path = song:GetBannerPath(), kind = "banner", cache = "Banner" }
	end
	return { path = song and GetJacketPath(song, fallback) or fallback or THEME:GetPathG("Common", "fallback jacket"), kind = "other", cache = "Jacket" }
end

function Sprite:LoadSongImage(song, width, height, cached, fallback)
	local image = Info(song, fallback)
	if cached then
		self:LoadFromCached(image.cache, image.path)
	else
		self:Load(image.path)
	end

	-- loading a texture resets the size
	local texture = self:GetTexture()
	local w = texture and texture.GetSourceWidth and texture:GetSourceWidth() or 0
	local h = texture and texture.GetSourceHeight and texture:GetSourceHeight() or 0
	if image.kind == "banner" and w > 0 and h > 0 then
		local scale = math.min(width / w, height / h)
		self:setsize(w * scale, h * scale)
	else
		self:setsize(width, height)
	end
	return self
end
