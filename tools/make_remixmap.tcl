#!/usr/bin/env tclsh9.0
package require fileutil

set iconlist {
	arrow-up-down-line cloud-windy-line\
	cloudy-line code-s-slash-line download-line drizzle-line foggy-line\
	hail-line haze-line heavy-showers-line mail-fill mist-line moon-clear-line\
	moon-cloudy-line moon-foggy-line moon-line music-2-fill\
	pause-large-fill play-fill question-mark rainy-line showers-line\
	snowflake-line snowy-line sun-cloudy-line sun-foggy-line sun-line\
	thunderstorms-line tornado-fill upload-line volume-up-fill }

set file "$::env(HOME)/.local/share/fonts/remixicon.css"

puts "#!/usr/bin/env tclsh9.0"
puts "namespace eval zstatus::remixicon {"
puts "	set remixmap {\\"
foreach icon $iconlist {
	set match [::fileutil::grep ".ri-${icon}.before" $file]
	regexp {\{ content: \"\\([0-9a-f]{4})\"; \}} $match -> unicode 
	regsub {\-line} $icon {} icon
	regsub {\-fill} $icon {} icon
	regsub {\-2} $icon {} icon
	regsub {\-large} $icon {} icon
	regsub {^cloudy$} $icon {overcast} icon
	regsub {\-foggy$} $icon {-few-clouds} icon
	regsub {^sun$} $icon {sun-clear} icon
	puts "		$icon \\u$unicode\\"
}
puts "	}"
puts "	namespace export get\n}\n"
puts "proc zstatus::remixicon::get {} {"
puts "	variable remixmap"
puts "	return \$remixmap\n}\n"
puts "package provide @PACKAGE_NAME@ @PACKAGE_VERSION@"
