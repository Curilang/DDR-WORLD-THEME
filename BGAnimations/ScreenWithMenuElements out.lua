return Def.Actor{
	OnCommand=function(s) s:sleep(THEME:GetMetric( Var "LoadingScreen","ScreenOutDelay")) end,
};