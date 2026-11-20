-- ============================================================================
-- PERFORMANCE: engine preferences that make the music wheel smoother on slow computers
-- ============================================================================
-- DelayedTextureDelete: with it off (the engine's default), every jacket is unloaded the moment it leaves the wheel
-- and read from the disk again when it comes back, which shows as stutter while scrolling. With it on, textures stay
-- in memory until the screen changes. It is an engine preference (Preferences.ini), so the theme sets it too: it
-- would not travel with the theme files otherwise.
-- ============================================================================

if PREFSMAN and PREFSMAN.SetPreference then
	pcall(function() PREFSMAN:SetPreference("DelayedTextureDelete", true) end)
end