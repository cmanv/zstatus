#include <tcl.h>
#include <X11/Atom.h>
#include <X11/Xlib.h>
int get_text_property(Display, Window, Atom, char *);
void *get_window_property(Display, Window, Atom, Atom , long, unsigned long *);
extern int X11_GetClientInfoObjCmd( ClientData d, Tcl_Interp *i, int c, Tcl_Obj *const o[]);
