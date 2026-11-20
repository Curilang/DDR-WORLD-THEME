return Def.ActorFrame {	
	Def.ActorFrame{
		InitCommand=function(s) s:y(_screen.cy+125):linear(0.34):y(0):sleep(29):linear(0.34):y(_screen.cy+125) end,
		LoadActor("base")..{
			InitCommand=function(s) s:xy(_screen.cx+240,_screen.cy+9):zoom(0.667) end,
		};
		Def.Sprite{
			InitCommand=function(s) 
				s:x(_screen.cx+240):y(_screen.cy-11)
				s:LoadSongImage(GAMESTATE:GetCurrentSong(), 215, 215)
			end,
		};
		LoadFont("SongNames") .. {
			InitCommand=function(s) 
				s:zoom(0.5):maxwidth(420):x(_screen.cx+135):y(_screen.cy+114):diffuse(color("#000000")):horizalign(left)
				s:settext(GAMESTATE:GetCurrentSong():GetDisplayMainTitle())
			end,
		};
		LoadFont("SongNames") .. {
			InitCommand=function(s) 
				s:zoom(0.5):maxwidth(420):x(_screen.cx+135):y(_screen.cy+131):diffuse(color("#000000")):horizalign(left)
				s:settext(GetArtistName(GAMESTATE:GetCurrentSong()))
			end,
		};
	};
	
	Def.Quad{
		InitCommand=function(s) s:FullScreen():diffusealpha(1) end,
		OnCommand=function(s) s:linear(0.5):diffusealpha(0):sleep(29):linear(0.5):diffusealpha(1) end,
	};
	Def.ActorFrame{
		InitCommand=function(s) s:sleep(29.5):linear(0.5):diffusealpha(0) end,
		loadfile(THEME:GetPathG("","ArcadeDecorations"))();
		GetSoftwareVersion();
	};
};