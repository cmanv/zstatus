namespace eval zstatus::remixicon {
	set remixmap {
		arrow-down \uea4c
		arrow-up \uea76
		arrow-up-down \uea74
		bar-chart \uea99
		cloud-windy \ueba1
		overcast \ueba5
		code-s-slash \uebad
		cpu \uebf0
		download \uec5a
		drizzle \uec68
		file-copy \uecd5
		foggy \ued50
		fullscreen \ued9c
		hail \ueded
		haze \uee00
		heavy-showers \uee15
		layout \uee7f
		layout-column \uee8d
		layout-grid \uee90
		layout-row \uee9d
		mail \ueef3
		mist \uef5d
		moon-clear \uef6f
		moon-cloudy \uef71
		moon-few-clouds \uef74
		moon \uef75
		music \uef82
		pause \uf506
		play \uf00a
		question-mark \uf046
		ram \uf456
		rainy \uf056
		rectangle \uf3d7
		showers \uf122
		snowflake \uf513
		snowy \uf15e
		stack \uf181
		sun-cloudy \uf1bb
		sun-few-clouds \uf1be
		sun-clear \uf1bf
		thunderstorms \uf209
		tornado \uf21c
		upload \uf250
		volume-up \uf2a1
		windy \uf2ca
	}
	namespace export get
}

proc zstatus::remixicon::get {} {
	variable remixmap
	return $remixmap
}

package provide @PROJECT_NAME@ @PROJECT_VERSION@
