package require Tcl 9.0
package require json

namespace eval zstatus::metar::decode {
	variable  metar_api 		https://aviationweather.gov/api/data/metar
	variable  station_api 		https://aviationweather.gov/api/data/stationinfo

	set pi			3.14159265358979
	set obliquity 		23.4363
	set julian1970 		2440587.5
	set julian2000		2451545
	set km_mile		1.609344
	set km_nautical_mile	1.852
	set cm_inch		2.54
	set cm_feet		30.48
	set kp_mmhg		0.133322

	set labeldict [dict create\
		windchill {C {Wind chill:} fr {Refroidissment éolien :}}\
		humidex {C {Humidex:} fr {Humidex :}}\
		success {C {Request completed at} fr {Requête complétée à}}\
		failed {C {Request failed at} fr {Requête échouée à}}\
		nodesc {C {No description for} fr {Description manquante pour}}]

	set precip_notes [dict create\
		VC	{C {in the vicinity} fr {au voisinage}}\
		RE	{C {(recent)} fr {(récent)}}]

	set precip_codes [dict create\
		DZ	{C drizzle fr bruine icon rain1}\
		FZDZ	{C {freezing drizzle} fr {bruine verglaçante} icon rain1}\
		RA	{C rain fr pluie icon rain2}\
		+RA	{C {heavy rain} fr {pluie forte} icon rain3}\
		-RA	{C {light rain} fr {pluie légère} icon rain1}\
		SHRA	{C {rain showers} fr {averses de pluie} icon rain3}\
		-SHRA	{C {light rain showers} fr {légères averses de pluie} icon rain2}\
		+SHRA	{C {heavy rain showers} fr {fortes averses de pluie} icon rain3}\
		TSRA	{C {thunderstorms} fr {orages} icon thunder}\
		-TSRA	{C {light thunderstorms} fr {orages faibles} icon thunder}\
		+TSRA	{C {heavy thunderstorms} fr {orages forts} icon thunder}\
		FZRA	{C {freezing rain} fr {pluie verglacante} icon rain2}\
		-FZRA	{C {light freezing rain} fr {faible pluie verglaçante} icon rain1}\
		+FZRA	{C {heavy freezing rain} fr {forte pluie verglaçante} icon rain3}\
		SN	{C snow fr neige icon snow}\
		+SN	{C {heavy snow} fr {neige forte} icon snow}\
		-SN	{C {light snow} fr {neige légère} icon snow}\
		SHSN	{C {snow showers} fr {averses de neige} icon snow}\
		-SHSN	{C {light snow showers} fr {légères averses de neige} icon snow}\
		+SHSN	{C {heavy snow showers} fr {fortes averses de neige} icon snow}\
		DRSN	{C {low drifting snow} fr {chasse basse de neige} icon snow}\
		BLSN	{C {blowing snow} fr {chasse haute de neige} icon snow}\
		SG	{C {snow grains} fr {neige en grains} icon snow}\
		IC	{C {ice crystals} fr {cristaux de glace} icon crystal}\
		PL	{C {ice pellets} fr {granules de glace} icon crystal}\
		GR	{C hail fr grêle icon hail}\
		+GR	{C {heavy hail} fr {grêle forte} icon hail}\
		-GR	{C {light hail} fr {grêle légère} icon hail}\
		GS	{C {small hail} fr {petite grêle} icon hail}\
		UP	{C {unknown precipitations} fr {précipitations inconnues} icon nometar}\
		BR	{C mist fr brume icon fog}\
		FG	{C fog fr brouillard icon fog}\
		BCFG	{C {patches of fog} fr {bancs de brouillard} icon fog}\
		FZFG	{C {freezing fog} fr {brouillard verglaçant} icon fog}\
		MIFG	{C {shallow fog} fr {brouillard mince} icon fog}\
		PRFG	{C {partial fog} fr {brouillard partiel} icon fog}\
		FU	{C smoke fr fumée icon dust}\
		VA	{C {volcanic ash} fr {cendre volcanique} icon dust}\
		DU	{C dust fr poussière icon dust}\
		DRDU	{C {low drifting dust} fr {chasse basse de poussière} icon dust}\
		BLDU	{C {blowing dust} fr {chasse haute de poussière} icon dust}\
		SA	{C sand fr sable icon dust}\
		DRSA	{C {low drifting sand} fr {chasse basse de sable} icon dust}\
		BLSA	{C {blowing sand} fr {chasse haute de sable} icon dust}\
		HZ	{C haze fr {brume sèche} icon fog}\
		PO	{C {dust whirls} fr {tourbillons de poussière} icon tornado}\
		SQ	{C squalls fr grains icon squall}\
		+FC	{C tornadoes fr tornades icon tornado}\
		FC	{C {funnel clouds} fr entonnoirs icon tornado}\
		SS	{C {sand storm} fr {tempête de sable} icon dust}\
		DS	{C {dust storm} fr {tempête de poussière} icon dust}]

