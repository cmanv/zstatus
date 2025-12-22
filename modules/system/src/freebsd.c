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
int add_mem_value(char *, Tcl_Interp *, Tcl_Obj *);

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

int FreeBSD_GetPercMemUsedObjCmd( ClientData clientData, Tcl_Interp *interp,
				int objc, Tcl_Obj *const objv[])
{
	Tcl_Obj	*resultObj = Tcl_GetObjResult(interp);

	/* Get total amount of memory */
	long total = 0;
	size_t size = sizeof(long);
	int err = sysctlbyname("vm.stats.vm.v_page_count", &total, &size, (void *)NULL, (size_t)0);
	if (err < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}

	/* Get amount of unused memory */
	long unused = 0;
	err = sysctlbyname("vm.stats.vm.v_free_count", &unused, &size, (void *)NULL, (size_t)0);
	if (err < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}

	/* Percent used = (total - unused) / total */
	double memperc = (double)(total - unused)*100.0/(double)total;

	/* Returns used memory */
	char mem_perc[11];
	snprintf(mem_perc, 10, "%.1f%%", memperc);
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(mem_perc, -1)) != TCL_OK) {
		return TCL_ERROR;
	}

	return TCL_OK;
}

int FreeBSD_GetMemUsedObjCmd( ClientData clientData, Tcl_Interp *interp,
				int objc, Tcl_Obj *const objv[])
{
	Tcl_Obj	*resultObj = Tcl_GetObjResult(interp);

	/* Get total amount of memory */
	long pages = 0;
	size_t size = sizeof(long);
	int err = sysctlbyname("vm.stats.vm.v_page_count", &pages, &size, (void *)NULL, (size_t)0);
	if (err < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}
	double total = pages>>8;

	/* Get amount of unused memory */
	err = sysctlbyname("vm.stats.vm.v_free_count", &pages, &size, (void *)NULL, (size_t)0);
	if (err < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}
	double unused = pages>>8;

	/* Percent used = (total - unused) / total */
	double usedmem = total - unused;

	// Total memory
	char unit[3];
	strcpy(unit, "Mi");
	if (total >= 1024) { total /= 1024; strcpy(unit, "Gi"); }

	char fmt[8];
	strcpy(fmt, "%.0f %s");
	if (total < 100) strcpy(fmt, "%.1f %s");
	if (total < 10) strcpy(fmt, "%.2f %s");

	char string[16];
	snprintf(string, 15, fmt, total, unit);
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(string, -1)) != TCL_OK) {
		return TCL_ERROR;
	}

	// Used memory
	strcpy(unit, "Mi");
	if (usedmem >= 1024) { usedmem /= 1024; strcpy(unit, "Gi"); }

	strcpy(fmt, "%.0f %s");
	if (usedmem < 100) strcpy(fmt, "%.1f %s");
	if (usedmem < 10) strcpy(fmt, "%.2f %s");

	snprintf(string, 15, fmt, usedmem, unit);
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(string, -1)) != TCL_OK) {
		return TCL_ERROR;
	}

	// Unused memory
	strcpy(unit, "Mi");
	if (unused >= 1024) { unused /= 1024; strcpy(unit, "Gi"); }

	strcpy(fmt, "%.0f %s");
	if (unused < 100) strcpy(fmt, "%.1f %s");
	if (unused < 10) strcpy(fmt, "%.2f %s");

	snprintf(string, 15, fmt, unused, unit);
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(string, -1)) != TCL_OK) {
		return TCL_ERROR;
	}

	return TCL_OK;
}

int FreeBSD_GetSwapInfoObjCmd( ClientData clientData, Tcl_Interp *interp,
				int objc, Tcl_Obj *const objv[])
{
	Tcl_Obj	*resultObj = Tcl_GetObjResult(interp);

	/* Get amount of swap in use */
	struct xswdev xsw;
	int mib[16];
	size_t mibsize = sizeof mib / sizeof mib[0];
	if (sysctlnametomib("vm.swap_info", mib, &mibsize) == -1) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}

	double total = 0;
	double used = 0;
	for (int n=0; ; ++n) {
		mib[mibsize] = n;
		size_t size = sizeof xsw;
		if (sysctl(mib, mibsize + 1, &xsw, &size, NULL, 0) == -1) break;
		total += (double)(xsw.xsw_nblks >> 8);
		used += (double)(xsw.xsw_used >> 8);
	}
	double free = total - used;

	char unit[3];
	strcpy(unit, "Mi");
	if (total>=1024) { total /= 1024; strcpy(unit, "Gi"); }

	char fmt[8];
	strcpy(fmt, "%.0f %s");
	if (total < 100) strcpy(fmt, "%.1f %s");
	if (total < 10) strcpy(fmt, "%.2f %s");

	char string[16];
	bzero(string, 16);
	snprintf(string, 16, fmt, total, unit);
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(string, -1)) != TCL_OK) {
		return TCL_ERROR;
	}

	strcpy(unit, "Mi");
	if (used>=1024) { used /= 1024; strcpy(unit, "Gi"); }

	strcpy(fmt, "%.0f %s");
	if (used < 100) strcpy(fmt, "%.1f %s");
	if (used < 10) strcpy(fmt, "%.2f %s");

	bzero(string, 16);
	snprintf(string, 16, fmt, used, unit);
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(string, -1)) != TCL_OK) {
		return TCL_ERROR;
	}

	strcpy(unit, "Mi");
	if (free>=1024) { free /= 1024; strcpy(unit, "Gi"); }

	strcpy(fmt, "%.0f %s");
	if (free < 100) strcpy(fmt, "%.1f %s");
	if (free < 10) strcpy(fmt, "%.2f %s");

	bzero(string, 16);
	snprintf(string, 16, fmt, free, unit);
	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(string, -1)) != TCL_OK) {
		return TCL_ERROR;
	}

	return TCL_OK;
}

