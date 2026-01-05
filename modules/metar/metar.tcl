package require Tk
package require zstatus::metar::decode

namespace eval zstatus::metar {
	set style [dict create\
		title1 {font large2 light black dark gray80}\
		label1 {font italic2 light black dark gray80}\
		value1 {font large light DarkBlue dark CadetBlue3}\
		value2 {font large light DarkGreen dark PaleGreen3}\
		summary {font large2 light DarkGreen dark PaleGreen3}\
		icon {font remix2 light DarkGreen dark PaleGreen3}\
		tooltip {font normal light black dark gray80}]

	set metar_locales {C fr}
	set labeldict [dict create\
		nostation {C "METAR station invalid or missing"\
			 fr "Station METAR non valide ou manquante"}\
		weather {C "Weather conditions:" fr "Conditions météorologiques :"}\
		station {C "Station:" fr "Station :"}\
		issued {C "Issued on:" fr "Émis le :"}\
		status {C "Status:" fr "Statut :"}\
		wind {C "Wind:" fr "Vent :"}\
		gust {C "Gust:" fr "Rafale :"}\
		dew {C "Dew point:" fr "Point de rosée :"}\
		rhumidity {C "Relative humidity:" fr "Humidité relative :"}\
		pressure {C "Pressure:" fr "Pression :"}\
		visibility {C "Visibility:" fr "Visibilité :"}\
		clouds {C "Clouds:" fr "Nuages :"}\
		precips {C "Precipitations:" fr "Précipitations :"}\
		sun {C "Sun" fr "Soleil"}\
		sunrise {C "Sunrise:" fr "Lever :"}\
		sunset {C "Sunset:" fr "Coucher :"}]

	set station {}
	variable  popup_visible 0
	namespace export setup update set_theme show_tooltip hide_tooltip
}

proc zstatus::metar::show_tooltip {} {
	variable bgcolor
	variable fgcolor
	variable metarfont
	variable barwidget
	variable metarwidget

	set window [toplevel .metartooltip -highlightthickness 0\
			-background $bgcolor]

	set xpos [winfo x $metarwidget]
	set ypos [expr [winfo y $barwidget] + [winfo height $barwidget] + 1]

	wm title $window "Metar Summary"
	wm attributes $window -type dialog
	wm overrideredirect $window 1
	wm geometry $window +$xpos+$ypos

	pack [label $window.text -font $metarfont\
		-fg $fgcolor -bg $bgcolor\
		-textvar zstatus::metar::report(tooltip)]\
		-side left -padx 5 -pady 3

	bind $window <Map> { zstatus::map_window .metartooltip }
}

proc zstatus::metar::hide_tooltip {} {
	destroy .metartooltip
}

proc zstatus::metar::toggle_popup {} {
	variable station
	variable popup
	variable bgcolor
	variable barwidget
	variable metarwidget

	if ![dict exists $station icaoId] { return }

	variable popup_visible
	if {$popup_visible} {
		destroy $popup
		set popup_visible 0
	} else {
		set popup [toplevel .metarreport -class Metar -bd 1 -relief solid]
		setup_header $popup.header
		setup_summary $popup.summary
		setup_grid $popup.grid

		$popup configure -background $bgcolor
		set_theme_header $popup.header
		set_theme_summary $popup.summary
		set_theme_grid $popup.grid

		update_grid $popup.grid

		wm attributes $popup -type dialog
		wm overrideredirect $popup 1
		wm title $popup {Metar Report}

		set xpos [winfo x $metarwidget]
		set ypos [expr [winfo y $barwidget] + [winfo height $barwidget] + 1]
		wm geometry $popup +$xpos+$ypos
		set popup_visible 1

		bind $popup <3> { zstatus::metar::toggle_popup }
		bind $popup <Map> { zstatus::map_window .metarreport }
	}
}

