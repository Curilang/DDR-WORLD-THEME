function SoftwareVersion()
	local path = THEME:GetCurrentThemeDirectory().."ThemeInfo.ini"
	local file = RageFileUtil.CreateRageFile()

	if not file:Open(path, 1) then
		file:destroy()
		return ""
	end

	local content = file:Read()
	file:Close()
	file:destroy()

	local software = content:match("[\r\n]Software%s*=%s*([^\r\n]+)")

	return software or ""
end

function GetSoftwareVersion()
	return Def.BitmapText{
		Font="_futura pt medium 30px";
		InitCommand=function(s)
			s:settext(SoftwareVersion())
			s:xy(SCREEN_LEFT+64.2,SCREEN_TOP+8.5)
			s:zoomx(0.42)
			s:zoomy(0.4)
			s:strokecolor(color("0,0,0,0.5"))
		end;
	};
end