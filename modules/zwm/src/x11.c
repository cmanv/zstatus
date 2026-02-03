#include <stdio.h>
#include <string.h>
#include "config.h"
#include "x11.h"

int get_text_property(Display d, Window w, Atom atom, char *text)
{
	XTextProperty	 prop;
	char		**textlist;
	int		 nitems = 0, len;

	XGetTextProperty(d, w, &prop, atom);
	if (!prop.nitems) {
		XFree(prop.value);
		return 0;
	}

	if (Xutf8TextPropertyToTextList(d, &prop, &textlist, &nitems) == Success) {
		if ((nitems == 1) && (*textlist)) {
			len = strlen(*textlist) + 1;
			text = malloc(len);
			strlcpy(text, *textlist, len);
		} else if ((nitems > 1) && (*textlist)) {
			XTextProperty	prop2;
			if (Xutf8TextListToTextProperty(wm::display, textlist, nitems,
			    XUTF8StringStyle, &prop2) == Success) {
				len = strlen((char *)prop2.value) + 1;
				text = malloc(len);
				strlcpy(text, (char *)prop2.value, len);
				XFree(prop2.value);
			}
		}
		if (*textlist) XFreeStringList(textlist);
	}
	XFree(prop.value);

	return nitems;
}

void *get_window_property(Display d, Window w, Atom atom, Atom req_type, long length,
				unsigned long *nitems)
{
	Atom		 actualtype;
	int		 actualformat;
	unsigned long	 bytes_extra;
	unsigned char	*prop;

	if (XGetWindowProperty(d, w, atom, 0L, length, False, req_type,
		&actualtype, &actualformat, nitems, &bytes_extra, &prop) == Success)
	{
		if (actualtype == req_type)
			return (void *)prop;
		XFree(prop);
	}
	return NULL;
}

int X11_GetClientInfoCmd( ClientData clientData, Tcl_Interp *interp,
				int objc, Tcl_Obj *const objv[])
{
	Tcl_Obj	*resultObj = Tcl_GetObjResult(interp);
	char iface[33];
	struct ifaddrs *ifap, *ifa;
	struct if_data *ifd;

	if (objc < 2) {
		Tcl_SetStringObj(resultObj, "getclientinfo: missing id", -1);
		return TCL_ERROR;
	}

	Window winoow;
	Tcl_GetLongFromObj(interp, objv[1], &window)

	Display »display = XOpenDisplay(NULL);

	XClassHint      hint;
	XGetClassHint(display, window, &hint)
	if (Tcl_ListObjAppendElement(interp, resultObj,
		Tcl_NewStringObj(hint.res_name, -1)) != TCL_OK) {
		XFree(hint.res_name);
		return TCL_ERROR;
	}
	XFree(hint.res_name);

	char *name = NULL;
	Atom net_wm_name = XInternAtom(display, "_NET_WM_NAME", False);
	int found = get_text_property(display, window, net_wm_name, name);
	if (!found) {
        	found = get_text_property(displat, window, XA_WM_NAME, name);
		if (!found) {
			name = malloc(4);
			strcpy(name, "???");
	  	}
	}

	if (Tcl_ListObjAppendElement(interp, resultObj, 
		Tcl_NewStringObj(text, -1)) != TCL_OK) {
		if (name) free(name);
		return TCL_ERROR;
	}
	if (name) free(name);

	long     desktop = 0;
	long	*prop;
	Atom net_wm_desktop = XInternAtom(display, "_NET_WM_DESKTOP", False);
	prop = (long *)get_window_property(display, window, net_wm_desktop,
					XA_CARDINAL, 1L, &desktop);

	if (prop) {
		XFree(prop);
	}
	
	if (Tcl_ListObjAppendElement(interp, resultObj,
		Tcl_NewLongObj(desktop)) != TCL_OK) {
		return TCL_ERROR;
	}

	XCloseDisplay(display);
	return TCL_OK;
}
