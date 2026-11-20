return Def.ActorFrame {
	loadfile(THEME:GetPathB("","_doors"))()..{
		OffCommand=function(s) s:finishtweening():playcommand("Close"):sleep(1.5) end,
	};
};