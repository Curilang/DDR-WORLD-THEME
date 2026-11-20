Region = {
	"Overseas",
	"Afghanistan", "Albania", "Algeria", "Andorra", "Angola", "Antigua and Barbuda", "Argentina", "Armenia", "Australia", "Austria", "Azerbaijan",
	"Bahamas", "Bahrain", "Bangladesh", "Barbados", "Belarus", "Belgium", "Belize", "Benin", "Bhutan", "Bolivia", "Bosnia and Herzegovina", "Botswana", "Brazil", "Brunei", "Bulgaria", "Burkina Faso", "Burundi",
	"Cabo Verde", "Cambodia", "Cameroon", "Canada", "Central African Republic", "Chad", "Chile", "China", "Colombia", "Comoros", "Congo", "Costa Rica", "Côte d'Ivoire", "Croatia", "Cuba", "Cyprus", "Czechia",
	"Democratic Republic of the Congo", "Denmark", "Djibouti", "Dominica", "Dominican Republic",
	"Ecuador", "Egypt", "El Salvador", "Equatorial Guinea", "Eritrea", "Estonia", "Eswatini", "Ethiopia",
	"Fiji", "Finland", "France",
	"Gabon", "Gambia", "Georgia", "Germany", "Ghana", "Greece", "Grenada", "Guatemala", "Guinea", "Guinea-Bissau", "Guyana",
	"Haiti", "Honduras", "Hungary",
	"Iceland", "India", "Indonesia", "Iran", "Iraq", "Ireland", "Israel", "Italy",
	"Jamaica", "Japan", "Jordan",
	"Kazakhstan", "Kenya", "Kiribati", "North Korea", "South Korea", "Kuwait", "Kyrgyzstan",
	"Laos", "Latvia", "Lebanon", "Lesotho", "Liberia", "Libya", "Liechtenstein", "Lithuania", "Luxembourg",
	"Madagascar", "Malawi", "Malaysia", "Maldives", "Mali", "Malta", "Marshall Islands", "Mauritania", "Mauritius", "Mexico", "Micronesia", "Moldova", "Monaco", "Mongolia", "Montenegro", "Morocco", "Mozambique", "Myanmar",
	"Namibia", "Nauru", "Nepal", "Netherlands", "New Zealand", "Nicaragua", "Niger", "Nigeria", "North Macedonia", "Norway",
	"Oman",
	"Pakistan", "Palau", "Palestine", "Panama", "Papua New Guinea", "Paraguay", "Peru", "Philippines", "Poland", "Portugal", "Qatar",
	"Romania", "Russia", "Rwanda",
	"Saint Kitts and Nevis", "Saint Lucia", "Saint Vincent and the Grenadines", "Samoa", "San Marino", "São Tomé and Príncipe", "Saudi Arabia", "Senegal", "Serbia", "Seychelles", "Sierra Leone", "Singapore", "Slovakia", "Slovenia", "Solomon Islands", "Somalia", "South Africa", "South Sudan", "Spain", "Sri Lanka", "Sudan", "Suriname", "Sweden", "Switzerland", "Syria",
	"Tajikistan", "Tanzania", "Thailand", "Timor-Leste", "Togo", "Tonga", "Trinidad and Tobago", "Tunisia", "Türkiye", "Turkmenistan", "Tuvalu",
	"Uganda", "Ukraine", "United Arab Emirates", "United Kingdom", "United States", "Uruguay", "Uzbekistan",
	"Vanuatu", "Vatican City", "Venezuela", "Vietnam",
	"Yemen",
	"Zambia", "Zimbabwe",
}

function OptionRowRegion() 
	return { 
		Name = "Region", 
		LayoutType = "ShowAllInRow", 
		SelectType = "SelectOne", 
		OneChoiceForAllPlayers = false, 
		ExportOnChange = true, 
		Choices = Region, 
		LoadSelections = function(self, list, pn) 
			local current 
				if pn == PLAYER_1 then 
					current = ThemePrefs.Get("RegionP1") 
				else 
					current = ThemePrefs.Get("RegionP2") 
				end 
				for i, name in ipairs(Region) do 
					list[i] = (name == current) 
				end 
		end, 
		SaveSelections = function(self, list, pn) 
			for i, selected in ipairs(list) do 
				if selected then 
					if pn == PLAYER_1 then 
						ThemePrefs.Set("RegionP1", tostring(Region[i]))
					else 
						ThemePrefs.Set("RegionP2", tostring(Region[i]))
					end 
					MESSAGEMAN:Broadcast("RegionChanged") 
					break 
				end 
			end 
		end, 
	} 
end

local Prefs = {
	VideoSize = {
        Default = "FullScreen",
        Choices = {"Off", "Small", "Medium", "FullScreen", },
        Values = {"Off", "Small", "Medium", "FullScreen", },
    },
	-- On: ARROW DESIGN / ARROW COLORING in the player options use the SchneiderAFX noteskins
	-- (SCH-<DESIGN>-<COLORING>). Off: ARROW DESIGN lists every installed noteskin, no ARROW COLORING row.
	NTOption = {
		Default = "On",
		Choices = { "Off", "On" },
		Values = { "Off", "On" },
	},
	-- On: the ITG packs (the ones with an itg.ini file) can be chosen in the FILTER: the ITG VERSION and ITG LEVEL
	-- categories appear. Off: the ITG packs never show up (see Scripts/08 Filter.lua).
	IncludeITG = {
		Default = "Off",
		Choices = { "Off", "On" },
		Values = { "Off", "On" },
	},
	Language = {
		Default = "English",
        Choices = { "English", "Japanese", "Korean", },
        Values = { "English", "Japanese", "Korean", },
	},
	RegionP1 = {
		Default = Region[1],
        Choices = Region,
        Values = Region,
	},
	RegionP2 = {
		Default = Region[1],
        Choices = Region,
        Values = Region,
	},
	TargetScore = {
		Default = "OFF",
        Choices = { "OFF", "ON" },
        Values = { "OFF", "ON" },
	},
	MeterBar = {
		Default = "Off",
        Choices = { "Off", "SongMeter", "StepsMeter" },
        Values = { "Off", "SongMeter", "StepsMeter" },
	},
	EvaluationPaneStateP1 = {
    Default = 0,
    Choices = {0, 1, 2, 3, 4, 5, 6},
    Values = {0, 1, 2, 3, 4, 5, 6},
	},
	EvaluationPaneStateP2 = {
		Default = 0,
		Choices = {0, 1, 2, 3, 4, 5, 6},
		Values = {0, 1, 2, 3, 4, 5, 6},
	},
	BackgroundMusic = {
		Default = "ON",
        Choices = { "OFF", "ON" },
        Values = { "OFF", "ON" },
	},
	EXScore = {
		Default = "OFF",
		Choices = { "OFF" , "ON" },
		Values = { "OFF" , "ON" },
	},
	
};

local AllPrefs = {}
for k, v in pairs(Prefs) do AllPrefs[k] = v end
ThemePrefs.InitAll(AllPrefs)

function GetLanguage()
	if ThemePrefs.Get("Language") == "Japanese" then
		return "jpn_"
	elseif ThemePrefs.Get("Language") == "Korean" then
		return "kor_"
	else
		return "eng_"
	end
end

function GetCurrentLanguage()
	if ThemePrefs.Get("Language") == "Japanese" then
		return 1
	elseif ThemePrefs.Get("Language") == "Korean" then
		return 2
	else
		return 0
	end
end
	
