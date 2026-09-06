-- ============ TEST HOOK ============
-- Publishes internals only when a harness sets SAE_TEST as a global first.
-- Roblox/Delta never set it, so nothing leaks into the game environment.
-- Note: in the standalone Luau CLI, top-level globals land in getfenv(0),
-- which is NOT the same table as _G — so both are checked and written.
do
  local env = getfenv(0)
  local flagged = rawget(env, "SAE_TEST") or (type(_G) == "table" and rawget(_G, "SAE_TEST"))
  if flagged then
    local api = {
      S            = S,
      RARITY       = RARITY,
      MUTATION     = MUTATION,
      RCOLOR       = RCOLOR,
      scanEggs     = scanEggs,
      scanTraps    = scanTraps,
      scanHostiles = scanHostiles,
      rarityOf     = rarityOf,
      mutationOf   = mutationOf,
      weightOf     = weightOf,
      myBase       = myBase,
      pickEgg      = pickEgg,
      eggScore     = eggScore,
      glideTo      = glideTo,
      stopGlide    = stopGlide,
      fireMatch    = fireMatch,
      indexRemotes = indexRemotes,
      getRemotes   = function() return remotes end,
      pressPromptsNear = pressPromptsNear,
      -- database pet
      DB           = DB,
      DB_COUNT     = DB_COUNT,
      DISPLAY      = DISPLAY,
      dbLookup     = dbLookup,
      dbExact      = dbExact,
      dbStripMutation = dbStripMutation,
      incomeOf     = incomeOf,
      money        = money,
      kg           = kg,
      MUT_MULT     = MUT_MULT,
      walkTo       = walkTo,
      hopTo        = hopTo,
      moveTo       = moveTo,
      avoidOffset  = avoidOffset,
      nearOwnBase  = nearOwnBase,
      heldByMe     = heldByMe,
      grabAttempt  = grabAttempt,
      promptsInside = promptsInside,
      touchAllParts = touchAllParts,
      -- perekam & pembelajar cara ambil
      SPY            = SPY,
      startLearning  = startLearning,
      stopLearning   = stopLearning,
      learnTxt       = learnTxt,
      gui          = gui,
      win          = win,
      orb          = orb,
      tabbar       = tabbar,
      pages        = pages,
      tabs         = tabs,
      showPage     = showPage,
      espFolder    = espF,
      statusTxt    = statusTxt,
      diagTxt      = diagTxt,
      textBlob     = textBlob,
      attrBlob     = attrBlob,
      rarityOf     = rarityOf,
      scanEggs     = scanEggs,
      hideBtn      = hideBtn,
      rarityBtns   = rarityBtns,
      -- prediksi
      PRED         = PRED,
      eggSignature = eggSignature,
      similarity   = similarity,
      computePeriod = computePeriod,
      nextResetIn  = nextResetIn,
      odds         = odds,
      probeNextEgg = probeNextEgg,
      findLiveTimer = findLiveTimer,
      hookAnnouncements = hookAnnouncements,
      fmtDur       = fmtDur,
      predPage     = pPred,
      cdBig        = cdBig,
      cdSub        = cdSub,
      oddsTxt      = oddsTxt,
      alertTxt     = alertTxt,
      probeTxt     = probeTxt,
    }
    env.SAE = api
    -- _G may be readonly (standalone Luau CLI); ignore if so
    pcall(function()
      if type(_G) == "table" then _G.SAE = api end
    end)
  end
end
