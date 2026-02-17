namespace eval zstatus::remixicon {

	set remixmap {
		bar-chart \uea99
		code-s-slash \uebad
		cpu \uebf0
		download \uec5a
		mail \ueef3
		ram \uf456
		upload \uf250
		volume-up \uf2a1
		question-mark \uf046
		cloud-windy \ueba1
		overcast \ueba5
		drizzle \uec68
		foggy \ued50
		hail \ueded
		haze \uee00
		heavy-showers \uee15
		mist \uef5d
		moon-clear \uef6f
		moon-cloudy \uef71
		moon-few-clouds \uef74
		moon \uef75
		rainy \uf056
		showers \uf122
		snowflake \uf513
		snowy \uf15e
		sun-cloudy \uf1bb
		sun-few-clouds \uf1be
		sun-clear \uf1bf
		thunderstorms \uf209
		tornado \uf21c
		windy \uf2ca
	}
	namespace export get
}

proc zstatus::remixicon::get {} {
	variable remixmap
	return $remixmap
}

package provide @PROJECT_NAME@ @PROJECT_VERSION@