	set cloud_codes [dict create\
		SKC	{C {Clear sky} fr {Ciel dégagé} icon clear}\
		FEW	{C {Few clouds} fr {Quelques nuages} icon cloud1}\
		SCT	{C {Scattered clouds} fr {Nuages dispersés} icon cloud2}\
		BKN	{C {Broken clouds} fr {Éclaircies} icon cloud2}\
		OVC	{C {Overcast} fr {Couvert} icon overcast}\
		CLR	{C {No low clouds} fr {Aucun nuage bas} icon clear}\
		NSC	{C {No low clouds} fr {Aucun nuage bas} icon clear}\
		NCD	{C {No clouds} fr {Aucun nuage} icon clear}\
		VV	{C {Darkened sky} fr {Ciel obscurci} icon overcast}]

	set cloud_types [dict create\
		CB	{C {Cumulonimbus} fr {Cumulonimbus}}\
		TCU	{C {Towering cumulus} fr {Cumulus bourgeonnant}}]

	set direction [dict create\
		{000}	{C N fr N}  	{010}	{C N fr N}\
		{020}	{C NNE fr NNE} 	{030}	{C NNE fr NNE}\
		{040}	{C NE fr NE}	{050}	{C NE fr NE}\
		{060}	{C ENE fr ENE} 	{070}	{C ENE fr ENE}\
		{080}	{C E fr E}	{090}	{C E fr E}\
		{100}	{C E fr E}	{110}	{C ESE fr ESE}\
		{120}	{C ESE fr ESE}	{130}	{C SE fr SE}\
		{140}	{C SE fr SE}	{150}	{C SSE fr SSE}\
		{160}	{C SSE fr SSE}	{170}	{C S fr S}\
		{180}	{C S fr S}	{190}	{C S fr S}\
		{200}	{C SSW fr SSE}	{210}	{C SSW fr SSE}\
		{220}	{C SW fr SO}	{230}	{C SW fr SO}\
		{240}	{C WSW fr OSO}	{250}	{C WSW fr OSO}\
		{260}	{C W fr O}	{270}	{C W fr O}\
		{280}	{C W fr O}	{290}	{C WNW fr ONO}\
		{300}	{C WNW fr ONO}	{310}	{C NW fr NO}\
		{320}	{C NW fr NO}	{330}	{C NNW fr NNO}\
		{340}	{C NNW fr NNO}	{350}	{C N fr N}\
		{360}	{C N fr N}]

	namespace export fetch_station get_report
}

proc zstatus::metar::decode::current_day {} {
	variable timezone
	set currenttime [clock seconds]

	set fixedtime [clock format $currenttime -format {%Y-%m-%d 12:00:00}\
			-timezone $timezone]
	set currentday [expr round([clock scan $fixedtime -format {%Y-%m-%d %H:%M:%S}\
			-timezone $timezone]/86400.0)]
}

proc zstatus::metar::decode::current_date {} {
	variable timezone
	set currenttime [clock seconds]
	set datetime [clock format $currenttime -format {%Y-%m-%d}\
			-timezone $timezone]
}

proc zstatus::metar::decode::calc_seconds {datetime} {
	variable timezone
	set currenttime [clock scan $datetime -format {%Y-%m-%d %H:%M:%S}\
			-timezone $timezone]
}

proc zstatus::metar::decode::calc_timezone_offset {} {
	variable timezone
	set currenttime [clock seconds]
	set tzoffset [clock format $currenttime -format {%z} -timezone $timezone]
	set len [string length $tzoffset]
	set moffset [expr [scan [string range $tzoffset $len-2 $len-1] %f]/60]
	set hoffset [expr [scan [string range $tzoffset 0 $len-3] %f]]
	if {$hoffset < 0} {
		set tzoffset [expr ($hoffset - $moffset)]
	} else {
		set tzoffset [expr ($hoffset + $moffset)]
	}
	return $tzoffset
}

