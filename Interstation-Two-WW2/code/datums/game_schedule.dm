var/datum/game_schedule/global_game_schedule = null

/datum/game_schedule
	// when the game is open to non-staff, UTC (5 hours ahead of EST)
	var/starttime = 16 // MUST be an integer
	// when the game is closed to non-staff, UTC (5 hours ahead of EST)
	var/endtime = 21 // MUST be an integer
	// days the game is CLOSED
	var/list/days_closed = list()
	// days the game is always open (WIP!)
	var/list/days_always_open = list()
	// a reference realtime, date (in DD-MM-YY format) and day:
	// this is not 100% accurate, but because starttime, endtime, are
	// independent of this, it doesn't matter
	var/refdate = "5619460480:22-10-17:Sunday"
	// DO NOT CHANGE THIS **EVER** OR ALL BANS AND STUFF BREAK
	var/refdate_static = "5619460480:22-10-17:Sunday"
	// the time in hours (decimal)
	var/time = -1
	// the day
	var/day = "Sunday"
	// stored value of world.realtime at the time of creation
	var/realtime = -1
	// and so we can read realtime it in standard notation
	var/realtime_as_string = ""
	// other stored strings
	var/scheduleString = ""
	var/dateInfoString = ""
	// admin
	var/forceClosed = 0

/datum/game_schedule/New()
	update()

/datum/game_schedule/proc/update()

	time = getCurrentTime()

	world_is_open = 0

	if (time >= starttime)
		if (time <= endtime)
			world_is_open = 1
		else if (time >= endtime)
			if (endtime <= starttime)
				world_is_open = 1
	else if (time <= starttime)
		if (time <= endtime)
			world_is_open = 1

	// determine the day by counting from refdate's day
	var/split = splittext(refdate, ":")
	var/ref_realtime = text2num(split[1])
//	var/ref_date = split[2] // currently unused: commented out to avoid errors
	var/ref_day = split[3]
	var/days_elapsed = round((world.realtime - ref_realtime)/864000)
	for (var/v in 1 to days_elapsed)
		ref_day = nextDay(ref_day)

	day = ref_day
	realtime = world.realtime
	realtime_as_string = num2text(realtime, 20)

	// hard overrides for opening or closing the world
	if (days_closed.Find(day))
		world_is_open = 0
	else if (days_always_open.Find(day))
		world_is_open = 1

	if (forceClosed)
		world_is_open = 0

/datum/game_schedule/proc/forceClose()
	forceClosed = 1
	update()
	for (var/client/C in clients)
		if (!C.holder)
			C << "<span class = 'userdanger'>The server has been closed.</span>"
			spawn (1)
				del C

/datum/game_schedule/proc/unforceClose()
	forceClosed = 0
	update()

/datum/game_schedule/proc/getCurrentTime(var/unit = "hours")
	// first, get the number of seconds that have elapsed since 00:00:00 today
	. = world.timeofday/10
	// now convert that to minutes
	. /= 60
	// now convert that to hours
	. /= 60
	// now we've returned the current time

	switch (unit)
		if ("hours")
			return .
		if ("minutes")
			return .*60
		if ("seconds")
			return .*60*60
		if ("deciseconds")
			return .*60*60*10

/datum/game_schedule/proc/getNewRealtime()
	var/reftime = text2num(splittext(refdate_static, ":")[1])
	reftime += getCurrentTime("deciseconds")

/datum/game_schedule/proc/getScheduleAsString()
	. = "from [starttime] to [endtime] UTC"
	if (days_closed.len)
		. += ", but is closed on "
		if (days_closed.len > 1)
			for (var/day in days_closed)
				. += day
				if (days_closed[days_closed.len] != day)
					if (days_closed[days_closed.len-1] == day)
						. += " and "
					else
						. += ", "
		else
			. += "[days_closed[1]]"
	if (days_always_open.len)
		. += ", and is always open on "
		if (days_always_open.len > 1)
			for (var/day in days_always_open)
				. += day
				if (days_always_open[days_always_open.len] != day)
					if (days_always_open[days_always_open.len-1] == day)
						. += " and "
					else
						. += ", "
		else
			. += "[days_always_open[1]]"

	scheduleString = .

/datum/game_schedule/proc/getDateInfoAsString()
	. = "[day], [getCurrentTime()] UTC"
	dateInfoString = .

/proc/nextDay(day)
	switch (day)
		if ("Monday")
			return "Tuesday"
		if ("Tuesday")
			return "Wednesday"
		if ("Wednesday")
			return "Thursday"
		if ("Thursday")
			return "Friday"
		if ("Friday")
			return "Saturday"
		if ("Saturday")
			return "Sunday"
		if ("Sunday")
			return "Monday"