proc zstatus::metar::set_theme_header {header} {
	variable bgcolor
	variable style
	variable theme

	$header configure -background $bgcolor
	$header.keys configure -background $bgcolor
	$header.keys.station configure -background $bgcolor
	$header.keys.station.text configure -bg $bgcolor\
		-fg [dict get $style label1 $theme]
	$header.keys.date configure -background $bgcolor
	$header.keys.date.text configure -bg $bgcolor\
		-fg [dict get $style label1 $theme]
	$header.keys.status configure -background $bgcolor
	$header.keys.status.text configure -bg $bgcolor\
		-fg [dict get $style label1 $theme]
	$header.values configure -background $bgcolor
	$header.values.station configure -background $bgcolor
	$header.values.station.text configure -bg $bgcolor\
		-fg [dict get $style value1 $theme]
	$header.values.date configure -background $bgcolor
	$header.values.date.text configure -bg $bgcolor\
		-fg [dict get $style value1 $theme]
	$header.values.status configure -background $bgcolor
	$header.values.status.text configure -bg $bgcolor\
		-fg [dict get $style value1 $theme]
}

proc zstatus::metar::set_theme_summary {summary} {
	variable bgcolor
	variable sepcolor
	variable style
	variable theme

	$summary configure -background $bgcolor
	$summary.temp configure -background $bgcolor
	$summary.temp.status configure -background $bgcolor
	$summary.temp.status.icon configure -bg $bgcolor\
		-fg [dict get $style summary $theme]
	$summary.temp.status.text configure -bg $bgcolor\
		-fg [dict get $style summary $theme]
	$summary.temp.remark configure -background $bgcolor
	$summary.temp.remark.key configure -bg $bgcolor\
		-fg [dict get $style summary $theme]
	$summary.temp.remark.value configure -bg $bgcolor\
		-fg [dict get $style summary $theme]
	$summary.separator configure -background $sepcolor
	$summary.sun configure -background $bgcolor
	$summary.sun.text configure -bg $bgcolor\
		-fg [dict get $style label1 $theme]
	$summary.sun.sunrise_text configure -bg $bgcolor\
		-fg [dict get $style label1 $theme]
	$summary.sun.sunrise_hour configure -bg $bgcolor\
		-fg [dict get $style value1 $theme]
	$summary.sun.sunset_text configure -bg $bgcolor\
		 -fg [dict get $style label1 $theme]
	$summary.sun.sunset_hour configure -bg $bgcolor\
		-fg [dict get $style value1 $theme]
}

proc zstatus::metar::set_theme_grid {grid} {
	variable bgcolor
	variable style
	variable theme

	$grid configure -background $bgcolor
	$grid.title configure -bg $bgcolor -fg [dict get $style title1 $theme]
	$grid.wind configure -bg $bgcolor -fg [dict get $style label1 $theme]
	$grid.wind_val configure -bg $bgcolor -fg [dict get $style value2 $theme]
	$grid.gust configure -bg $bgcolor -fg [dict get $style label1 $theme]
	$grid.gust_val configure -bg $bgcolor -fg [dict get $style value2 $theme]
	$grid.dew configure -bg $bgcolor -fg [dict get $style label1 $theme]
	$grid.dew_val configure -bg $bgcolor -fg [dict get $style value2 $theme]
	$grid.rhumidity configure -bg $bgcolor -fg [dict get $style label1 $theme]
	$grid.rhumidity_val configure -bg $bgcolor -fg [dict get $style value2 $theme]
	$grid.pressure configure -bg $bgcolor -fg [dict get $style label1 $theme]
	$grid.pressure_val configure -bg $bgcolor -fg [dict get $style value2 $theme]
	$grid.visibility configure -bg $bgcolor -fg [dict get $style label1 $theme]
	$grid.visibility_val configure -bg $bgcolor -fg [dict get $style value2 $theme]
	$grid.clouds configure -bg $bgcolor -fg [dict get $style label1 $theme]
	$grid.clouds_val configure -bg $bgcolor -fg [dict get $style value2 $theme]
	$grid.precips configure -bg $bgcolor -fg [dict get $style label1 $theme]
	$grid.precips_val configure -bg $bgcolor -fg [dict get $style value2 $theme]
}

