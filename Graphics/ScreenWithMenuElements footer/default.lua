local t = Def.ActorFrame{};
local screenName = Var "LoadingScreen"

local footerTextImage
if screenName == "ScreenSelectProfile" then
	footerTextImage = 1
elseif screenName == "ScreenSelectStyle" then
	footerTextImage = 2
elseif screenName == "ScreenSelectMusic" or screenName == "ScreenSelectCourse" then
	footerTextImage = 3
elseif screenName == "ScreenEvaluation" then
	footerTextImage = 5
elseif screenName == "ScreenEvaluationSummary" then
	footerTextImage = 6
elseif screenName == "ScreenDataSaveSummary" then
	footerTextImage = 7

end

return Def.ActorFrame{
	Condition=footerTextImage;
	Def.Quad{
		InitCommand=function(s) s:diffuse(Color.Black):setsize(SCREEN_WIDTH,40):y(21) end,
	};
	Def.Sprite{
		Texture=GetLanguage().."tex",
		InitCommand=function(s) s:zoom(0.667):y(15):pause():setstate(footerTextImage) end,
	};
};