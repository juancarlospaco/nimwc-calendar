  # https://github.com/dom96/jester#routes
  get re"^\/calendar\/(\d{4})-([0]\d|1[0-2])-([0-2]\d|3[01])$":
    createTFD()
    let # Regex puts the matches on request.matches,we them assign to subrange
      year: range[2019..2999] = request.matches[0].parseInt
      mont: range[1..12]      = request.matches[1].parseInt
      dayz: range[1..31]      = request.matches[2].parseInt
    if mont == 2: doAssert dayz < 30, "February days must not be >29: " & $dayz
    var mo: Month
    case mont
    of 1:  mo = mJan
    of 2:  mo = mFeb
    of 3:  mo = mMar
    of 4:  mo = mApr
    of 5:  mo = mMay
    of 6:  mo = mJun
    of 7:  mo = mJul
    of 8:  mo = mAug
    of 9:  mo = mSep
    of 10: mo = mOct
    of 11: mo = mNov
    else:  mo = mDec
    const cueri = sql"select * from calendar where eventDate = ?"
    let
      daysInMo  = getDaysInMonth(mo, year)
      dayOneIs  = parse($year & "-" & $mont & "-01", "yyyy-M-dd").weekday
      thisDay   = parse($year & "-" & $mont & "-" & $dayz, "yyyy-M-d").utc.toTime.toUnix
      thisEvent = getRow(db, cueri, thisDay)
      descrRST  = rst2html(thisEvent[2])
      libravatarUrl = getLibravatarUrl(thisEvent[4])
      isAdmin = c.rank in [Admin, Moderator]
    if thisEvent[0] != "":
      resp genMain(c, genEvent(thisEvent, descrRST, libravatarUrl, isAdmin))  # & bulma(c)
    else:
      var hasEventList: seq[string]
      for adate in 1..daysInMo:
        hasEventList.add getRow(db, cueri, parse($year & "-" & $mont & "-" & $adate, "yyyy-M-d").utc.toTime.toUnix)[1]
      resp genMain(c, genCalendar(year, mont, dayz, daysInMo, $dayOneIs, hasEventList, isAdmin))  # & bulma(c)

  post "/calendar/save":
    createTFD()
    restrictTestuser(HttpGet)
    restrictAccessTo(c, [Admin, Moderator])
    const cueri = sql"""
      INSERT INTO calendar(
        title, description, color, email, web, location, maxPeople, eventDate,
        isRemote, isFree, isMinorsOk, hasA11y, hasBikePark, hasCarPark, hasFood, hasDrink,
        hasBTC, needNotebook, isWeatherOk, hasPower, hasWifi, hasAC, hasBathroom, hasSit
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"""
    let
      year: range[2019..2999] = @"year".parseInt
      mont: range[1..12]      = @"mont".parseInt
      dayz: range[1..31]      = @"dayz".parseInt
    if mont == 2: doAssert dayz < 30, "February days must not be >29: " & $dayz
    exec(db, cueri,
      @"title".normalize,
      @"description".strip,
      @"color".strip.toLowerAscii,
      @"email".strip.toLowerAscii,
      @"web".strip,
      @"location".strip,
      @"maxPeople".parseInt,
      parse($year & "-" & $mont & "-" & $dayz, "yyyy-M-d").utc.toTime.toUnix,
      @"isRemote".len,
      @"isFree".len,
      @"isMinorsOk".len,
      @"hasA11y".len,
      @"hasBikePark".len,
      @"hasCarPark".len,
      @"hasFood".len,
      @"hasDrink".len,
      @"hasBTC".len,
      @"needNotebook".len,
      @"isWeatherOk".len,
      @"hasPower".len,
      @"hasWifi".len,
      @"hasAC".len,
      @"hasBathroom".len,
      @"hasSit".len
    )
    redirect "/"

  post "/calendar/reset":
    createTFD()
    restrictTestuser(HttpGet)
    restrictAccessTo(c, [Admin, Moderator])
    resp "<meta http-equiv='refresh' content='3;url=/'/><h1>" & $tryExec(db, sql"DELETE FROM calendar WHERE id = ?", @"eventid")  # UX IQ200 ;P