proc zstatus::metar::decode::fetch_station {code} {
	variable station_api
	variable station
	set station {}

	if [catch {set message [exec -ignorestderr -- curl -s \
		$station_api?ids=$code]}] {return $station}
	if ![string length $message] {return $station}

	set station {*}[json::json2dict $message]
	return $station
}

proc zstatus::metar::decode::calc_daylight {} {
	variable report
	variable station
	variable timezone

	set report(site) [dict get $station site]

	variable julian1970
	variable julian2000
	set julian_day [expr [current_day] + $julian1970 - $julian2000]

	# Anomalie moyenne de la terre
	set AM [expr fmod(357.5291 + 0.98560028*$julian_day, 360.0)]

	# Facteur d'excentricité
	variable pi
	set EC [expr 1.91476*sin($AM*$pi/180.0) \
			+ 0.020*sin(2.0*$AM*$pi/180.0) \
			+ 0.00029*sin(3.0*$AM*$pi/180.0) ]

	# Longitude écliptique du soleil
	set LE [expr fmod(280.4665 + 0.98564736*$julian_day + $EC, 360.0)]

	# Facteur d'obliquité en degrés
	set OB [expr -2.46569*sin(2.0*$LE*$pi/180.0) \
			+ 0.0530*sin(4.0*$LE*$pi/180.0) \
			- 0.0014*sin(6.0*$LE*$pi/180.0) ]

	# Equation du temps
	set EQT [expr $EC + $OB]

	variable obliquity
	set sun_dec [expr asin(sin($obliquity*$pi/180.0)\
			 *sin($LE*$pi/180.0))]
	set latitude [dict get $station lat]
	set station_lat [expr $latitude*$pi/180.0]

	set cos_station_lat [expr cos($station_lat)]
	if {!$cos_station_lat} {
		# Cas spécial pour les pôles
		set cos_station_lat 0.0001
		set tan_station_lat 10000.0
	} else {
		set tan_station_lat [expr tan($station_lat)]
	}

	# Estimation de 29 minutes d'arc de réfraction à l'horizon
	# Plus le demi-diamètre apparent du soleil environ 16 minutes d'arc
	# Soit une correction de 45 minutes d'arc ou 0.75 degrés
	set refract [expr sin(0.75*$pi/180.0)/$cos_station_lat]

	set cos_H0 [expr -tan($sun_dec) * $tan_station_lat - $refract]
	if {$cos_H0 >= 1} {
		# Nuit polaire
		set report(daylight) 0
		set report(sunrise) "N/A"
		set report(sunset) "N/A"
	} elseif {$cos_H0 <= -1} {
		# Jour polaire
		set report(daylight) 1
		set report(sunrise) "N/A"
		set report(sunset) "N/A"
	} else {
		set H0 [expr acos($cos_H0) *180.0/$pi]
		set tzoffset [calc_timezone_offset]
		set longitude [dict get $station lon]
		set sunrise [expr (180.0 - $H0 + $EQT - $longitude)/15.0\
				+ $tzoffset]
		set sunset [expr (180.0 + $H0 + $EQT - $longitude)/15.0\
				 + $tzoffset]

		set hour1 [expr int(floor($sunrise))]
		set min1 [format {%02d} [expr round(fmod($sunrise,1.0) * 60)]]
		set hour2 [expr int(floor($sunset))]
		set min2 [format {%02d} [expr round(fmod($sunset,1.0) * 60)]]

		if {$min1 == 60} {
			set hour1 [expr $hour1 + 1]
			set min1 "00"
		}
		if {$min2 == 60} {
			set hour2 [expr $hour2 + 1]
			set min2 "00"
		}

		set report(sunrise) "$hour1:$min1"
		set report(sunset) "$hour2:$min2"

		set currenttime [clock seconds]
		set currentdate [current_date]
		set sunrisetime [calc_seconds "$currentdate $hour1:$min1:00"]
		set sunsettime [calc_seconds "$currentdate $hour2:$min2:00"]
		if {$currenttime > $sunrisetime && $currenttime < $sunsettime} {
			set report(daylight) 1
		} else {
			set report(daylight) 0
		}
	}
	return $report(daylight)
}

