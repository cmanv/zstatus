#include <tcl.h>
extern int FreeBSD_GetLoadAvgObjCmd( ClientData d, Tcl_Interp *i, int c, Tcl_Obj *const o[]);
extern int FreeBSD_GetMemStatsObjCmd( ClientData d, Tcl_Interp *i, int c, Tcl_Obj *const o[]);
extern int FreeBSD_GetArcStatsObjCmd( ClientData d, Tcl_Interp *i, int c, Tcl_Obj *const o[]);
extern int FreeBSD_GetAcpiTempObjCmd( ClientData d, Tcl_Interp *i, int c, Tcl_Obj *const o[]);
extern int FreeBSD_GetCpuTempObjCmd( ClientData d, Tcl_Interp *i, int c, Tcl_Obj *const o[]);
extern int FreeBSD_GetCpuFreqObjCmd( ClientData d, Tcl_Interp *i, int c, Tcl_Obj *const o[]);
extern int FreeBSD_GetNetInObjCmd( ClientData d, Tcl_Interp *i, int c, Tcl_Obj *const o[]);
extern int FreeBSD_GetNetOutObjCmd( ClientData d, Tcl_Interp *i, int c, Tcl_Obj *const o[]);
extern int FreeBSD_GetMixerVolObjCmd( ClientData d, Tcl_Interp *i, int c, Tcl_Obj *const o[]);
