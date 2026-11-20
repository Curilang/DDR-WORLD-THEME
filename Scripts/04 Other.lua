_screen = {
	t = SCREEN_TOP,
	b = SCREEN_BOTTOM,
	l = SCREEN_LEFT,
	r = SCREEN_RIGHT,
	w  = SCREEN_WIDTH,
	h  = SCREEN_HEIGHT,
	cx = SCREEN_CENTER_X,
	cy = SCREEN_CENTER_Y,
}

function ThemeManager:GetAbsolutePath(sPath, optional)
	local sFinPath = self:GetCurrentThemeDirectory().."/"..sPath
	if not optional then
		assert(FILEMAN:DoesFileExist(sFinPath), "the theme element "..sPath.." is missing")
	end
	return sFinPath
end

function GetJacketPath(item, fallback) 
	if item:HasJacket() then
		return item:GetJacketPath()
	elseif item:HasBackground() then
		return item:GetBackgroundPath()
	elseif item:HasBanner() then
		return item:GetBannerPath()
	else
		return fallback or THEME:GetPathG("Common","fallback jacket")
	end
end

function Sprite:_LoadSCJacket(...)
	return self:Load(GetJacketPath(...))
end

function SameDiffSteps(song, pn)
    if song then
		local diff = GAMESTATE:GetCurrentSteps(pn):GetDifficulty();
		local st = GAMESTATE:GetCurrentStyle():GetStepsType();
		return song:GetOneSteps(st, diff);
	end;
end;

function MachineOrProfile(pn)
	if PROFILEMAN:IsPersistentProfile(pn) then
		return PROFILEMAN:GetProfile(pn)
	else
		return PROFILEMAN:GetMachineProfile()
	end
end

function ReadOrCreateAppearancePlusValueForPlayer(PlayerUID, MyValue)
	local AppearancePlusFile = RageFileUtil:CreateRageFile()
	if AppearancePlusFile:Open("Save/AppearancePlus/"..PlayerUID..".txt",1) then 
		local str = AppearancePlusFile:Read();
		MyValue =str;
	else
		AppearancePlusFile:Open("Save/AppearancePlus/"..PlayerUID..".txt",2);
		AppearancePlusFile:Write("Visible");
		MyValue="Visible";
	end
	AppearancePlusFile:Close();
	return MyValue;
end

function SaveAppearancePlusValueForPlayer( PlayerUID, MyValue)
	local AppearancePlusFile2 = RageFileUtil:CreateRageFile();
	AppearancePlusFile2:Open("Save/AppearancePlus/"..PlayerUID..".txt",2);
	AppearancePlusFile2:Write(tostring(MyValue));
	AppearancePlusFile2:Close();
end

function ScreenGameplay_P1X()
	local st = GAMESTATE:GetCurrentStyle():GetStepsType();
	if st == "StepsType_Dance_Solo" then
		return SCREEN_CENTER_X;
	elseif st == "StepsType_Dance_Couple" then
		return WideScale(SCREEN_CENTER_X-180,SCREEN_CENTER_X-160);
	else
		return WideScale(SCREEN_CENTER_X-180,SCREEN_CENTER_X-240);
	end
end

function ScreenGameplay_P2X()
	local st = GAMESTATE:GetCurrentStyle():GetStepsType();
	if st == "StepsType_Dance_Solo" then
		return SCREEN_CENTER_X;
	elseif st == "StepsType_Dance_Couple" then
		return WideScale(SCREEN_CENTER_X+180,SCREEN_CENTER_X+160);
	else
		return WideScale(SCREEN_CENTER_X+180,SCREEN_CENTER_X+240);
	end
end

function SongORCourse()
	if GAMESTATE:IsCourseMode() then 
		return GAMESTATE:GetCurrentCourse() 
	else
		return GAMESTATE:GetCurrentSong()
	end
end

function GetArtistName(item)
	if item:GetDisplayArtist() == "Unknown artist" then 
		return ""
	else
		return item:GetDisplayArtist()
	end
end

--Conditionals

function ComboUnderField()
	if ReadPrefFromFile("OptionRowComboUnderField") ~= nil then
		if GetUserPref("OptionRowComboUnderField") == 'false' then
			return false
		else
			return true
		end
	else
		return true
	end
end

-- Same as ComboUnderField, but for the judgment (Judgment 1x5.png, and the hold judgments). It is its own
-- setting (JUDGMENT DISPLAY PRIORITY), independent of the combo; the default is behind the arrows.
function JudgmentUnderField()
	if ReadPrefFromFile("OptionRowJudgmentUnderField") ~= nil then
		return GetUserPref("OptionRowJudgmentUnderField") ~= 'false'
	end
	return true
