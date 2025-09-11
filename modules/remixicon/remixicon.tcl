#!/usr/bin/env tclsh9.0
namespace eval zstatus::remixicon {
	set remixmap {\
		arrow-down \uea4c\
		arrow-up \uea76\
		cloud-windy \ueba1\
		overcast \ueba5\
		code-s-slash \uebad\
		download \uec5a\
		drizzle \uec68\
		foggy \ued50\
		hail \ueded\
		haze \uee00\
		heavy-showers \uee15\
		mail \ueef3\
		mist \uef5d\
		moon-clear \uef6f\
		moon-cloudy \uef71\
		moon-few-clouds \uef74\
		moon \uef75\
		music \uef82\
		pause \uf506\
		play \uf00a\
		question-mark \uf046\
		rainy \uf056\
		showers \uf122\
		snowflake \uf513\
		snowy \uf15e\
		sun-cloudy \uf1bb\
		sun-few-clouds \uf1be\
		sun-clear \uf1bf\
		thunderstorms \uf209\
		tornado \uf21c\
		upload \uf250\
		volume-up \uf2a1\
	}
	namespace export get
}

proc zstatus::remixicon::get {} {
	variable remixmap
	return $remixmap
}

package provide @PACKAGE_NAME@ @PACKAGE_VERSION@
