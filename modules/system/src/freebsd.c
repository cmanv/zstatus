#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/soundcard.h>
#include <sys/sysctl.h>
#include <vm/vm_param.h>
#include <unistd.h>
#include <net/if.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <ifaddrs.h>
#include "config.h"
#include "freebsd.h"

int FreeBSD_GetLoadAvgObjCmd( ClientData clientData, Tcl_Interp *interp,
				int objc, Tcl_Obj *const objv[])
{
	Tcl_Obj	*resultObj = Tcl_GetObjResult(interp);
	double loadavg;

	if (getloadavg(&loadavg, 1) < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}

	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_ObjPrintf("%.2f", loadavg)) != TCL_OK) {
		return TCL_ERROR;
	}

	return TCL_OK;
}

int FreeBSD_GetMemStatsObjCmd( ClientData clientData, Tcl_Interp *interp,
				int objc, Tcl_Obj *const objv[])
{
	Tcl_Obj	*resultObj = Tcl_GetObjResult(interp);

	/* Get amount of active memory */
	long active = 0;
	size_t size = sizeof(long);
	int err = sysctlbyname("vm.stats.vm.v_active_count", &active, &size, (void *)NULL, (size_t)0);
	if (err < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}

	/* Get amount of wired memory */
	long wired = 0;
	err = sysctlbyname("vm.stats.vm.v_wire_count", &wired, &size, (void *)NULL, (size_t)0);
	if (err < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}

	/* Used nemory = active + wired */
	double memused = (double)((active + wired)>>8);

	char mem_unit[3];
	strcpy(mem_unit, "Mi");
	if (memused>=1024) { memused /= 1024; strcpy(mem_unit, "Gi"); }

	char mem_fmt[8];
	strcpy(mem_fmt, "%.0f %s");
	if (memused < 100) strcpy(mem_fmt, "%.1f %s");
	if (memused < 10) strcpy(mem_fmt, "%.2f %s");

	/* Returns used memory */
	char vmemused[16];
	snprintf(vmemused, 16, mem_fmt, memused, mem_unit);
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(vmemused, -1)) != TCL_OK) {
		return TCL_ERROR;
	}

	/* Get amount of swap in use */
	struct xswdev xsw;
	int mib[16];
	size_t mibsize = sizeof mib / sizeof mib[0];
	if (sysctlnametomib("vm.swap_info", mib, &mibsize) == -1) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}

	double swapused = 0;
	for (int n=0; ; ++n) {
		mib[mibsize] = n;
		size = sizeof xsw;
		if (sysctl(mib, mibsize + 1, &xsw, &size, NULL, 0) == -1) break;
		swapused += (double)(xsw.xsw_used >> 8);
	}

	char swap_unit[3];
	strcpy(swap_unit, "Mi");
	if (swapused>=1024) { swapused /= 1024; strcpy(swap_unit, "Gi"); }

	char swap_fmt[8];
	strcpy(swap_fmt, "%.0f %s");
	if (swapused < 100) strcpy(swap_fmt, "%.1f %s");
	if (swapused < 10) strcpy(swap_fmt, "%.2f %s");

	/* Returns swap */
	char vswapused[16];
	bzero(vswapused, 16);
	if (swapused > 0)
		snprintf(vswapused, 16, swap_fmt, swapused, swap_unit);
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(vswapused, -1)) != TCL_OK) {
		return TCL_ERROR;
	}

	return TCL_OK;
}

