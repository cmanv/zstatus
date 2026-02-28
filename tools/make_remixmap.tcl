#!/usr/bin/env tclsh9.0
package require fileutil

set iconlist {
	cloud-windy-line cloudy-line drizzle-line foggy-line hail-line haze-line\
	heavy-showers-line rectangle-line layout-2-line layout-column-line\
	layout-grid-line layout-row-line mail-fill mist-line moon-clear-line\
	moon-cloudy-line moon-foggy-line ram-line rainy-line showers-line\
	snowflake-line snowy-line sun-cloudy-line sun-foggy-line sun-line\
	thunderstorms-line tornado-fill windy-line window-line }

set file "$::env(HOME)/.local/share/fonts/remixicon.css"

puts "	set pua_map {"
foreach icon $iconlist {
	set match [::fileutil::grep ".ri-${icon}.before" $file]
	regexp {\{ content: \"\\([0-9a-f]{4})\"; \}} $match -> unicode 
	regsub {\-line} $icon {} icon
	regsub {\-fill} $icon {} icon
	regsub {\-2} $icon {} icon
	regsub {\-large} $icon {} icon

	regsub {^layout-column$} $icon {vsplit} icon
	regsub {^layout-row$} $icon {hsplit} icon
	regsub {^layout-grid$} $icon {grid} icon
	regsub {^layout$} $icon {vsplit2} icon
	regsub {^rectangle$} $icon {maximize} icon
	regsub {^thunderstorms$} $icon {thunderstorm} icon
	regsub {^foggy$} $icon {fog} icon
	regsub {^snowy$} $icon {snow} icon
	regsub {^rainy$} $icon {rain} icon
	regsub {^cloudy$} $icon {overcast} icon
	regsub {\-foggy$} $icon {-few-clouds} icon
	regsub {^sun} $icon {day} icon
	regsub {^moon} $icon {night} icon
	regsub {^day$} $icon {day-clear} icon
	puts "		$icon \\u$unicode"
}
puts "	}"