proc zstatus::metar::set_theme {newtheme} {
	variable theme
	variable bgcolor
	variable fgcolor
	variable sepcolor

	set theme $newtheme
	set bgcolor [dict get $::widgetdict metar bg $theme]
	set fgcolor [dict get $::widgetdict metar fg $theme]
	set sepcolor [dict get $::widgetdict separator bg $theme]

	variable popup_visible
	if {$popup_visible} {
		variable popup
		$popup configure -background $bgcolor
		set_theme_header $popup.header
		set_theme_summary $popup.summary
		set_theme_grid $popup.grid
	}
}

proc zstatus::metar::update_grid {grid} {
	variable report

	if {![string length $report(wind)]} {
		grid remove $grid.wind $grid.wind_val
	} else {
		grid $grid.wind $grid.wind_val
	}

	if {![string length $report(gust)]} {
		grid remove $grid.gust $grid.gust_val
	} else {
		grid $grid.gust $grid.gust_val
	}

	if {![string length $report(visibility)]} {
		grid remove $grid.visibility $grid.visibility_val
	} else {
		grid $grid.visibility $grid.visibility_val
	}

	if {![string length $report(pressure)]} {
		grid remove $grid.pressure $grid.pressure_val
	} else {
		grid $grid.pressure $grid.pressure_val
	}

	$grid.clouds_val delete 1.0 end
	if {[info exists report(clouds)]} {
		if {![string length $report(clouds)]} {
			grid remove $grid.clouds $grid.clouds_val
		} else {
			set width 0
			set lines [split $report(clouds) \n]
			set height [llength $lines]
			foreach line $lines {
				set width [tcl::mathfunc::max [\
						string length $line] $width]
			}
			$grid.clouds_val insert 1.0 $report(clouds)
			$grid.clouds_val configure -height $height -width $width
			grid $grid.clouds $grid.clouds_val
		}
	}

	$grid.precips_val delete 1.0 end
	if {[info exists report(precips)]} {
		if {![string length $report(precips)]} {
			grid remove $grid.precips $grid.precips_val
		} else {
			set width 0
			set lines [split $report(precips) \n]
			set height [llength $lines]
			foreach line $lines {
				set width [tcl::mathfunc::max [\
						string length $line] $width]
			}
			$grid.precips_val insert 1.0 $report(precips)
			$grid.precips_val configure -height $height -width $width
			grid $grid.precips $grid.precips_val
		}
	}
}

proc zstatus::metar::update {} {
	variable metarcode
	variable station
	variable locale
	variable labeldict
	variable report

	if ![dict exists $station icaoId] {
		set station [decode::fetch_station $metarcode]
		if ![dict size $station] {
			set report(statusbar) "<?>"
			set report(tooltip) [dict get $labeldict nostation $locale]
			return
		}
	}

	variable timezone
	array set report [decode::get_report $locale $timezone]

	variable popup_visible
	if {$popup_visible} {
		variable popup
		update_grid $popup.grid
	}
}