int FreeBSD_GetArcStatsObjCmd( ClientData clientData, Tcl_Interp *interp,
				int objc, Tcl_Obj *const objv[])
{
	Tcl_Obj	*resultObj = Tcl_GetObjResult(interp);

	long long mfu = 0, mru = 0, anon = 0, header = 0, other = 0;
	size_t size = sizeof(long);
	int err = sysctlbyname("kstat.zfs.misc.arcstats.mfu_size", &mfu, &size,
				(void *)NULL, (size_t)0);
	if (err < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}

	err = sysctlbyname("kstat.zfs.misc.arcstats.mru_size", &mru, &size,
				(void *)NULL, (size_t)0);
	if (err < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}

	err = sysctlbyname("kstat.zfs.misc.arcstats.anon_size", &anon, &size,
				(void *)NULL, (size_t)0);
	if (err < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}

	err = sysctlbyname("kstat.zfs.misc.arcstats.hdr_size", &header, &size,
				(void *)NULL, (size_t)0);
	if (err < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}

	err = sysctlbyname("kstat.zfs.misc.arcstats.other_size", &other, &size,
				(void *)NULL, (size_t)0);
	if (err < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}

	double arcsize = (double)((mfu + mru + anon + header + other)>>20);
	double mfusize = (double)(mfu>>20);
	double mrusize = (double)(mru>>20);

	char arc_unit[3];
	strcpy(arc_unit, "Mi");
	if (arcsize>=1024) { arcsize /= 1024; strcpy(arc_unit, "Gi"); }

	char arc_fmt[8];
	strcpy(arc_fmt, "%.0f %s");
	if (arcsize < 100) strcpy(arc_fmt, "%.1f %s");
	if (arcsize < 10) strcpy(arc_fmt, "%.2f %s");

	/* Returns a string containing ARC size */
	char varcsize[16];
	snprintf(varcsize, 16, arc_fmt, arcsize, arc_unit);

	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(varcsize, -1)) != TCL_OK) {
		return TCL_ERROR;
	}

	char mfu_unit[3];
	strcpy(mfu_unit, "Mi");
	if (mfusize>=1024) { mfusize /= 1024; strcpy(mfu_unit, "Gi"); }

	char mfu_fmt[8];
	strcpy(mfu_fmt, "%.0f %s");
	if (mfusize < 100) strcpy(mfu_fmt, "%.1f %s");
	if (mfusize < 10) strcpy(mfu_fmt, "%.2f %s");

	/* Returns a string containing ARC size */
	char vmfusize[16];
	snprintf(vmfusize, 16, mfu_fmt, mfusize, mfu_unit);

	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(vmfusize, -1)) != TCL_OK) {
		return TCL_ERROR;
	}

	char mru_unit[3];
	strcpy(mru_unit, "Mi");
	if (mrusize>=1024) { mrusize /= 1024; strcpy(mru_unit, "Gi"); }

	char mru_fmt[8];
	strcpy(mru_fmt, "%.0f %s");
	if (mrusize < 100) strcpy(mru_fmt, "%.1f %s");
	if (mrusize < 10) strcpy(mru_fmt, "%.2f %s");

	/* Returns a string containing ARC size */
	char vmrusize[16];
	snprintf(vmrusize, 16, mru_fmt, mrusize, mru_unit);

	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(vmrusize, -1)) != TCL_OK) {
		return TCL_ERROR;
	}

	return TCL_OK;
}

int FreeBSD_GetAcpiTempObjCmd( ClientData clientData, Tcl_Interp *interp,
				int objc, Tcl_Obj *const objv[])
{
	Tcl_Obj	*resultObj = Tcl_GetObjResult(interp);
	int temp;
	size_t size = sizeof(int);

	int err = sysctlbyname("hw.acpi.thermal.tz0.temperature", &temp, &size,
				(void *)NULL, (size_t)0);
	if (err < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}

	double tcelcius = (double)(temp - 2731)/10;
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_ObjPrintf("%.f°C", tcelcius)) != TCL_OK) {
		return TCL_ERROR;
	}
	return TCL_OK;
}

int FreeBSD_GetCpuTempObjCmd( ClientData clientData, Tcl_Interp *interp,
				int objc, Tcl_Obj *const objv[])
{
	Tcl_Obj	*resultObj = Tcl_GetObjResult(interp);
	int temp;
	size_t size = sizeof(int);

	int err = sysctlbyname("dev.cpu.0.temperature", &temp, &size,
				(void *)NULL, (size_t)0);
	if (err < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}

	double tcelcius = (double)(temp - 2731)/10;
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_ObjPrintf("%.f°C", tcelcius)) != TCL_OK) {
		return TCL_ERROR;
	}
	return TCL_OK;
}

int FreeBSD_GetCpuFreqObjCmd( ClientData clientData, Tcl_Interp *interp,
				int objc, Tcl_Obj *const objv[])
{
	Tcl_Obj	*resultObj = Tcl_GetObjResult(interp);
	int freq;
	size_t size = sizeof(int);

	int err = sysctlbyname("dev.cpu.0.freq", &freq, &size,
				(void *)NULL, (size_t)0);
	if (err < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}

	double fmhz = (double)(freq)/1000;
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_ObjPrintf("%.1f Mhz", fmhz)) != TCL_OK) {
		return TCL_ERROR;
	}
	return TCL_OK;
}

int FreeBSD_GetNetStatObjCmd( ClientData clientData, Tcl_Interp *interp,
				int objc, Tcl_Obj *const objv[])
{
	Tcl_Obj	*resultObj = Tcl_GetObjResult(interp);
	char iface[33];
	struct ifaddrs *ifap, *ifa;
	struct if_data *ifd;

	if (objc < 2) {
		Tcl_SetStringObj(resultObj, "getnetin: missing interface", -1);
		return TCL_ERROR;
	}

	strlcpy(iface, Tcl_GetString(objv[1]), 32);

	if (getifaddrs(&ifap) < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}

	char ipaddr[17];
	strcpy(ipaddr, "N/A");
	double inbound = 0;
	double outbound = 0;
	for (ifa = ifap; ifa; ifa = ifa->ifa_next) {
		if (strcmp(ifa->ifa_name, iface)) continue;
		if (ifa->ifa_addr->sa_family == AF_LINK) {
			ifd = (struct if_data *)ifa->ifa_data;
			inbound = (double)(ifd->ifi_ibytes>>10);
			outbound = (double)(ifd->ifi_obytes>>10);
			continue;
		}
		if (ifa->ifa_addr->sa_family != AF_INET) continue;
		struct sockaddr_in *addr_in = (struct sockaddr_in *)ifa->ifa_addr;
		strlcpy(ipaddr, inet_ntoa(addr_in->sin_addr), 16);
	}
	freeifaddrs(ifap);

	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(ipaddr, -1)) != TCL_OK) {
		return TCL_ERROR;
	}

	char iunit[3];
	strcpy(iunit, "Ki");
	if (inbound>=1024) { inbound /= 1024; strcpy(iunit, "Mi"); }
	if (inbound>=1024) { inbound /= 1024; strcpy(iunit, "Gi"); }

	char ifmt[8];
	strcpy(ifmt, "%.0f %s");
	if (inbound < 100) strcpy(ifmt, "%.1f %s");
	if (inbound < 10) strcpy(ifmt, "%.2f %s");

	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_ObjPrintf(ifmt, inbound, iunit)) != TCL_OK) {
		return TCL_ERROR;
	}

	char ounit[3];
	strcpy(ounit, "Ki");
	if (outbound>=1024) { outbound /= 1024; strcpy(ounit, "Mi"); }
	if (outbound>=1024) { outbound /= 1024; strcpy(ounit, "Gi"); }

	char ofmt[8];
	strcpy(ofmt, "%.0f %s");
	if (outbound < 100) strcpy(ofmt, "%.1f %s");
	if (outbound < 10) strcpy(ofmt, "%.2f %s");

	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_ObjPrintf(ifmt, outbound, ounit)) != TCL_OK) {
		return TCL_ERROR;
	}
	return TCL_OK;
}

