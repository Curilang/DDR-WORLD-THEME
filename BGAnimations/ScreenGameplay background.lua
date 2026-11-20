function GetVideoChanges()
	local song = GAMESTATE:GetCurrentSong()
	if not song then return false end
	
	if song and song.HasMusicVideo and song:HasMusicVideo() then
		return true
	end

	local songDir = song:GetSongDir()
	local files = FILEMAN:GetDirListing(songDir.."/")
	
	for _, file in ipairs(files) do
	
		if IsVideoFile(file) then
			return true
		end
		
	end
	
	local bg = song:GetBGChanges()
	if bg and #bg > 0 then return true end

	return false
end

local cond;
if not (ThemePrefs.Get("VideoSize") == "Off" or ThemePrefs.Get("VideoSize") == "Small" or ThemePrefs.Get("VideoSize") == "Medium") then
	cond = not GetVideoChanges()
end

return Def.ActorFrame {
	LoadActor(THEME:GetPathB("ScreenWithMenuElements","background"))..{
		Condition=cond
	};
};