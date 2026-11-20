return Def.ActorFrame {
	loadfile(THEME:GetPathB("","_doors"))()..{
		OnCommand=function(s) s:finishtweening():playcommand("Open") end,
	};
};