int FreeBSD_GetNetOutObjCmd( ClientData clientData, Tcl_Interp *interp,
				int objc, Tcl_Obj *const objv[])
{
	Tcl_Obj	*resultObj = Tcl_GetObjResult(interp);
	char iface[33];
	struct ifaddrs *ifap, *ifa;
	struct if_data *ifd;

	if (objc < 2) {
		Tcl_SetStringObj(resultObj, "getnetout: missing interface", -1);
		return TCL_ERROR;
	}

	strlcpy(iface, Tcl_GetString(objv[1]), 32);

	if (getifaddrs(&ifap) < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}

	double outbound = 0;
	for (ifa = ifap; ifa; ifa = ifa->ifa_next) {
		if (strcmp(ifa->ifa_name, iface)) continue;
		ifd = (struct if_data *)ifa->ifa_data;
		outbound = (double)(ifd->ifi_obytes>>10);
		break;
	}
	freeifaddrs(ifap);

	char ounit[3];
	strcpy(ounit, "Ki");
	if (outbound>=1024) { outbound /= 1024; strcpy(ounit, "Mi"); }
	if (outbound>=1024) { outbound /= 1024; strcpy(ounit, "Gi"); }

	char ofmt[8];
	strcpy(ofmt, "%.0f %s");
	if (outbound < 100) strcpy(ofmt, "%.1f %s");
	if (outbound < 10) strcpy(ofmt, "%.2f %s");

	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_ObjPrintf(ofmt, outbound, ounit)) != TCL_OK) {
		return TCL_ERROR;
	}
	return TCL_OK;
}

int FreeBSD_GetNetInObjCmd( ClientData clientData, Tcl_Interp *interp,
				int objc, Tcl_Obj *const objv[])
{
	Tcl_Obj	*resultObj = Tcl_GetObjResult(interp);
	char iface[33];
	struct ifaddrs *ifap, *ifa;
	struct if_data *ifd;

	if (objc < 2) {
		Tcl_SetStringObj(resultObj, "getnetin: missing interface", -1);
		return TCL_ERROR;
	}

	strlcpy(iface, Tcl_GetString(objv[1]), 32);

	if (getifaddrs(&ifap) < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}

	double inbound = 0;
	for (ifa = ifap; ifa; ifa = ifa->ifa_next) {
		if (strcmp(ifa->ifa_name, iface)) continue;
		ifd = (struct if_data *)ifa->ifa_data;
		inbound = (double)(ifd->ifi_ibytes>>10);
		break;
	}
	freeifaddrs(ifap);

	char iunit[3];
	strcpy(iunit, "Ki");
	if (inbound>=1024) { inbound /= 1024; strcpy(iunit, "Mi"); }
	if (inbound>=1024) { inbound /= 1024; strcpy(iunit, "Gi"); }

	char ifmt[8];
	strcpy(ifmt, "%.0f %s");
	if (inbound < 100) strcpy(ifmt, "%.1f %s");
	if (inbound < 10) strcpy(ifmt, "%.2f %s");

	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_ObjPrintf(ifmt, inbound, iunit)) != TCL_OK) {
		return TCL_ERROR;
	}
	return TCL_OK;
}

int FreeBSD_GetMixerVolObjCmd( ClientData clientData, Tcl_Interp *interp,
				int objc, Tcl_Obj *const objv[])
{
	Tcl_Obj	*resultObj = Tcl_GetObjResult(interp);
	int value;
	int device = 0;

	int fd = open("/dev/mixer", O_RDONLY);
	if (fd < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}
	ioctl(fd, MIXER_READ(device), &value);
	close(fd);

	int vol = value & 0x7f;
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_ObjPrintf("%d%%", vol)) != TCL_OK) {
		return TCL_ERROR;
	}
	return TCL_OK;
}
