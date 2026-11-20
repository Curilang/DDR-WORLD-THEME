for _, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
    local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(pn)
    Trace("P"..pn.." personal idx: "..tostring(pss:GetPersonalHighScoreIndex()))
end

return Def.Actor{};