proc zstatus::metar::setup_header { header } {
	variable style
	variable locale
	variable labeldict
	variable report

	pack [frame $header] -padx 10 -pady 10 -side top -anchor w
	pack [frame $header.keys] -side left
	pack [frame $header.keys.station] -side top -anchor w
	pack [label $header.keys.station.text -font [dict get $style label1 font]\
			-text [dict get $labeldict station $locale]]
	pack [frame $header.keys.date]  -side top -anchor w
	pack [label $header.keys.date.text -font [dict get $style label1 font]\
			-text [dict get $labeldict issued $locale]]
	pack [frame $header.keys.status] -side top -anchor w
	pack [label $header.keys.status.text -font [dict get $style label1 font]\
			-text [dict get $labeldict status $locale]]
	pack [frame $header.values] -padx 5 -side left -anchor w
	pack [frame $header.values.station] -side top -anchor w
	pack [label $header.values.station.text -font [dict get $style value1 font]\
		-textvar zstatus::metar::report(site)]
	pack [frame $header.values.date] -side top -anchor w
	pack [label $header.values.date.text -font [dict get $style value1 font]\
		-textvar zstatus::metar::report(date)]
	pack [frame $header.values.status] -side top -anchor w
	pack [label $header.values.status.text -font [dict get $style value1 font]\
		-textvar zstatus::metar::report(request_message)]
}

proc zstatus::metar::setup_summary { summary } {
	variable style
	variable locale
	variable labeldict
	variable report

	pack [frame $summary] -padx 10 -side top -anchor w
	pack [frame $summary.temp] -side left
	pack [frame $summary.temp.status] -side top -anchor w
	pack [label $summary.temp.status.icon -font [dict get $style icon font]\
		-textvar zstatus::metar::report(weather_icon)] -side left
	pack [label $summary.temp.status.text -font [dict get $style summary font]\
		-textvar zstatus::metar::report(summary)] -side left -padx 5
	pack [frame $summary.temp.remark] -side top -anchor w
	pack [label $summary.temp.remark.key -font [dict get $style summary font]\
		-textvar zstatus::metar::report(note)] -side left
	pack [label $summary.temp.remark.value -font [dict get $style summary font]\
		-textvar zstatus::metar::report(note_val) ] -side left -padx 5
	pack [frame $summary.separator -width 1] -padx 10 -fill y -side left

	pack [frame $summary.sun] -anchor w -side left
	label $summary.sun.text -font [dict get $style label1 font]\
		-text [dict get $labeldict sun $locale]
	label $summary.sun.sunrise_text -font [dict get $style label1 font]\
		-text [dict get $labeldict sunrise $locale]
	label $summary.sun.sunrise_hour -font [dict get $style value1 font]\
		 -textvar zstatus::metar::report(sunrise)
	label $summary.sun.sunset_text -font [dict get $style label1 font]\
		-text [dict get $labeldict sunset $locale]
	label $summary.sun.sunset_hour -font [dict get $style value1 font]\
		-textvar zstatus::metar::report(sunset)

	grid configure $summary.sun.text -columnspan 2 -row 0 -column 0
	grid configure $summary.sun.sunrise_text -row 1 -column 0 -sticky w
	grid configure $summary.sun.sunrise_hour -row 1 -column 1 -sticky w
	grid configure $summary.sun.sunset_text -row 2 -column 0 -sticky w
	grid configure $summary.sun.sunset_hour -row 2 -column 1 -sticky w
}

