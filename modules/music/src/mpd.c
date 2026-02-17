#include <stdio.h>
#include <string.h>
#include <mpd/connection.h>
#include <mpd/song.h>
#include <mpd/queue.h>
#include <mpd/status.h>
#include "mpd.h"

static const int titlelength = 256;
static char host[65] = "";
static int port = 0;
static int timeout = 0;
static struct mpd_connection *conn = NULL;

int MPD_ConnectObjCmd( ClientData clientData, Tcl_Interp *interp,
				int objc, Tcl_Obj *const objv[])
{
	Tcl_Obj	*resultObj = Tcl_GetObjResult(interp);
	if (objc == 1) {
		Tcl_SetStringObj(resultObj, "[mpd::connect: missing host or socket]", -1);
		return TCL_ERROR;
	}

	strlcpy(host, Tcl_GetString(objv[1]), 64);

	if (objc > 2) {
		if (Tcl_GetIntFromObj(interp, objv[2], &port) != TCL_OK) {
			Tcl_SetStringObj(resultObj, "[mpd::connect: invalid port]", -1);
			return TCL_ERROR;
		}
	}

	if (objc > 3) {
		if (Tcl_GetIntFromObj(interp, objv[3], &timeout) != TCL_OK) {
			Tcl_SetStringObj(resultObj, "[mpd::connect: invalid timeout]", -1);
			return TCL_ERROR;
		}
	}

	if (conn) mpd_connection_free(conn);
	conn = mpd_connection_new(host, port, timeout);
	if (mpd_connection_get_error(conn) != MPD_ERROR_SUCCESS) {
		Tcl_SetStringObj(resultObj, "[mpd::connect: failed to connect]", -1);
		mpd_connection_free(conn);
		conn = NULL;
		return TCL_ERROR;
	}

	return TCL_OK;
}

int MPD_StateObjCmd( ClientData clientData, Tcl_Interp *interp,
				int objc, Tcl_Obj *const objv[])
{
	Tcl_Obj	*resultObj = Tcl_GetObjResult(interp);
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_ObjPrintf("%d", mpd_get_state())) != TCL_OK) {
		return TCL_ERROR;
	}
	return TCL_OK;
}

int mpd_get_state()
{
	if ((!conn) || (mpd_connection_get_error(conn) != MPD_ERROR_SUCCESS)) {
		if (conn) mpd_connection_free(conn);
		conn = mpd_connection_new(host, port, timeout);
		if (!conn) return 0;
		if (mpd_connection_get_error(conn) != MPD_ERROR_SUCCESS) return 0;
	}

	struct mpd_status *status = mpd_run_status(conn);
	if (!status) return 0;

	return mpd_status_get_state(status);
}

int MPD_CurrentTitleObjCmd( ClientData clientData, Tcl_Interp *interp,
				int objc, Tcl_Obj *const objv[])
{
	Tcl_Obj	*resultObj = Tcl_GetObjResult(interp);

	char currenttitle[titlelength];
	bzero(currenttitle, titlelength);

	if ((!conn) || (mpd_connection_get_error(conn) != MPD_ERROR_SUCCESS)) {
		if (conn) mpd_connection_free(conn);
		conn = mpd_connection_new(host, port, timeout);
		if (!conn) return 1;
		if (mpd_connection_get_error(conn) != MPD_ERROR_SUCCESS) return 1;
	}

	struct mpd_status *status = mpd_run_status(conn);
	if (!status) return 1;

	enum mpd_state s = mpd_status_get_state(status);
	if ((s != MPD_STATE_PLAY) && (s != MPD_STATE_PAUSE)) {
		mpd_status_free(status);
		return 0;
	}

	int id = mpd_status_get_song_id(status);
	if (id <0) {
		mpd_status_free(status);
		return 0;
	}

	char artist[64];
	char album[64];
	char title[110];

	bzero(artist, 64);
	bzero(album, 64);
	bzero(title, 110);

	struct mpd_song *song = mpd_run_get_queue_song_id(conn, id);
	if (song) {
		const char *partist = mpd_song_get_tag(song, MPD_TAG_ARTIST, 0);
		const char *palbum = mpd_song_get_tag(song, MPD_TAG_ALBUM, 0);
		const char *ptitle = mpd_song_get_tag(song, MPD_TAG_TITLE, 0);

		if (partist) strlcpy(artist, partist, 64);
		if (palbum) strlcpy(album, palbum, 64);
		if (ptitle) strlcpy(title, ptitle, 110);
		mpd_song_free(song);
	}
	mpd_status_free(status);

	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(artist, -1)) != TCL_OK) {
		return TCL_ERROR;
	}
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(album, -1)) != TCL_OK) {
		return TCL_ERROR;
	}
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(title, -1)) != TCL_OK) {
		return TCL_ERROR;
	}

	int pos = mpd_status_get_song_pos(status);
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_ObjPrintf("%d", pos+1)) != TCL_OK) {
		return TCL_ERROR;
	}

	unsigned length = mpd_status_get_queue_length(status);
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_ObjPrintf("%u", length)) != TCL_OK) {
		return TCL_ERROR;
	}

	unsigned elapsed = mpd_status_get_elapsed_time(status);
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_ObjPrintf("%um %02us", elapsed/60, elapsed%60)) != TCL_OK) {
		return TCL_ERROR;
	}

	unsigned total = mpd_status_get_total_time(status);
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_ObjPrintf("%um:%02us", total/60, total%60)) != TCL_OK) {
		return TCL_ERROR;
	}

	return TCL_OK;
}