int FreeBSD_GetArcStatsObjCmd( ClientData clientData, Tcl_Interp *interp,
				int objc, Tcl_Obj *const objv[])
{
	Tcl_Obj	*resultObj = Tcl_GetObjResult(interp);

	long long value = 0;
	size_t size = sizeof(long);
	int err = sysctlbyname("vfs.zfs.arc.max", &value, &size,
				(void *)NULL, (size_t)0);
	if (err < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}
	double arcmax = (double)(value>>20);

	err = sysctlbyname("kstat.zfs.misc.arcstats.size", &value, &size,
				(void *)NULL, (size_t)0);
	if (err < 0) {
		Tcl_SetStringObj(resultObj, Tcl_PosixError(interp), -1);
		return TCL_ERROR;
	}
	double arcsize = (double)(value>>20);
	double arcfree = arcmax - arcsize;

	// ARC MAX
	char unit[3];
	strcpy(unit, "Mi");
	if (arcmax>=1024) { arcmax /= 1024; strcpy(unit, "Gi"); }

	char fmt[8];
	strcpy(fmt, "%.0f %s");
	if (arcmax < 100) strcpy(fmt, "%.1f %s");
	if (arcmax < 10) strcpy(fmt, "%.2f %s");

	/* Returns a string containing ARC max size */
	char string[16];
	snprintf(string, 16, fmt, arcmax, unit);

	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(string, -1)) != TCL_OK) {
		return TCL_ERROR;
	}

	// ARC Used
	strcpy(unit, "Mi");
	if (arcsize>=1024) { arcsize /= 1024; strcpy(unit, "Gi"); }

	strcpy(fmt, "%.0f %s");
	if (arcsize < 100) strcpy(fmt, "%.1f %s");
	if (arcsize < 10) strcpy(fmt, "%.2f %s");

	/* Returns a string containing ARC used size */
	snprintf(string, 16, fmt, arcsize, unit);

	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(string, -1)) != TCL_OK) {
		return TCL_ERROR;
	}

	// ARC unused
	strcpy(unit, "Mi");
	if (arcfree>=1024) { arcfree /= 1024; strcpy(unit, "Gi"); }

	strcpy(fmt, "%.0f %s");
	if (arcfree < 100) strcpy(fmt, "%.1f %s");
	if (arcfree < 10) strcpy(fmt, "%.2f %s");

	/* Returns a string containing ARC unused size */
	snprintf(string, 16, fmt, arcfree, unit);

	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(string, -1)) != TCL_OK) {
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

	char ipv4[INET_ADDRSTRLEN+1], ipv6[INET6_ADDRSTRLEN+1];
	double inbound = 0;
	double outbound = 0;
	strcpy(ipv4, "n/a");
	strcpy(ipv6, "n/a");

	for (ifa = ifap; ifa; ifa = ifa->ifa_next) {
		if (strcmp(ifa->ifa_name, iface)) continue;
		struct sockaddr_in *addr_in = (struct sockaddr_in *)ifa->ifa_addr;
		if (addr_in->sin_family == AF_LINK) {
			ifd = (struct if_data *)ifa->ifa_data;
			inbound = (double)(ifd->ifi_ibytes>>10);
			outbound = (double)(ifd->ifi_obytes>>10);
			continue;
		}
		if (addr_in->sin_family == AF_INET) {
			inet_ntop(AF_INET, &(addr_in->sin_addr), ipv4, INET_ADDRSTRLEN);
			continue;
		}
		if (addr_in->sin_family == AF_INET6) {
			inet_ntop(AF_INET6, &(addr_in->sin_addr), ipv6, INET6_ADDRSTRLEN);
		}
	}
	freeifaddrs(ifap);

	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(ipv4, -1)) != TCL_OK) {
		return TCL_ERROR;
	}

	if (Tcl_ListObjAppendElement(interp, resultObj, Tcl_NewStringObj(ipv6, -1)) != TCL_OK) {
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
