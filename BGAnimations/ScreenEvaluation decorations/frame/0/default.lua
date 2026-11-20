local pn = ...;

local profile = PROFILEMAN:GetProfile(pn);
local stageStats = STATSMAN:GetCurStageStats();
local playerStats = stageStats:GetPlayerStageStats(pn);

local CaloriesToday = profile:GetCaloriesBurnedToday();
local CaloriesBurned = playerStats:GetCaloriesBurned();

local CaloriesLevel = {
	{ 5,   0 },
	{ 30,  1 },
	{ 50,  2 },
	{ 60,  3 },
	{ 70,  4 },
	{ 85,  5 },
	{ 100, 6 },
	{ 120, 7 },
	{ 150, 8 },
	{ 200, 9 },
	{ 220, 10 },
	{ 235, 11 },
	{ 250, 12 },
	{ 280, 13 },
	{ 300, 14 },
	{ 330, 15 },
	{ 355, 16 },
	{ 400, 17 },
	{ 430, 18 },
	{ 450, 19 },
	{ 505, 20 },
	{ 550, 21 },
	{ 570, 22 },
	{ 600, 23 },
	{ 620, 24 },
	{ 700, 25 },
	{ 740, 26 },
	{ 870, 27 },
	{ 900, 28 },
};

local CaloriesPercent = 100;
local CaloriesFood = 28;

for _, level in ipairs(CaloriesLevel) do
	local maxCalories = level[1];
	local food = level[2];
	if CaloriesToday <= maxCalories then
		CaloriesPercent = (CaloriesToday / maxCalories) * 100;
		CaloriesFood = food;
		break;
	end

end

local function FormatCalories(value)
	if value == 0 then
		return "0"
	end
	return string.format("%.1f", value);
end

return Def.ActorFrame{

	Def.Sprite{
		Texture="base",
		InitCommand=function(s) s:pause():setstate(GetCurrentLanguage()) end,
	},
	LoadFont("_swis721 blk bt 28px")..{
		InitCommand=function(s) s:player(pn):xy(169, -50):zoom(0.57):halign(1) end,
		OnCommand=function(s) s:settext(FormatCalories(CaloriesBurned)) end,
	},
	LoadFont("_swis721 blk bt 28px")..{
		InitCommand=function(s) s:player(pn):xy(169, -14):zoom(0.57):halign(1) end,
		OnCommand=function(s) s:settext(FormatCalories(CaloriesToday)) end,
	},
	LoadFont("_swis721 blk bt 28px")..{
		InitCommand=function(s) s:xy(192, 18) :diffuse(color("#00e3a5")):zoom(0.45):halign(1) end,
		OnCommand=function(s) s:settextf("%.0f", CaloriesPercent) end,
	},
	Def.Sprite{
		Texture=GetLanguage().."frame",
		InitCommand=function(s) s:pause():setstate(CaloriesFood) end,
	},

};