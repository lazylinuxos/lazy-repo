# This hook removes the wordsize specific libdir symlink.

hook() {
	if [ "${pkgname}" != "lazy-base-files" ]; then
		rm -f ${PKGDESTDIR}/usr/lib${XBPS_TARGET_WORDSIZE}
	fi
}