end

function IsEXScore()
	if ThemePrefs.Get("EXScore") == "ON" then
		if GAMESTATE:IsDemonstration() then
			return false
		else
			return true
		end
	else
		return false
	end
end

--Conditionals

--Screens


function IsTitleMenu()
	local curScreen = Var "LoadingScreen"
	return curScreen == "ScreenTitleMenu"
end

function IsTitleJoin()
	local curScreen = Var "LoadingScreen"
	return curScreen == "ScreenTitleJoin"
end

function IsHowToPlay()
	local curScreen = Var "LoadingScreen"
	return curScreen == "ScreenHowToPlay"
end

function IsLogo()
	local curScreen = Var "LoadingScreen"
	return curScreen == "ScreenLogo"
end

function IsOptionService()
	local curScreen = Var "LoadingScreen"
	return curScreen == "ScreenOptionsService"
end

function IsOptionManageProfiles()
	local curScreen = Var "LoadingScreen"
	return curScreen == "ScreenOptionsManageProfiles"
end

function IsCustomOptions()
	local curScreen = Var "LoadingScreen"
	return curScreen == "ScreenCustomOptions"
end

function IsDataSaveSummary()
	local curScreen = Var "LoadingScreen"
	return curScreen == "ScreenDataSaveSummary"
end

function IsPremiumCustomizer()
	local curScreen = Var "LoadingScreen"
	return curScreen == "ScreenPremiumCustomizer"
end
--Screens

-- Reverse elegido por el jugador (Preferred): ya es correcto al construir la pantalla,
-- a diferencia de Current, que todavía trae lo de la partida anterior.
-- Compatible con StepMania 5.1, ITGmania y OutFox.
function IsReverse(pn)
	local ps = GAMESTATE:GetPlayerState(pn)
	if not ps then return false end
	for _, level in ipairs({ 'ModsLevel_Preferred', 'ModsLevel_Current' }) do
		local ok, v = pcall(function() return ps:GetPlayerOptions(level):Reverse() end)
		if ok then
			if type(v) == "number" then return v > 0.5 end
			if type(v) == "boolean" then return v end
		end
	end
	return false
end

function StreamingMode()
	if ThemePrefs.Get("BackgroundMusic") == "OFF" then
		return true
	end
end

function StreamingSound(item)
	if ThemePrefs.Get("BackgroundMusic") == "OFF" then
		return THEME:GetPathS("","_silent")
	else
		return item
	end 
end

function SelectMusicBGM()
	local Music = THEME:GetAbsolutePath("Sounds/ScreenSelectMusic music (loop).redir")
	local file = RageFileUtil.CreateRageFile()
	
	if ThemePrefs.Get("BackgroundMusic") == "OFF" then
		file:Open(Music,2)
		file:Write("_silent")
		file:Close()
		file:destroy()
	else
		file:Open(Music,2)
		file:Write("WORLD/BGM (loop)")
		file:Close()
		file:destroy()
	end
end

function JudgmentTransformCommand( self, params )
	local x = 0
	local y = -76
	if params.bReverse then y = 56 end
	self:x( x )
	self:y( y )
end

function ComboTransformCommand( self, params )
	local x = 0
	local y = 38
	if params.bReverse then y = 18 end
	self:x( x )
	self:y( y )
end

function SongMeterDisplayX(pn)
	if Center1Player() then
		return SCREEN_CENTER_X
	else
		return pn == PLAYER_1 and SCREEN_LEFT+16 or SCREEN_RIGHT-16
	end
end

function SongMeterDisplayY(pn)
	return Center1Player() and SCREEN_TOP+50 or SCREEN_CENTER_Y
end

function SongMeterDisplayCommand(pn)
	if Center1Player() then
		return cmd(draworder,50;zoom,0;y,SCREEN_TOP-24;sleep,1.5;decelerate,0.5;zoom,1;y,SCREEN_TOP+50)
	else
		local xAdd = (pn == PLAYER_1) and -24 or 24
		return cmd(draworder,5;rotationz,-90;zoom,0;addx,xAdd;sleep,1.5;decelerate,0.5;zoom,1;addx,xAdd*-1)
	end
end

