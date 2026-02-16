namespace eval zstatus::symbols {
	set symbols {
		question-mark	\ueb32
		fog		\ue313
		hail		\ue314
		mist		\ue35d
		dust		\ue35d
		haze		\ue3ae
		smoke		\ue35c
		drizzle		\ue3ad
		tornado		\ue351
		sandstorm	\ue37a
		snow		\ue31a
		thunderstorm	\ue31d
		light-rain	\ue319
		rain		\ue318
		showers		\uef1d
		windy		\ue31e
		cloudy-windy	\ue311
		overcast	\ue312
		cloud		\ue33d
		day-clear	\ue30d
		day-cloudy1 	\ue30c
		day-cloudy2	\ue302
		night-clear	\uf186
		night-cloudy1	\ue379
		night-cloudy2	\ue37e
		sunrise		\ue34c
		sunset		\ue34d
		arrow-down	\uf063
		arrow-up	\uf062
		download 	\uf019
		upload 		\uf093
		mail		\uf42f
		volume		\uf028
		play 		\uf04b
		pause 		\uf04c
		music 		\uf001
		code-slash	\uf121
		cpu		\uf4bc
		memory		\Uefc5
		usb		\uf287
		graph		\Uf0128
		floating	\uf4bb
		hsplit		\uebf2
		vsplit		\uebf4
		maximize	\Uf01be
		maximiz2	\uf06f
		terminal	\uea85
		chrome		\uf268
		emacs		\ue632 
		firefox		\ue745
	}
	namespace export get
}

proc zstatus::symbols::get {} {
	variable symbols
	return $symbols
}

package provide @PROJECT_NAME@ @PROJECT_VERSION@
