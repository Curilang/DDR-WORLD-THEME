local player = Var "Player"
local h = 24

return Def.ActorFrame{
	InitCommand=function(s) s:y(1) end,
	-- -- LifeMetterBar under
	Def.Sprite{
		Texture=THEME:GetPathB("","ScreenGameplay decorations/lifeframe/stream/base"),
		InitCommand=function(s) s:zoom(0.667) end,
	};
	Def.Sprite{
		InitCommand=function(s) s:x(-1):texcoordvelocity(-0.6,0) end,
		BeginCommand=function(self,params)
			local screen = SCREENMAN:GetTopScreen();
			local glifemeter = screen:GetLifeMeter(player);
			assert(glifemeter);
			if glifemeter:GetTotalLives() == 4 then
				self:Load(THEME:GetPathB("ScreenGameplay","decorations/lifeframe/stream/full"))
				self:zoomto(273,h);
			elseif glifemeter:GetTotalLives() == 1 then
				self:Load(THEME:GetPathB("ScreenGameplay","decorations/lifeframe/stream/danger"))
				self:zoomto(67,h):x(-104)
			end
		end;
		LifeChangedMessageCommand=function(self,params)
		if params.Player ~= player then return end;
			self:finishtweening();
			if params.LivesLeft == 4 then 
				self:Load(THEME:GetPathB("ScreenGameplay","decorations/lifeframe/stream/full"))
				self:zoomto(273,h);
			elseif params.LivesLeft == 3 then
				self:Load(THEME:GetPathB("ScreenGameplay","decorations/lifeframe/stream/normal"))
				self:zoomto(208,h):x(-34)
			elseif params.LivesLeft == 2 then
				self:zoomto(138,h):x(-69)
				self:Load(THEME:GetPathB("ScreenGameplay","decorations/lifeframe/stream/normal"))
			elseif params.LivesLeft == 1 then
				self:Load(THEME:GetPathB("ScreenGameplay","decorations/lifeframe/stream/danger"))
				self:zoomto(67,h):x(-104)
			elseif params.LivesLeft == 0 then
				self:Load(THEME:GetPathB("ScreenGameplay","decorations/lifeframe/stream/danger"))
				self:zoomto(0,0);
			end;
		end;
	};
};