proc zstatus::metar::decode::get_weather_icon {daylight} {
	variable latest
	variable precip_codes

	if {[dict exists $latest precip_code]} {
		set code [dict get $latest precip_code]
		set icon [dict get $precip_codes $code icon]
		return $::remix($icon)
	}

	if {$daylight == 1} {
		set suffix "day"
	} else {
		set suffix "night"
	}

	if {[dict exists $latest cloud_code]} {
		variable cloud_codes
		set icon [dict get $cloud_codes [dict get $latest cloud_code] icon]
		if {$icon != "overcast"} {
			set icon "${icon}_$suffix"
		}
		return $::remix($icon)
	}
	return $::remix(nometar)
}

proc zstatus::metar::decode::calc_windchill {temperature windspeed} {
	if {$windspeed < 4.0} {
		set windchill [expr $temperature + 0.2 * (0.1345 * $temperature -1.59)\
				* $windspeed]
	} else {
		set windchill [expr 13.12 + 0.6215 * $temperature \
				+ (0.3965 * $temperature - 11.37) * pow($windspeed, 0.16)]
	}
	set diff [expr round( $temperature - $windchill)]
	if {$diff >= 1} {
		set windchill [expr round($windchill)]
	} else {
		set windchill ""
	}
	return $windchill
}

proc zstatus::metar::decode::calc_rel_humidity {temperature dew} {
	# Utilise l'équation de Buck pour calculer les pressions saturantes de vapeur d'eau
	set p1 [expr 0.01121 * exp((18.678 - $temperature/234.5) \
		* ($temperature/(257.14 + $temperature)))]
	set p2 [expr 0.01121 * exp((18.678 - $dew/234.5) \ * ($dew/(257.14 + $dew)))]
	set rel_humidity [expr round(100 * $p2/$p1)]
}

proc zstatus::metar::decode::calc_humidex {temperature dew} {
	set humidex [expr $temperature + 0.5555 * (6.11 * exp( 5417.753 * \
		(1/273.16 - 1/($dew + 273.16))) - 10.0)]
	if {$humidex > 24} {
		set humidex [expr round($humidex)]
	} else {
		set humidex ""
	}
	return $humidex
}

proc zstatus::metar::decode::decode_datetime {datetime} {
	variable latest
	variable timezone
	variable locale

	set day [string range $datetime 0 1]
	set hour [string range $datetime 2 3]
	set minute [string range $datetime 4 5]

	set currenttime [clock seconds]
	set date [clock format $currenttime -format {%Y-%m} -timezone :UTC]
	set date "$date-$day $hour:$minute:00"
	set rtime [clock scan $date -format {%Y-%m-%d %H:%M:%S} -timezone :UTC]
	dict set latest date [clock format $rtime -format {%d %B %H:%M %Z}\
			 -locale $locale -timezone $timezone]
	dict set latest daytime [clock format $rtime -format {%a %H:%M}\
			 -locale $locale -timezone $timezone]
}

proc zstatus::metar::decode::decode_wind {wdir wspeed wgust} {
	variable latest
	variable direction
	variable locale

	variable km_nautical_mile
	dict set latest speed [expr round([scan $wspeed %d] * $km_nautical_mile)]
	if {[string length $wgust]} {
		dict set latest gust [expr round([scan $wgust %d] * $km_nautical_mile)]
	}
	dict set latest direction [dict get $direction $wdir $locale]
}

proc zstatus::metar::decode::decode_lightwind {wspeed} {
	variable latest
	dict set latest speed [expr round($wspeed * 1.852)]
}

proc zstatus::metar::decode::decode_temp {m1 tcode m2 dcode} {
	variable latest
	if {[string length $m1]} {
		dict set latest temp [expr round(-[scan $tcode %d])]
	} else {
		dict set latest temp [expr round([scan $tcode %d])]
	}
	if {[string length $m2]} {
		dict set latest dew [expr round(-[scan $dcode %d])]
	} else {
		dict set latest dew [expr round([scan $dcode %d])]
	}
}