--Better Experience with this theme
function PreferenceTheme()
	PREFSMAN:SetPreference("BGBrightness", 1)
	PREFSMAN:SetPreference("RandomBackgroundMode", "Off")
	PREFSMAN:SetPreference("BackgroundFitMode", "FitInside")
	PREFSMAN:SetPreference("AllowW1", "AllowW1_Everywhere")
	-- DefaultModifiers also holds the noteskin chosen in Appearance Options > Default NoteSkin (the one the demonstration
	-- uses), and this runs every time the service menu is left: only "FailImmediate" is made sure of, the rest is kept.
	local mods = tostring(PREFSMAN:GetPreference("DefaultModifiers") or "")
	if not string.find(string.lower(mods), "failimmediate", 1, true) then
		mods = (mods ~= "") and (mods .. ",FailImmediate") or "FailImmediate"
		PREFSMAN:SetPreference("DefaultModifiers", mods)
	end
end

function PreferenceGame()
	PREFSMAN:SetPreference("ShowBeginnerHelper", false)
	PREFSMAN:SetPreference("AutogenGroupCourses", false)
	PREFSMAN:SetPreference("HiddenSongs", false)
	PREFSMAN:SetPreference("EasterEggs", false)
	PREFSMAN:SetPreference("UseUnlockSystem", false)
	PREFSMAN:SetPreference("MusicWheelUsesSections", "Always")
	PREFSMAN:SetPreference("ShowCaution", true)
	PREFSMAN:SetPreference("ShowDanger", true)
	PREFSMAN:SetPreference("ArcadeOptionsNavigation", false)
	PREFSMAN:SetPreference("ThreeKeyNavigation", false)
	PREFSMAN:SetPreference("AllowMultipleHighScoreWithSameName", true)
	PREFSMAN:SetPreference("AllowExtraStage", false)
	PREFSMAN:SetPreference("ComboContinuesBetweenSongs", false)
	PREFSMAN:SetPreference("LockCourseDifficulties", false)
	PREFSMAN:SetPreference("OnlyDedicatedMenuButtons", true)
end

function IsPlayingWorkout()
	return GAMESTATE:GetEnv("Workout") == "1"
end
	
function WorkoutResetStageStats()
	STATSMAN:Reset()
end

function WorkoutGetProfileGoalType( pn )
	return PROFILEMAN:GetProfile(pn):GetGoalType()
end

function WorkoutGetStageCalories( pn )
	return STATSMAN:GetCurStageStats():GetPlayerStageStats(pn):GetCaloriesBurned()
end

function WorkoutGetTotalCalories( pn )
	return STATSMAN:GetAccumStageStats():GetPlayerStageStats(pn):GetCaloriesBurned()
end

function WorkoutGetTotalSeconds( pn )
	return STATSMAN:GetAccumStageStats():GetGameplaySeconds()
end

function WorkoutGetGoalCalories( pn )
	return PROFILEMAN:GetProfile(pn):GetGoalCalories()
end

function WorkoutGetGoalSeconds( pn )
	return PROFILEMAN:GetProfile(pn):GetGoalSeconds()
end

function WorkoutGetPercentCompleteCalories( pn )
	return WorkoutGetTotalCalories(pn) / WorkoutGetGoalCalories(pn)
end

function WorkoutGetPercentCompleteSeconds( pn )
	return WorkoutGetTotalSeconds(pn) / WorkoutGetGoalSeconds(pn)
end

local numbered_stages= {
	Stage_1st= true,
	Stage_2nd= true,
	Stage_3rd= true,
	Stage_4th= true,
	Stage_5th= true,
	Stage_6th= true,
	Stage_Next= true,
}

function thified_curstage_index(on_eval)
	local cur_stage= GAMESTATE:GetCurrentStage()
	local adjust= 1
	-- hack: ScreenEvaluation shows the current stage, but it needs to show
	-- the last stage instead.  Adjust the amount.
	if on_eval then
		adjust= 0
	end
	if numbered_stages[cur_stage] then
		return FormatNumberAndSuffix(GAMESTATE:GetCurrentStageIndex() + adjust)
	else
		return ToEnumShortString(cur_stage)
	end
end

--Loads the file at path and runs it in the specified environment,
--or an empty one if no environment is provided. Catches any errors that occur.
--Returns false if the called function failed, true and anything else the function returned if it worked
function dofile_safer(path, env)
    env = env or {}
    if not FILEMAN:DoesFileExist(path) then
        --the file doesn't exist
        return false
    end
    local handle = RageFileUtil.CreateRageFile()
    handle:Open(path, 1)
    local code = loadstring(handle:Read(), path)
    handle:Close()
    handle:destroy()
    if not code then
        --an error occurred while compiling the file
        return false
    end
    setfenv(code, env)
    return pcall(code)
end