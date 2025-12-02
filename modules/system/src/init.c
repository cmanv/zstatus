#include "config.h"
#include "freebsd.h"

EXTERN int
Freebsd_Init(Tcl_Interp *interp)
{
	Tcl_Namespace *namespace;

	if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL) {
		return TCL_ERROR;
	}

	if (Tcl_PkgRequire(interp, "Tcl", TCL_VERSION, 0) == NULL) {
		return TCL_ERROR;
	}

	if (Tcl_PkgProvide(interp, LIBRARY_PROVIDE, PACKAGE_VERSION) != TCL_OK) {
		return TCL_ERROR;
	}

	namespace = Tcl_CreateNamespace(interp, LIBRARY_PROVIDE, (ClientData)NULL,
					(Tcl_NamespaceDeleteProc *)NULL);

	Tcl_CreateObjCommand(	interp,
				"zstatus::system::freebsd::getloadavg",
				FreeBSD_GetLoadAvgObjCmd,
				(ClientData) NULL,
				(Tcl_CmdDeleteProc*) NULL);

	Tcl_CreateObjCommand(	interp,
				"zstatus::system::freebsd::getpercmemused",
				FreeBSD_GetPercMemUsedObjCmd,
				(ClientData) NULL,
				(Tcl_CmdDeleteProc*) NULL);

	Tcl_CreateObjCommand(	interp,
				"zstatus::system::freebsd::getmemused",
				FreeBSD_GetMemUsedObjCmd,
				(ClientData) NULL,
				(Tcl_CmdDeleteProc*) NULL);

	Tcl_CreateObjCommand(	interp,
				"zstatus::system::freebsd::getswapinfo",
				FreeBSD_GetSwapInfoObjCmd,
				(ClientData) NULL,
				(Tcl_CmdDeleteProc*) NULL);

	Tcl_CreateObjCommand(	interp,
				"zstatus::system::freebsd::getarcstats",
				FreeBSD_GetArcStatsObjCmd,
				(ClientData) NULL,
				(Tcl_CmdDeleteProc*) NULL);

	Tcl_CreateObjCommand(	interp,
				"zstatus::system::freebsd::getacpitemp",
				FreeBSD_GetAcpiTempObjCmd,
				(ClientData) NULL,
				(Tcl_CmdDeleteProc*) NULL);

	Tcl_CreateObjCommand(	interp,
				"zstatus::system::freebsd::getcputemp",
				FreeBSD_GetCpuTempObjCmd,
				(ClientData) NULL,
				(Tcl_CmdDeleteProc*) NULL);

	Tcl_CreateObjCommand(	interp,
				"zstatus::system::freebsd::getcpufreq",
				FreeBSD_GetCpuFreqObjCmd,
				(ClientData) NULL,
				(Tcl_CmdDeleteProc*) NULL);

	Tcl_CreateObjCommand(	interp,
				"zstatus::system::freebsd::getnetstat",
				FreeBSD_GetNetStatObjCmd,
				(ClientData) NULL,
				(Tcl_CmdDeleteProc*) NULL);

	Tcl_CreateObjCommand(	interp,
				"zstatus::system::freebsd::getnetin",
				FreeBSD_GetNetInObjCmd,
				(ClientData) NULL,
				(Tcl_CmdDeleteProc*) NULL);

	Tcl_CreateObjCommand(	interp,
				"zstatus::system::freebsd::getnetout",
				FreeBSD_GetNetOutObjCmd,
				(ClientData) NULL,
				(Tcl_CmdDeleteProc*) NULL);

	Tcl_CreateObjCommand(	interp,
				"zstatus::system::freebsd::getmixervol",
				FreeBSD_GetMixerVolObjCmd,
				(ClientData) NULL,
				(Tcl_CmdDeleteProc*) NULL);

	if (Tcl_Export(interp, namespace, "*", 0) == TCL_ERROR) {
		return TCL_ERROR;
	}

	return TCL_OK;
}