proc zstatus::metar::decode::decode_visibility {vcode} {
	variable km_mile
	variable latest
	set divider [expr [string first "/" $vcode]]
	if {$divider != -1} {
		set numerator [string range $vcode 0 $divider-1]
		set denominator [string range $vcode $divider+1 end]
		if {![string length $denominator]} {
			set denominator "1"
		}
		dict set latest visibility [format {%0.1f} [expr round(10 * $km_mile \
					* $numerator / $denominator)/10.0]]
	} else {
		dict set latest visibility [format {%0.1f} [expr round(10 * $km_mile \
					* $vcode)/10.0]]
	}
}

proc zstatus::metar::decode::decode_pressure {pcode} {
	variable latest
	variable cm_inch
	variable kp_mmhg
	dict set latest pressure [format {%0.1f} [expr round([scan $pcode %d] \
				* $cm_inch * $kp_mmhg)/10.0]]
}

proc zstatus::metar::decode::decode_clouds {code alt type} {
	variable cloud_codes
	variable cloud_types
	variable latest
	variable locale

	dict set latest cloud_desc [dict get $cloud_codes $code $locale]
	dict set latest cloud_code $code

	variable cm_feet
	if {[string length $alt]} {
		set altitude [expr 100 * round([scan $alt %d] * $cm_feet / 100)]
		set description "[dict get $latest cloud_desc], $altitude m"
		if {![dict exists $latest clouds]} {
			dict set latest clouds $description
		} else {
			dict append latest clouds "\n" $description
		}
	} else {
		if {![dict exists $latest clouds]} {
			dict set latest clouds [dict get $latest cloud_desc]
		} else {
			dict append latest clouds "\n" [dict get $latest cloud_desc]]
		}
	}
	if {[string length $type]} {
		dict set latest cloud_type [dict get $cloud_types $type $locale]
	}
}

proc zstatus::metar::decode::decode_precips {intensity qualifier precips} {
	variable precip_codes
	variable precip_notes
	variable locale
	variable latest

	set suffix ""
	if {$intensity == "VC" || $intensity == "RE"} {
		set suffix [dict get $precip_notes intensity $locale]
		set intensity ""
	}

	set codes {}
	while [string length $precips] {
		if [regexp {^(DZ|RA|SN|SG|IC|PL|GR|GS|UP|BR|FG|FU|VA|DU|SA|HZ|PO|SQ|[+]FC|FC|SS|DS)([A-Z+]{2,})?$}\
			$precips -> pcode precips] {
			lappend codes $pcode
		}
		break
	}

	variable labeldict
	foreach pcode $codes {
		set fullcode "${intensity}${qualifier}${pcode}"
		if [dict exists $precip_codes $fullcode $locale] {
			set deccription [dict get $precip_codes $fullcode $locale]
			set deccription "$description $suffix"
		} else {
			set description "[dict get $labeldict nodesc $locale] $fullcode"
		}
		if {![dict exists $latest precips]} {
			dict set latest precips $description
			dict set latest precip_desc $description
			dict set latest precip_code $fullcode
		} else {
			dict append latest precips "\n" $description
		}
	}
}

proc zstatus::metar::decode::fetch_metar_report {} {
	variable station
	variable metar_api

	if [catch {set message [exec -ignorestderr -- curl -s \
			$metar_api?ids=[dict get $station icaoId]]}] {return ""}
	return $message
}

proc zstatus::metar::decode::decode_metar_report {message} {
	variable station
	if {![string length $message]} {return 0}
	set tokens [split $message " "]
	foreach token $tokens {
		if {$token == "RMK"} break
		if {$token == "METAR"} continue
		if {$token == "SPECI"} continue
		if {$token == [dict get $station icaoId]} continue

		if [regexp {^([0-9]{6})Z$} $token -> datetime] {
			decode_datetime $datetime
			continue
		} elseif [regexp {^([0-9]{3})([0-9]{2})(G([0-9]{2}))?KT$}\
			$token -> dir speed gust0 gust1] {
			decode_wind $dir $speed $gust1
			continue
		} elseif [regexp {^VRB([0-9]{2})KTS$} $token -> lspeed] {
			decode_lightwind $lspeed
			continue
		} elseif [regexp {^(M)?([0-9]{2})/(M)?([0-9]{2})$}\
			$token -> m1 temp m2 dew] {
			decode_temp $m1 $temp $m2 $dew
			continue
		} elseif [regexp {^([0-9/]{1,4})SM$} $token -> visibility] {
			decode_visibility $visibility
			continue
		} elseif [regexp {^A([0-9]{4})$} $token -> pressure] {
			decode_pressure $pressure
			continue
		} elseif [regexp {^(SKC|FEW|SCT|BKN|OVC|CLR|VV)([0-9]{3})?(CB|TCU)?$}\
			$token -> descr altitude type ] {
			decode_clouds $descr $altitude $type
			continue
		} elseif [regexp {^(-|[+]|RE|VC)?(BC|DR|BL|FZ|MI|PR|SH|TS)?([A-Z+]{2,9})$}\
			$token -> intensity qualifier precips] {
			decode_precips $intensity $qualifier $precips
			continue
		}
	}
	return 1
}

