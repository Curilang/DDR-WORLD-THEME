-- Var "Player" llega nil (lo confirma el log); el dueño lo dejó Player judgment al cargarse justo antes
local pn = Var "Player" or HoldJudgmentOwner

return Def.Sprite {
	InitCommand=function(s)
		s:Load(THEME:GetPathG("","HoldJudgment label 1x2/Hold"))
		Trace("HoldJudgment pn = " .. tostring(pn))   -- solo para probar; bórralo después
		-- LOW: el OK/NG del motor se oculta y lo dibuja la copia de decorations
		if pn and POMenu and POMenu.JudgmentHigh and not POMenu.JudgmentHigh(pn) then
			s:blend("BlendMode_NoEffect")
		end
	end,
};