proc zstatus::metar::setup_grid { grid } {
	variable style
	variable locale
	variable labeldict
	variable report

	set row 0
	pack [frame $grid] -padx 10 -pady 10 -side top -anchor w
	label $grid.title -font [dict get $style title1 font]\
		-text [dict get $labeldict weather $locale]
	grid configure $grid.title -columnspan 2 -row $row -column 0\
		 -pady 5 -sticky w

	incr row
	label $grid.wind -font [dict get $style label1 font]\
		-text [dict get $labeldict wind $locale]
	label $grid.wind_val -font [dict get $style value2 font]\
		-textvar zstatus::metar::report(wind)
	grid configure $grid.wind -row $row -column 0 -sticky w
	grid configure $grid.wind_val -row $row -column 1 -sticky w

	incr row
	label $grid.gust -font [dict get $style label1 font]\
		-text [dict get $labeldict gust $locale]
	label $grid.gust_val -font [dict get $style value2 font]\
		-textvar zstatus::metar::report(gust)
	grid configure $grid.gust -row $row -column 0 -sticky w
	grid configure $grid.gust_val -row $row -column 1 -sticky w

	incr row
	label $grid.dew -font [dict get $style label1 font]\
		-text [dict get $labeldict dew $locale]
	label $grid.dew_val -font [dict get $style value2 font]\
		-textvar zstatus::metar::report(dew)
	grid configure $grid.dew -row $row -column 0 -sticky w
	grid configure $grid.dew_val -row $row -column 1 -sticky w

	incr row
	label $grid.rhumidity -font [dict get $style label1 font]\
		-text [dict get $labeldict rhumidity $locale]
	label $grid.rhumidity_val -font [dict get $style value2 font] \
		-textvar zstatus::metar::report(rel_humidity)
	grid configure $grid.rhumidity -row $row -column 0 -sticky w
	grid configure $grid.rhumidity_val -row $row -column 1 -sticky w

	incr row
	label $grid.pressure -font [dict get $style label1 font]\
		-text [dict get $labeldict pressure $locale]
	label $grid.pressure_val -font [dict get $style value2 font]\
		-textvar zstatus::metar::report(pressure)
	grid configure $grid.pressure -row $row -column 0 -sticky w
	grid configure $grid.pressure_val -row $row -column 1 -sticky w

	incr row
	label $grid.visibility -font [dict get $style label1 font]\
		-text [dict get $labeldict visibility $locale]
	label $grid.visibility_val -font [dict get $style value2 font] \
		-textvar zstatus::metar::report(visibility)
	grid configure $grid.visibility -row $row -column 0 -sticky w
	grid configure $grid.visibility_val -row $row -column 1 -sticky w

	incr row
	label $grid.clouds -font [dict get $style label1 font]\
		-text [dict get $labeldict clouds $locale]
	text $grid.clouds_val -font [dict get $style value2 font] -borderwidth 0\
		 -highlightthickness 0 -wrap none
	grid configure $grid.clouds -row $row -column 0 -sticky nw
	grid configure $grid.clouds_val -row $row -column 1 -sticky w

	incr row
	label $grid.precips -font [dict get $style label1 font]\
		-text [dict get $labeldict precips $locale]
	text $grid.precips_val -font [dict get $style value2 font] -borderwidth 0\
		 -highlightthickness 0 -wrap none
	grid configure $grid.precips -row $row -column 0 -sticky nw
	grid configure $grid.precips_val -row $row -column 1 -sticky w
}

proc zstatus::metar::setup {bar widget} {
	variable barwidget
	variable metarwidget
	variable metarfont
	variable metarcode

	if ![dict exists $::widgetdict metar station] {
		variable report
		set report(statusbar) "-"
		set report(tooltip) "-"
		return
	}
	set barwidget $bar
	set metarwidget $bar.$widget

	set metarfont [dict get $::widgetdict metar font]
	set metarcode [dict get $::widgetdict metar station]

	variable metar_locales
	variable timezone
	variable locale
	set timezone [dict get $::config timezone]
	set lang [dict get $::config lang]
	set index [lsearch $metar_locales [lindex [split $lang "_"] 0]]
	if {$index < 0} {
		set locale C
	} else {
		set locale [lindex $metar_locales $index]
	}

	dict set ::messagedict metar_toggle {action metar::toggle_popup arg 0}
	dict set ::messagedict metar_update {action metar::update arg 0}

	bind $metarwidget <1> { zstatus::metar::toggle_popup }
	bind $metarwidget <2> { zstatus::metar::update }
	bind $metarwidget <Enter> { zstatus::metar::show_tooltip }
	bind $metarwidget <Leave> { zstatus::metar::hide_tooltip }

	set delay [expr [dict get $::widgetdict metar delay] * 60000]
	after 1000 "every $delay zstatus::metar::update"
}
package provide @PACKAGE_NAME@ @PACKAGE_VERSION@