proc zstatus::metar::decode::get_report {plocale ptimezone} {
	variable latest
	variable report
	variable locale
	variable timezone
	variable labeldict

	set locale $plocale
	set timezone $ptimezone
	set now [clock seconds]
	set reporttime [clock format $now -format {%H:%M}\
			 -timezone $timezone]

	set latest {}
	if [decode_metar_report [fetch_metar_report]] {
		set latest_date [dict get $latest date]
		set latest_temp [dict get $latest temp]
		set latest_dew [dict get $latest dew]

		set report(date) $latest_date
		set report(temperature) "$latest_temp]°C"
		set report(dew) "$latest_dew°C"

		if {[dict exists $latest speed]} {
			set latest_speed [dict get $latest speed]
			set report(wind) "$latest_speed km/h"
			if {[dict exists $latest direction]} {
				append report(wind) " " [dict get $latest direction]
			}
			set windchill [calc_windchill $latest_temp $latest_speed]
		} else {
			set report(wind) ""
			set windchill ""
		}

		if {[dict exists $latest gust]} {
			set report(gust) "[dict get $latest gust] km/h"
		} else {
			set report(gust) ""
		}

		set report(note) ""
		set report(note_val) ""
		if {[string length $windchill]} {
			set report(note) [dict get $labeldict windchill $locale]
			set report(note_val) "$windchill°C"
		}

		set report(pressure) ""
		set report(pressure_icon) ""
		if {[dict exists $latest pressure]} {
			set latest_pressure [dict get $latest pressure]
			if {[info exists report(prev_pressure)] &&\
				$latest_date != $report(prev_date)} {
				set prev_pressure $report(prev_pressure)
				if {$latest_pressure > $prev_pressure} {
					set report(pressure_icon) $::arrowup
				} elseif {$latest_pressure < $prev_pressure} {
					set report(pressure_icon) $::arrowdown
				}
			}
			set report(prev_date) $latest_date
			set report(prev_pressure) $latest_pressure
			set report(pressure)\
				"$latest_pressure kPa $report(pressure_icon)"
		}

		set humidex [calc_humidex $latest_temp $latest_dew]
		if {[string length $humidex]} {
			set report(note) [dict get $labeldict humidex $locale]
			set report(note_val) "$humidex°C"
		}

		set report(rel_humidity) "[calc_rel_humidity $latest_temp $latest_dew]%"

		set report(visibility) ""
		if [dict exists $latest visibility] {
			set report(visibility) "[dict get $latest visibility] km"
		}
		set report(clouds) ""
		if [dict exists $latest clouds] {
			set report(clouds) [dict get $latest clouds]
		}
		set report(precips) ""
		if [dict exists $latest precips] {
			set report(precips) [dict get $latest precips]
		}

		set report(weather_icon) [get_weather_icon [calc_daylight]]
		set report(statusbar) "$report(weather_icon) $latest_temp°C"

		set report(summary) "$latest_temp°C"
		if [dict exists $latest precip_desc] {
			append report(summary) ", " [dict get $latest precip_desc]
		} elseif [dict exists $latest cloud_desc] {
			append report(summary) ", " [dict get $latest cloud_desc]
		}
		set report(tooltip) "[dict get $latest daytime]:  $report(summary)"
		set report(request_message)\
			"[dict get $labeldict success $locale] $reporttime"
	} else {
		set report(statusbar) $::remix(failed)
		set report(request_message)\
			"[dict get $labeldict failed $locale] $reporttime"
		set report(tooltip) $report(request_message)
	}

	return [array get report]
}
package provide @PACKAGE_NAME@::decode @PACKAGE_VERSION@
