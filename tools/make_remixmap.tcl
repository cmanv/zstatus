#!/usr/bin/env tclsh9.0
package require fileutil

set iconlist {
	cloud-windy-line cloudy-line drizzle-line foggy-line hail-line\
	haze-line heavy-showers-line mist-line moon-clear-line\
	moon-cloudy-line moon-foggy-line rainy-line showers-line\
	snowflake-line snowy-line sun-cloudy-line sun-foggy-line\
	sun-line thunderstorms-line tornado-fill windy-line }

set file "$::env(HOME)/.local/share/fonts/remixicon.css"

puts "set weather_icon_map {"
foreach icon $iconlist {
	set match [::fileutil::grep ".ri-${icon}.before" $file]
	regexp {\{ content: \"\\([0-9a-f]{4})\"; \}} $match -> unicode 
	regsub {\-line} $icon {} icon
	regsub {\-fill} $icon {} icon

	regsub {^thunderstorms$} $icon {thunderstorm} icon
	regsub {^foggy$} $icon {fog} icon
	regsub {^snowy$} $icon {snow} icon
	regsub {^rainy$} $icon {rain} icon
	regsub {^cloudy$} $icon {overcast} icon
	regsub {\-foggy$} $icon {-few-clouds} icon
	regsub {^sun} $icon {day} icon
	regsub {^moon} $icon {night} icon
	regsub {^day$} $icon {day-clear} icon
	puts "	$icon \\u$unicode"
}
puts "}"
