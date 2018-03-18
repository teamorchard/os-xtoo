# Copyright 2016-2018 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

# Based on eclass from gentoo main tree
# Copyright 2004-2015 Gentoo Foundation

# @ECLASS: java-utils-2.eclass
# @MAINTAINER:
# William L. Thomson Jr. <wlt@o-sinc.com>
# @AUTHOR:
# Thomas Matthijs <axxo@gentoo.org>, Karl Trygve Kalleberg <karltk@gentoo.org>
# @BLURB: Base eclass for Java packages
# @DESCRIPTION:
# This eclass provides functionality which is used by java-pkg-2.eclass,
# java-pkg-opt-2.eclass and java-pkg-simple eclass, as well as from ebuilds.
#
# This eclass should not be inherited this directly from an ebuild. Instead,
# you should inherit java-pkg-2 for Java packages or java-pkg-opt-2 for packages
# that have optional Java support. In addition you can inherit
# java-pkg-simple for all other packages.
inherit eutils versionator multilib

IUSE="elibc_FreeBSD"

# @VARIABLE: JAVA_PKG_E_DEPEND
# @INTERNAL
# @DESCRIPTION:
# This is a convience variable to be used from the other java eclasses. This is
# the version of jem we want to use. Usually the latest stable version
# so that ebuilds can use new features without depending on specific versions.
JAVA_PKG_E_DEPEND="dev-java/jem"
has source ${JAVA_PKG_IUSE} && \
	JAVA_PKG_E_DEPEND="${JAVA_PKG_E_DEPEND} source? ( app-arch/zip )"

# @ECLASS-VARIABLE: JAVA_PKG_ALLOW_VM_CHANGE
# @DESCRIPTION:
# Allow this eclass to change the active VM?
# If your system VM isn't sufficient for the package, the build will fail
# instead of trying to switch to another VM.
#
# Overriding the default can be useful for testing specific VMs locally, but
# should not be used in the final ebuild.
JAVA_PKG_ALLOW_VM_CHANGE=${JAVA_PKG_ALLOW_VM_CHANGE:="yes"}

# @ECLASS-VARIABLE: JAVA_PKG_FORCE_VM
# @DEFAULT_UNSET
# @DESCRIPTION:
# Explicitly set a particular VM to use. If its not valid, it'll fall back to
# whatever /etc/jem/build/jdk.conf would elect to use.
#
# Should only be used for testing and debugging.
#
# Example: use oracle-jdk-bin-9 to emerge foo:
# @CODE
#	JAVA_PKG_FORCE_VM=oracle-jdk-bin-9 emerge foo
# @CODE

# @ECLASS-VARIABLE: JAVA_PKG_WANT_BUILD_VM
# @DEFAULT_UNSET
# @DESCRIPTION:
# A list of VM handles to choose a build VM from. If the list contains the
# currently active VM use that one, otherwise step through the list till a
# usable/installed VM is found.
#
# This allows to use an explicit list of JDKs in DEPEND instead of a virtual.
# Users of this variable must make sure at least one of the listed handles is
# covered by DEPEND.
# Requires JAVA_RELEASE to be set as well.

# @ECLASS-VARIABLE: JAVA_RELEASE
# @DEFAULT_UNSET
# @DESCRIPTION:
# Specify a non-standard Java release version for compilation
# (via javac --release parameter).
# Normally this is determined from the jdk version specified in DEPEND.
# See java-pkg_get-release function below.
#
# Should generally only be used for testing and debugging.
#
# Use release 7 to emerge baz
# @CODE
#	JAVA_RELEASE=7 emerge baz
# @CODE

# @ECLASS-VARIABLE: JAVA_PKG_DEBUG
# @DEFAULT_UNSET
# @DESCRIPTION:
# A variable to be set with "yes" or "y", or ANY string of length non equal to
# zero. When set, verbosity across java eclasses is increased and extra
# logging is displayed.
# @CODE
#	JAVA_PKG_DEBUG="yes"
# @CODE

# @ECLASS-VARIABLE: JAVA_RM_FILES
# @DEFAULT_UNSET
# @DESCRIPTION:
# An array containing a list of files to remove. If defined, this array will be
# automatically handed over to _java-pkg_rm_files for processing during the
# src_prepare phase.
#
# @CODE
#	JAVA_RM_FILES=(
#		path/to/File1.java
#		DELETEME.txt
#	)
# @CODE

# @VARIABLE: JAVA_PKG_COMPILER_DIR
# @INTERNAL
# @DESCRIPTION:
# Directory where compiler settings are saved, without trailing slash.
# You probably shouldn't touch this variable except local testing.
JAVA_PKG_COMPILER_DIR=${JAVA_PKG_COMPILER_DIR:="/etc/jem/compiler"}

# @VARIABLE: JAVA_PKG_COMPILERS_CONF
# @INTERNAL
# @DESCRIPTION:
# Path to file containing information about which compiler to use.
# Can be overloaded, but it should be overloaded only for local testing.
JAVA_PKG_COMPILERS_CONF=${JAVA_PKG_COMPILERS_CONF:="/etc/jem/build/compilers.conf"}

# @ECLASS-VARIABLE: JAVA_PKG_FORCE_COMPILER
# @INTERNAL
# @DEFAULT_UNSET
# @DESCRIPTION:
# Explicitly set a list of compilers to choose from. This is normally read from
# JAVA_PKG_COMPILERS_CONF.
#
# Useful for local testing.
#
# Use ecj and javac, in that order
# @CODE
#	JAVA_PKG_FORCE_COMPILER="ecj javac"
# @CODE

# @FUNCTION: java-pkg_doexamples
# @USAGE: [--subdir <subdir>] <file1/dir1> [<file2> ...]
# @DESCRIPTION:
# Installs given arguments to /usr/share/doc/${PF}/examples
# If you give it only one parameter and it is a directory it will install
# everything in that directory to the examples directory.
#
# @CODE
# Parameters:
# --subdir - If the examples need a certain directory structure
# $* - list of files to install
#
# Examples:
#	java-pkg_doexamples demo
#	java-pkg_doexamples demo/* examples/*
# @CODE
java-pkg_doexamples() {
	debug-print-function ${FUNCNAME} $*

	[[ ${#} -lt 1 ]] && die "At least one argument needed"

	java-pkg_check-phase install
	java-pkg_init_paths_

	local dest=/usr/share/doc/${PF}/examples
	if [[ ${1} == --subdir ]]; then
		local dest=${dest}/${2}
		dodir ${dest}
		shift 2
	fi

	if [[ ${#} = 1 && -d ${1} ]]; then
		( # dont want to pollute calling env
			insinto "${dest}"
			doins -r ${1}/*
		) || die "Installing examples failed"
	else
		( # dont want to pollute calling env
			insinto "${dest}"
			doins -r "$@"
		) || die "Installing examples failed"
	fi

	# Let's make a symlink to the directory we have everything else under
	dosym "${dest}" "${JAVA_PKG_SHAREPATH}/examples" || die
}

# @FUNCTION: _java-pkg_rm_files
# @USAGE: _java-pkg_rm_files File1.java File2.java ...
# @DESCRIPTION:
# Remove unneeded files in ${S}. Should not be called directly! Instead
# set and use JAVA_RM_FILES variable to any files that need to be removed.
#
# @CODE
#	_java-pkg_rm_files File1.java File2.java
# @CODE
#
# @param $* - list of files to remove.
_java-pkg_rm_files() {
	local IFS f

	debug-print-function ${FUNCNAME} $*

	IFS="\n"
	for f in "$@"; do
		rm -r "${S}/${f}" || die "cannot remove ${f}"
	done
}

# @FUNCTION: java-pkg_dojar
# @USAGE: <jar1> [<jar2> ...]
# @DESCRIPTION:
# Installs any number of jars.
# Jar's will be installed into /usr/share/${PN}(-${SLOT})/lib/ by default.
# You can use java-pkg_jarinto to change this path.
# You should never install a jar with a package version in the filename.
# Instead, use java-pkg_newjar defined below.
#
# @CODE
#	java-pkg_dojar dist/${PN}.jar dist/${PN}-core.jar
# @CODE
#
# @param $* - list of jars to install
java-pkg_dojar() {
	debug-print-function ${FUNCNAME} $*

	[[ ${#} -lt 1 ]] && die "At least one argument needed"

	java-pkg_check-phase install
	java-pkg_init_paths_

	# Create JARDEST if it doesn't exist
	dodir ${JAVA_PKG_JARDEST}

	local jar
	# for each jar
	for jar in "${@}"; do
		local jar_basename=$(basename "${jar}")

		java-pkg_check-versioned-jar ${jar_basename}

		# check if it exists
		if [[ -e "${jar}" ]] ; then
			# Don't overwrite if jar has already been installed with the same
			# name
			local dest="${D}${JAVA_PKG_JARDEST}/${jar_basename}"
			if [[ -e "${dest}" ]]; then
				ewarn "Overwriting ${dest}"
			fi

			# install it into JARDEST if it's a non-symlink
			if [[ ! -L "${jar}" ]] ; then
				#but first check class version when in strict mode.
#				is-java-strict && java-pkg_verify-classes "${jar}"

				(
					insinto "${JAVA_PKG_JARDEST}"
					doins "${jar}"
				) || die "failed to install ${jar}"
				java-pkg_append_ JAVA_PKG_CLASSPATH "${JAVA_PKG_JARDEST}/${jar_basename}"
				debug-print "installed ${jar} to ${D}${JAVA_PKG_JARDEST}"
			# make a symlink to the original jar if it's symlink
			else
				# TODO use dosym, once we find something that could use it
				# -nichoj
				ln -s "$(readlink "${jar}")" "${D}${JAVA_PKG_JARDEST}/${jar_basename}"
				debug-print "${jar} is a symlink, linking accordingly"
			fi
		else
			die "${jar} does not exist"
		fi
	done

	# Extra logging if enabled.
	if [[ -n ${JAVA_PKG_DEBUG} ]]; then
		einfo "Verbose logging for \"${FUNCNAME}\" function"
		einfo "Jar file(s) destination: ${JAVA_PKG_JARDEST}"
		einfo "Jar file(s) created: ${@}"
		einfo "Complete command:"
		einfo "${FUNCNAME} ${@}"
	fi

	java-pkg_do_write_
}

# @FUNCTION: java-pkg_regjar
# @USAGE: </path/to/installed/jar>
# @DESCRIPTION:
# Records an already installed (in ${D}) jar in the package.env
# This would mostly be used if the package has make or a custom script to
# install things.
#
# WARNING:
# if you want to use shell expansion, you have to use ${D}/... as the for in
# this function will not be able to expand the path, here's an example:
#
# @CODE
#   java-pkg_regjar ${D}/opt/my-java/lib/*.jar
# @CODE
#

# TODO should we be making sure the jar is present on ${D} or wherever?
java-pkg_regjar() {
	debug-print-function ${FUNCNAME} $*

	java-pkg_check-phase install

	[[ ${#} -lt 1 ]] && die "at least one argument needed"

	java-pkg_init_paths_

	local jar jar_dir jar_file
	for jar in "${@}"; do
		# TODO use java-pkg_check-versioned-jar
		if [[ -e "${jar}" || -e "${D}${jar}" ]]; then
			[[ -d "${jar}" || -d "${D}${jar}" ]] \
				&& die "Called ${FUNCNAME} on a	directory $*"

			#check that class version correct when in strict mode
#			is-java-strict && java-pkg_verify-classes "${jar}"

			# nelchael: we should strip ${D} in this case too, here's why:
			# imagine such call:
			#    java-pkg_regjar ${D}/opt/java/*.jar
			# such call will fall into this case (-e ${jar}) and will
			# record paths with ${D} in package.env
			java-pkg_append_ JAVA_PKG_CLASSPATH	"${jar#${D}}"
		else
			if [[ ${jar} = *\** ]]; then
				eerror "The argument ${jar} to ${FUNCNAME}"
				eerror "has * in it. If you want it to glob in"
				eerror '${D} add ${D} to the argument.'
			fi
			debug-print "${jar} or ${D}${jar} not found"
			die "${jar} does not exist"
		fi
	done

	java-pkg_do_write_
}

# @FUNCTION: java-pkg_newjar
# @USAGE: <path/to/oldname.jar> [<newname.jar>]
# @DESCRIPTION:
# Installs a jar with a new name (defaults to $PN.jar)
#
# For example, installs a versioned jar without the version
java-pkg_newjar() {
	debug-print-function ${FUNCNAME} $*

	local original_jar="${1}"
	local new_jar="${2:-${PN}.jar}"
	local new_jar_dest="${T}/${new_jar}"

	[[ -z ${original_jar} ]] && die "Must specify a jar to install"
	[[ ! -f ${original_jar} ]] \
		&& die "${original_jar} does not exist or is not a file!"

	rm -f "${new_jar_dest}" || die "Failed to remove ${new_jar_dest}"
	cp "${original_jar}" "${new_jar_dest}" \
		|| die "Failed to copy ${original_jar} to ${new_jar_dest}"
	java-pkg_dojar "${new_jar_dest}"
}

# @FUNCTION: java-pkg_addcp
# @USAGE: <classpath>
# @DESCRIPTION:
# Add something to the package's classpath. For jars, you should use dojar,
# newjar, or regjar. This is typically used to add directories to the classpath.
# The parameters of this function are appended to JAVA_PKG_CLASSPATH
java-pkg_addcp() {
	java-pkg_append_ JAVA_PKG_CLASSPATH "${@}"
	java-pkg_do_write_
}

# @FUNCTION: java-pkg_doso
# @USAGE: <path/to/file1.so> [...]
# @DESCRIPTION:
# Installs any number of JNI libraries
# They will be installed into /usr/lib by default, but java-pkg_sointo
# can be used change this path
#
# @CODE
# Example:
#	java-pkg_doso *.so
# @CODE
java-pkg_doso() {
	debug-print-function ${FUNCNAME} $*

	java-pkg_check-phase install

	[[ ${#} -lt 1 ]] && die "${FUNCNAME} requires at least one argument"

	java-pkg_init_paths_

	local lib
	# for each lib
	for lib in "$@" ; do
		# if the lib exists...
		if [[ -e "${lib}" ]] ; then
			# install if it isn't a symlink
			if [[ ! -L "${lib}" ]] ; then
				(
					insinto "${JAVA_PKG_LIBDEST}"
					insopts -m0755
					doins "${lib}"
				) || die "failed to install ${lib}"
				java-pkg_append_ JAVA_PKG_LIBRARY "${JAVA_PKG_LIBDEST}"
				debug-print "Installing ${lib} to ${JAVA_PKG_LIBDEST}"
			# otherwise make a symlink to the symlink's origin
			else
				dosym "$(readlink "${lib}")" "${JAVA_PKG_LIBDEST}/${lib##*/}"
				debug-print "${lib} is a symlink, linking accordantly"
			fi
		# otherwise die
		else
			die "${lib} does not exist"
		fi
	done

	java-pkg_do_write_
}

# @FUNCTION: java-pkg_regso
# @USAGE: <file1.so> [...]
# @DESCRIPTION:
# Registers an already installed JNI library in package.env.
#
# @CODE
# Parameters:
# $@ - JNI libraries to register
#
# Example:
#	java-pkg_regso *.so /path/*.so
# @CODE
java-pkg_regso() {
	debug-print-function ${FUNCNAME} $*

	java-pkg_check-phase install

	[[ ${#} -lt 1 ]] && die "${FUNCNAME} requires at least one argument"

	java-pkg_init_paths_

	local lib target_dir
	for lib in "$@" ; do
		# Check the absolute path of the lib
		if [[ -e "${lib}" ]] ; then
			target_dir="$(java-pkg_expand_dir_ ${lib})"
			java-pkg_append_ JAVA_PKG_LIBRARY "/${target_dir#${D}}"
		# Check the path of the lib relative to ${D}
		elif [[ -e "${D}${lib}" ]]; then
			target_dir="$(java-pkg_expand_dir_ ${D}${lib})"
			java-pkg_append_ JAVA_PKG_LIBRARY "${target_dir}"
		else
			die "${lib} does not exist"
		fi
	done

	java-pkg_do_write_
}

# @FUNCTION: java-pkg_jarinto
# @USAGE: </path/to/install/jars/into>
# @DESCRIPTION:
# Changes the path jars are installed into via subsequent java-pkg_dojar calls.
java-pkg_jarinto() {
	debug-print-function ${FUNCNAME} $*

	JAVA_PKG_JARDEST="${1}"
}

# @FUNCTION: java-pkg_sointo
# @USAGE: </path/to/install/sofiles/into>
# @DESCRIPTION:
# Changes the path that JNI libraries are installed into via subsequent
# java-pkg_doso calls.
java-pkg_sointo() {
	debug-print-function ${FUNCNAME} $*

	JAVA_PKG_LIBDEST="${1}"
}

# @FUNCTION: java-pkg_dohtml
# @USAGE: <path/to/javadoc/documentation> [...]
# @DESCRIPTION:
# Install Javadoc HTML documentation. Usage of java-pkg_dojavadoc is preferred.
#
# @CODE
#	java-pkg_dohtml dist/docs/
# @CODE
java-pkg_dohtml() {
	debug-print-function ${FUNCNAME} $*

	[[ ${#} -lt 1 ]] &&  die "At least one argument required for ${FUNCNAME}"

	# from /usr/lib/portage/bin/dohtml -h
	#  -f   Set list of allowed extensionless file names.
	dohtml -f package-list "$@"

	# this probably shouldn't be here but it provides
	# a reasonable way to catch # docs for all of the
	# old ebuilds.
	java-pkg_recordjavadoc
}

# @FUNCTION: java-pkg_dojavadoc
# @USAGE: [--symlink destination] <path/to/javadocs/root>
# @DESCRIPTION:
# Installs javadoc documentation. This should be controlled by the doc use flag.
#
# @CODE
# Parameters:
# $1: optional --symlink creates to symlink like this for html
#            documentation bundles.
# $2: - The javadoc root directory.
#
# Examples:
#	java-pkg_dojavadoc docs/api
#	java-pkg_dojavadoc --symlink apidocs docs/api
# @CODE
java-pkg_dojavadoc() {
	debug-print-function ${FUNCNAME} $*

	# For html documentation bundles that link to Javadoc
	local symlink
	if [[ ${1} = --symlink ]]; then
		symlink=${2}
		shift 2
	fi

	local dir="$1"
	local dest=/usr/share/doc/${PF}/html

	# QA checks

	java-pkg_check-phase install
	java-pkg_init_paths_

	[[ -z "${dir}" ]] && die "Must specify a directory!"
	[[ ! -d "${dir}" ]] && die "${dir} does not exist, or isn't a directory!"
	if [[ ! -e "${dir}/index.html" ]]; then
		local msg="No index.html in javadoc directory"
		ewarn "${msg}"
		is-java-strict && die "${msg}"
	fi

	if [[ -e ${D}/${dest}/api ]]; then
		eerror "${dest} already exists. Will not overwrite."
		die "${dest}"
	fi

	# Renaming to match our directory layout

	local dir_to_install="${dir}"
	if [[ "$(basename "${dir}")" != "api" ]]; then
		dir_to_install="${T}/api"
		# TODO use doins
		cp -r "${dir}" "${dir_to_install}" || die "cp failed"
	fi

	# Actual installation
	java-pkg_dohtml -r "${dir_to_install}"

	# Let's make a symlink to the directory we have everything else under
	dosym ${dest}/api "${JAVA_PKG_SHAREPATH}/api" || die

	if [[ ${symlink} ]]; then
		debug-print "symlinking ${dest}/{api,${symlink}}"
		dosym ${dest}/{api,${symlink}} || die
	fi

	# Extra logging if enabled.
	if [[ -n ${JAVA_PKG_DEBUG} ]]; then
		einfo "Verbose logging for \"${FUNCNAME}\" function"
		einfo "Documentation destination: ${dest}"
		einfo "Directory to install: ${dir_to_install}"
		einfo "Complete command:"
		einfo "${FUNCNAME} ${@}"
	fi
}

# @FUNCTION: java-pkg_dosrc
# @USAGE: <path/to/sources> [...]
# @DESCRIPTION:
# Installs a zip containing the source for a package, so it can used in
# from IDEs like eclipse and netbeans.
# Ebuild needs to DEPEND on app-arch/zip to use this. It also should be controlled by USE=source.
#
# @CODE
# Example:
# java-pkg_dosrc src/*
# @CODE

# TODO change so it the arguments it takes are the base directories containing
# source -nichoj
#
# TODO should we be able to handle multiple calls to dosrc? -nichoj
#
# TODO maybe we can take an existing zip/jar? -nichoj
#
# FIXME apparently this fails if you give it an empty directories
java-pkg_dosrc() {
	debug-print-function ${FUNCNAME} $*

	[ ${#} -lt 1 ] && die "At least one argument needed"

	java-pkg_check-phase install

	[[ ${#} -lt 1 ]] && die "At least one argument needed"

	if ! [[ ${DEPEND} = *app-arch/zip* ]]; then
		local msg="${FUNCNAME} called without app-arch/zip in DEPEND"
		java-pkg_announce-qa-violation ${msg}
	fi

	java-pkg_init_paths_

	local zip_name="${PN}-src.zip"
	local zip_path="${T}/${zip_name}"
	local dir
	for dir in "${@}"; do
		local dir_parent=$(dirname "${dir}")
		local dir_name=$(basename "${dir}")
		pushd ${dir_parent} > /dev/null || die "problem entering ${dir_parent}"
		zip -q -r ${zip_path} ${dir_name} -i '*.java'
		local result=$?
		# 12 means zip has nothing to do
		if [[ ${result} != 12 && ${result} != 0 ]]; then
			die "failed to zip ${dir_name}"
		fi
		popd >/dev/null || die
	done

	# Install the zip
	(
		insinto "${JAVA_PKG_SOURCESPATH}"
		doins ${zip_path}
	) || die "Failed to install source"

	JAVA_SOURCES="${JAVA_PKG_SOURCESPATH}/${zip_name}"

	# Extra logging if enabled.
	if [[ -n ${JAVA_PKG_DEBUG} ]]; then
		einfo "Verbose logging for \"${FUNCNAME}\" function"
		einfo "Zip filename created: ${zip_name}"
		einfo "Zip file destination: ${JAVA_PKG_SOURCESPATH}"
		einfo "Directories zipped: ${@}"
		einfo "Complete command:"
		einfo "${FUNCNAME} ${@}"
	fi

	java-pkg_do_write_
}

# @FUNCTION: java-pkg_dolauncher
# @USAGE: <filename> [options]
# @DESCRIPTION:
# Make a wrapper script to lauch/start this package
# If necessary, the wrapper will switch to the appropriate VM.
#
# Can be called without parameters if the package installs only one jar
# that has the Main-class attribute set. The wrapper will be named ${PN}.
#
# @CODE
# Parameters:
# $1 - filename of launcher to create
# $2 - options, as follows:
#  --main the.main.class.to.start
#  --jar /the/jar/too/launch.jar or just <name>.jar
#  --java_args 'Extra arguments to pass to java'
#  --pkg_args 'Extra arguments to pass to the package'
#  --pwd Directory the launcher changes to before executing java
#  -into Directory to install the launcher to, instead of /usr/bin
#  -pre Prepend contents of this file to the launcher
# @CODE
java-pkg_dolauncher() {
	debug-print-function ${FUNCNAME} $*

	java-pkg_check-phase install
	java-pkg_init_paths_

	if [[ ${#} = 0 ]]; then
		local name="${PN}"
	else
		local name="${1}"
		shift
	fi

	# TODO rename to launcher
	local target="${T}/${name}"
	local var_tmp="${T}/launcher_variables_tmp"
	local target_dir pre

	# Process the other the rest of the arguments
	while [[ -n "${1}" && -n "${2}" ]]; do
		local var="${1}" value="${2}"
		if [[ "${var:0:2}" == "--" ]]; then
			local var=${var:2}
			echo "gjl_${var}=\"${value}\"" >> "${var_tmp}"
			local gjl_${var}="${value}"
		elif [[ "${var}" == "-into" ]]; then
			target_dir="${value}"
		elif [[ "${var}" == "-pre" ]]; then
			pre="${value}"
		fi
		shift 2
	done

	# Test if no --jar and --main arguments were given and
	# in that case check if the package only installs one jar
	# and use that jar.
	if [[ -z "${gjl_jar}" && -z "${gjl_main}" ]]; then
		local cp="${JAVA_PKG_CLASSPATH}"
		if [[ "${cp/:}" = "${cp}" && "${cp%.jar}" != "${cp}" ]]; then
			echo "gjl_jar=\"${JAVA_PKG_CLASSPATH}\"" >> "${var_tmp}"
		else
			local msg="Not enough information to create a launcher given."
			msg="${msg} Please give --jar or --main argument to ${FUNCNAME}."
			die "${msg}"
		fi
	fi

	# Write the actual script
	echo "#!/bin/bash" > "${target}"
	if [[ -n "${pre}" ]]; then
		if [[ -f "${pre}" ]]; then
			cat "${pre}" >> "${target}"
		else
			die "-pre specified file '${pre}' does not exist"
		fi
	fi
	echo "gjl_package=${JAVA_PKG_NAME}" >> "${target}"
	cat "${var_tmp}" >> "${target}"
	rm -f "${var_tmp}"
	echo "source /usr/share/java-config-2/launcher/launcher.bash" >> "${target}"

	if [[ -n "${target_dir}" ]]; then
		(
			into "${target_dir}"
			dobin "${target}"
		)
		local ret=$?
		return ${ret}
	else
		dobin "${target}"
	fi
}

# @FUNCTION: java-pkg_dowar
# @DESCRIPTION:
# Install war files.
# TODO document
java-pkg_dowar() {
	debug-print-function ${FUNCNAME} $*

	# Check for arguments
	[[ ${#} -lt 1 ]] && die "At least one argument needed"
	java-pkg_check-phase install

	java-pkg_init_paths_

	local war
	for war in $* ; do
		local warpath
		# TODO evaluate if we want to handle symlinks differently -nichoj
		# Check for symlink
		if [[ -L "${war}" ]] ; then
			cp "${war}" "${T}"
			warpath="${T}$(basename "${war}")"
		# Check for directory
		# TODO evaluate if we want to handle directories differently -nichoj
		elif [[ -d "${war}" ]] ; then
			echo "dowar: warning, skipping directory ${war}"
			continue
		else
			warpath="${war}"
		fi

		# Install those files like you mean it
		(
			insopts -m0644
			insinto "${JAVA_PKG_WARDEST}"
			doins ${warpath}
		)
	done
}

# @FUNCTION: java-pkg_recordjavadoc
# @INTERNAL
# @DESCRIPTION:
# Scan for JavaDocs, and record their existence in the package.env file

# TODO make sure this in the proper section
java-pkg_recordjavadoc()
{
	debug-print-function ${FUNCNAME} $*
	# the find statement is important
	# as some packages include multiple trees of javadoc
	JAVADOC_PATH="$(find ${D}/usr/share/doc/ -name allclasses-frame.html -printf '%h:')"
	# remove $D - TODO: check this is ok with all cases of the above
	JAVADOC_PATH="${JAVADOC_PATH//${D}}"
	if [[ -n "${JAVADOC_PATH}" ]] ; then
		debug-print "javadocs found in ${JAVADOC_PATH%:}"
		java-pkg_do_write_
	else
		debug-print "No javadocs found"
	fi
}


# @FUNCTION: java-pkg_jar-from
# @USAGE: [--build-only] [--with-dependencies] [--virtual] [--into dir] <package> [<package.jar>] [<destination.jar>]
# @DESCRIPTION:
# Makes a symlink to a jar from a certain package
# A lot of java packages include dependencies in a lib/ directory
# You can use this function to replace these bundled dependencies.
# The dependency is recorded into package.env DEPEND line, unless "--build-only"
# is passed as the very first argument, for jars that have to be present only
# at build time and are not needed on runtime (junit testing etc).
#
# @CODE
# Example: get all jars from xerces slot 2
#	java-pkg_jar-from xerces-2
#
# Example: get a specific jar from xerces slot 2
# 	java-pkg_jar-from xerces-2 xml-apis.jar
#
# Example: get a specific jar from xerces slot 2, and name it diffrently
# 	java-pkg_jar-from xerces-2 xml-apis.jar xml.jar
#
# Example: get junit.jar which is needed only for building
#	java-pkg_jar-from --build-only junit junit.jar
# @CODE
#
# @CODE
# Parameters
#	--build-only - makes the jar(s) not added into package.env DEPEND line.
#	  (assumed automatically when called inside src_test)
#	--with-dependencies - get jars also from requested package's dependencies
#	  transitively.
#	--virtual - Packages passed to this function are to be handled as virtuals
#	  and will not have individual jar dependencies recorded.
#	--into $dir - symlink jar(s) into $dir (must exist) instead of .
# $1 - Package to get jars from, or comma-separated list of packages in
#	case other parameters are not used.
# $2 - jar from package. If not specified, all jars will be used.
# $3 - When a single jar is specified, destination filename of the
#	symlink. Defaults to the name of the jar.
# @CODE

# TODO could probably be cleaned up a little
java-pkg_jar-from() {
	debug-print-function ${FUNCNAME} $*

	local build_only=""
	local destdir="."
	local deep=""
	local virtual=""
	local record_jar=""

	[[ "${EBUILD_PHASE}" == "test" ]] && build_only="build"

	while [[ "${1}" == --* ]]; do
		if [[ "${1}" = "--build-only" ]]; then
			build_only="build"
		elif [[ "${1}" = "--with-dependencies" ]]; then
			deep="--with-dependencies"
		elif [[ "${1}" = "--virtual" ]]; then
			virtual="true"
		elif [[ "${1}" = "--into" ]]; then
			destdir="${2}"
			shift
		else
			die "java-pkg_jar-from called with unknown parameter: ${1}"
		fi
		shift
	done

	local target_pkg="${1}" target_jar="${2}" destjar="${3}"

	[[ -z ${target_pkg} ]] && die "Must specify a package"

	# default destjar to the target jar
	[[ -z "${destjar}" ]] && destjar="${target_jar}"

	local error_msg="There was a problem getting the classpath for ${target_pkg}."
	local classpath
	classpath="$(jem ${deep} --classpath=${target_pkg})"
	[[ $? != 0 ]] && die ${error_msg}

	# When we have commas this functions is called to bring jars from multiple
	# packages. This affects recording of dependencencies performed later
	# which expects one package only, so we do it here.
	if [[ ${target_pkg} = *,* ]]; then
		for pkg in ${target_pkg//,/ }; do
			java-pkg_ensure-dep "${build_only}" "${pkg}"
			[[ -z "${build_only}" ]] && java-pkg_record-jar_ "${pkg}"
		done
		# setting this disables further record-jar_ calls later
		record_jar="true"
	else
		java-pkg_ensure-dep "${build_only}" "${target_pkg}"
	fi

	# Record the entire virtual as a dependency so that
	# no jars are missed.
	if [[ -z "${build_only}" && -n "${virtual}" ]]; then
		java-pkg_record-jar_ "${target_pkg}"
		# setting this disables further record-jars_ calls later
		record_jar="true"
	fi

	pushd ${destdir} > /dev/null \
		|| die "failed to change directory to ${destdir}"

	local jar
	for jar in ${classpath//:/ }; do
		local jar_name=$(basename "${jar}")
		if [[ ! -f "${jar}" ]] ; then
			debug-print "${jar} from ${target_pkg} does not exist"
			die "Installation problems with jars in ${target_pkg} - is it installed?"
		fi
		# If no specific target jar was indicated, link it
		if [[ -z "${target_jar}" ]] ; then
			[[ -f "${target_jar}" ]]  && rm "${target_jar}"
			ln -snf "${jar}" \
				|| die "Failed to make symlink from ${jar} to ${jar_name}"
			if [[ -z "${record_jar}" ]]; then
				if [[ -z "${build_only}" ]]; then
					java-pkg_record-jar_ "${target_pkg}" "${jar}"
				else
					java-pkg_record-jar_ --build-only "${target_pkg}" "${jar}"
				fi
			fi
		# otherwise, if the current jar is the target jar, link it
		elif [[ "${jar_name}" == "${target_jar}" ]] ; then
			[[ -f "${destjar}" ]]  && rm "${destjar}"
			ln -snf "${jar}" "${destjar}" \
				|| die "Failed to make symlink from ${jar} to ${destjar}"
			if [[ -z "${record_jar}" ]]; then
				if [[ -z "${build_only}" ]]; then
					java-pkg_record-jar_ "${target_pkg}" "${jar}"
				else
					java-pkg_record-jar_ --build-only "${target_pkg}" "${jar}"
				fi
			fi
			popd > /dev/null || die
			return 0
		fi
	done
	popd > /dev/null || die
	# if no target was specified, we're ok
	if [[ -z "${target_jar}" ]] ; then
		return 0
	# otherwise, die bitterly
	else
		die "Failed to find ${target_jar:-jar} in ${target_pkg}"
	fi
}

# @FUNCTION: java-pkg_jarfrom
# @DESCRIPTION:
# See java-pkg_jar-from
java-pkg_jarfrom() {
	java-pkg_jar-from "$@"
}

# @FUNCTION: java-pkg_getjars
# @USAGE: [--build-only] [--with-dependencies] <package1>[,<package2>...]
# @DESCRIPTION:
# Get the classpath provided by any number of packages
# Among other things, this can be passed to 'javac -classpath' or 'ant -lib'.
# The providing packages are recorded as dependencies into package.env DEPEND
# line, unless "--build-only" is passed as the very first argument, for jars
# that have to be present only at build time and are not needed on runtime
# (junit testing etc).
#
# @CODE
# Example: Get the classpath for xerces-2 and xalan,
#	java-pkg_getjars xerces-2,xalan
#
# Example Return:
#	/usr/share/xerces-2/lib/xml-apis.jar:/usr/share/xerces-2/lib/xmlParserAPIs.jar:/usr/share/xalan/lib/xalan.jar
#
#
# Parameters:
#	--build-only - makes the jar(s) not added into package.env DEPEND line.
#	  (assumed automatically when called inside src_test)
#	--with-dependencies - get jars also from requested package's dependencies
#	  transitively.
# $1 - list of packages to get jars from
#   (passed to jem --classpath)
# @CODE
java-pkg_getjars() {
	debug-print-function ${FUNCNAME} $*

	local build_only=""
	local deep=""

	[[ "${EBUILD_PHASE}" == "test" ]] && build_only="build"

	while [[ "${1}" == --* ]]; do
		if [[ "${1}" = "--build-only" ]]; then
			build_only="build"
		elif [[ "${1}" = "--with-dependencies" ]]; then
			deep="--with-dependencies"
		else
			die "java-pkg_jar-from called with unknown parameter: ${1}"
		fi
		shift
	done

	[[ ${#} -ne 1 ]] && die "${FUNCNAME} takes only one argument besides --*"


	local pkgs="${1}"

	jars="$(jem ${deep} --classpath=${pkgs})"
	[[ $? != 0 ]] && die "jem --classpath=${pkgs} failed"
	debug-print "${pkgs}:${jars}"

	for pkg in ${pkgs//,/ }; do
		java-pkg_ensure-dep "${build_only}" "${pkg}"
	done

	for pkg in ${pkgs//,/ }; do
		if [[ -z "${build_only}" ]]; then
			java-pkg_record-jar_ "${pkg}"
		else
			java-pkg_record-jar_ --build-only "${pkg}"
		fi
	done

	echo "${jars}"
}

# @FUNCTION: java-pkg_getjar
# @USAGE: [--build-only] [--virtual] <package> <jarfile>
# @DESCRIPTION:
# Get the complete path of a single jar from a package
# The providing package is recorded as runtime dependency into package.env
# DEPEND line, unless "--build-only" is passed as the very first argument, for
# jars that have to be present only at build time and are not needed on runtime
# (junit testing etc).
#
# @CODE
# Example:
#	java-pkg_getjar xerces-2 xml-apis.jar
# returns
#	/usr/share/xerces-2/lib/xml-apis.jar
#
# Parameters:
#	--build-only - makes the jar not added into package.env DEPEND line.
#	--virtual - Packages passed to this function are to be handled as virtuals
#	  and will not have individual jar dependencies recorded.
# $1 - package to use
# $2 - jar to get
# @CODE
java-pkg_getjar() {
	debug-print-function ${FUNCNAME} $*

	local build_only=""
	local virtual=""
	local record_jar=""

	[[ "${EBUILD_PHASE}" == "test" ]] && build_only="build"

	while [[ "${1}" == --* ]]; do
		if [[ "${1}" = "--build-only" ]]; then
			build_only="build"
		elif [[ "${1}" == "--virtual" ]]; then
			virtual="true"
		else
			die "java-pkg_getjar called with unknown parameter: ${1}"
		fi
		shift
	done

	[[ ${#} -ne 2 ]] && die "${FUNCNAME} takes only two arguments besides --*"

	local pkg="${1}" target_jar="${2}" jar

	[[ -z ${pkg} ]] && die "Must specify package to get a jar from"
	[[ -z ${target_jar} ]] && die "Must specify jar to get"

	local error_msg="Could not find classpath for ${pkg}. Are you sure its installed?"
	local classpath
	classpath=$(jem --classpath=${pkg})
	[[ $? != 0 ]] && die ${error_msg}

	java-pkg_ensure-dep "${build_only}" "${pkg}"

	# Record the package(Virtual) as a dependency and then set build_only
	# So that individual jars are not recorded.
	if [[ -n "${virtual}" ]]; then
		if [[ -z "${build_only}" ]]; then
			java-pkg_record-jar_ "${pkg}"
		else
			java-pkg_record-jar_ --build-only "${pkg}"
		fi
		record_jar="true"
	fi

	for jar in ${classpath//:/ }; do
		if [[ ! -f "${jar}" ]] ; then
			die "Installation problem with jar ${jar} in ${pkg} - is it installed?"
		fi

		if [[ "$(basename ${jar})" == "${target_jar}" ]] ; then
			# Only record jars that aren't build-only
			if [[ -z "${record_jar}" ]]; then
				if [[ -z "${build_only}" ]]; then
					java-pkg_record-jar_ "${pkg}" "${jar}"
				else
					java-pkg_record-jar_ --build-only "${pkg}" "${jar}"
				fi
			fi
			echo "${jar}"
			return 0
		fi
	done

	die "Could not find ${target_jar} in ${pkg}"
	return 1
}

# @FUNCTION: java-pkg_register-dependency
# @USAGE: <package>[,<package2>...] [<jarfile>]
# @DESCRIPTION:
# Registers runtime dependency on a package, list of packages, or a single jar
# from a package, into package.env DEPEND line. Can only be called in
# src_install phase.
# Intended for binary packages where you don't need to symlink the jars or get
# their classpath during build. As such, the dependencies only need to be
# specified in ebuild's RDEPEND, and should be omitted in DEPEND.
#
# @CODE
# Parameters:
# $1 - comma-separated list of packages, or a single package
# $2 - if param $1 is a single package, optionally specify the jar
#   to depend on
#
# Examples:
# Record the dependency on whole xerces-2 and xalan,
#	java-pkg_register-dependency xerces-2,xalan
#
# Record the dependency on ant.jar from ant-core
#	java-pkg_register-dependency ant-core ant.jar
# @CODE
#
# Note: Passing both list of packages as the first parameter AND specifying the
# jar as the second is not allowed and will cause the function to die. We assume
# that there's more chance one passes such combination as a mistake, than that
# there are more packages providing identically named jar without class
# collisions.
java-pkg_register-dependency() {
	debug-print-function ${FUNCNAME} $*

	java-pkg_check-phase install

	[[ ${#} -gt 2 ]] && die "${FUNCNAME} takes at most two arguments"

	local pkgs="${1}"
	local jar="${2}"

	[[ -z "${pkgs}" ]] && die "${FUNCNAME} called with no package(s) specified"

	if [[ -z "${jar}" ]]; then
		for pkg in ${pkgs//,/ }; do
			java-pkg_ensure-dep runtime "${pkg}"
			java-pkg_record-jar_ "${pkg}"
		done
	else
		[[ ${pkgs} == *,* ]] && \
			die "${FUNCNAME} called with both package list and jar name"
		java-pkg_ensure-dep runtime "${pkgs}"
		java-pkg_record-jar_ "${pkgs}" "${jar}"
	fi

	java-pkg_do_write_
}

# @FUNCTION: java-pkg_register-optional-dependency
# @USAGE: <package>[,<package2>...] [<jarfile>]
# @DESCRIPTION:
# Registers optional runtime dependency on a package, list of packages, or a
# single jar from a package, into package.env OPTIONAL_DEPEND line. Can only be
# called in src_install phase.
# Intended for packages that can use other packages when those are in classpath.
# Will be put on classpath by launcher if they are installed. Typical case is
# JDBC implementations for various databases. It's better than having USE flag
# for each implementation triggering hard dependency.
#
# @CODE
# Parameters:
# $1 - comma-separated list of packages, or a single package
# $2 - if param $1 is a single package, optionally specify the jar to depend on
#
# Example:
# Record the optional dependency on some jdbc providers
#	java-pkg_register-optional-dependency jdbc-jaybird,jtds-1.2,jdbc-mysql
# @CODE
#
# Note: Passing both list of packages as the first parameter AND specifying the
# jar as the second is not allowed and will cause the function to die. We assume
# that there's more chance one passes such combination as a mistake, than that
# there are more packages providing identically named jar without class
# collisions.
java-pkg_register-optional-dependency() {
	debug-print-function ${FUNCNAME} $*

	java-pkg_check-phase install

	[[ ${#} -gt 2 ]] && die "${FUNCNAME} takes at most two arguments"

	local pkgs="${1}"
	local jar="${2}"

	[[ -z "${pkgs}" ]] && die "${FUNCNAME} called with no package(s) specified"

	if [[ -z "${jar}" ]]; then
		for pkg in ${pkgs//,/ }; do
			java-pkg_record-jar_ --optional "${pkg}"
		done
	else
		[[ ${pkgs} == *,* ]] && \
			die "${FUNCNAME} called with both package list and jar name"
		java-pkg_record-jar_ --optional "${pkgs}" "${jar}"
	fi

	java-pkg_do_write_
}

# @FUNCTION: java-pkg_register-environment-variable
# @USAGE: <name> <value>
# @DESCRIPTION:
# Register an arbitrary environment variable into package.env. The gjl launcher
# for this package or any package depending on this will export it into
# environement before executing java command.
# Must only be called in src_install phase.
JAVA_PKG_EXTRA_ENV="${T}/java-pkg-extra-env"
JAVA_PKG_EXTRA_ENV_VARS=""
java-pkg_register-environment-variable() {
	debug-print-function ${FUNCNAME} $*

	java-pkg_check-phase install

	[[ ${#} != 2 ]] && die "${FUNCNAME} takes two arguments"

	echo "${1}=\"${2}\"" >> ${JAVA_PKG_EXTRA_ENV}
	JAVA_PKG_EXTRA_ENV_VARS="${JAVA_PKG_EXTRA_ENV_VARS} ${1}"

	java-pkg_do_write_
}

# @FUNCTION: java-pkg_ensure-vm-version-sufficient
# @INTERNAL
# @DESCRIPTION:
# Checks if we have a sufficient VM and dies if we don't.
java-pkg_ensure-vm-version-sufficient() {
	debug-print-function ${FUNCNAME} $*

	local msg

	msg="Active Java VM (${JEM_VM}) cannot build this package"
	if ! java-pkg_is-vm-version-sufficient; then
		debug-print "VM is not suffient"
		eerror
		eerror "${msg}"
		eerror
		einfo
		einfo "Please use jem -S to set the correct one"
		einfo "Only Java 9+ is supported!"
		einfo
		die "${msg}"
	fi
}

# @FUNCTION: java-pkg_is-vm-version-sufficient
# @INTERNAL
# @DESCRIPTION:
# @RETURN: zero - VM is sufficient; non-zero - VM is not sufficient
java-pkg_is-vm-version-sufficient() {
	debug-print-function ${FUNCNAME} $*

	local IFS t supported v

	# less than 9 unsupported
	v="$(java-pkg_get-vm-version)"
	[[ ${v/1./} -lt 9 ]] && return 1

	# use current jdk version unless package overridden
	[[ -z ${JAVA_RELEASE} ]] && return 0

	supported=( $(javac --help | \
			sed -n 's/^.*Supported targets\: \([^ ].*\).*$/\1/p' ) )

	IFS=', '
	for t in ${supported[@]}; do
		[[ "${JAVA_RELEASE}" == "${t}" ]] && return 0
	done

	return 1
}

# @FUNCTION: java-pkg_ensure-vm-version-eq
# @INTERNAL
# @DESCRIPTION:
# Die if the current VM is not equal to the argument passed.
#
# @param $@ - Desired VM version to ensure
java-pkg_ensure-vm-version-eq() {
	debug-print-function ${FUNCNAME} $*

	if ! java-pkg_is-vm-version-eq $@ ; then
		debug-print "VM is not suffient"
		eerror "This package requires a Java VM version = $@"
		einfo "Please use jem -S to set the correct one"
		die "Active Java VM too old"
	fi
}

# @FUNCTION: java-pkg_is-vm-version-eq
# @USAGE: <version>
# @INTERNAL
# @RETURN: zero - VM versions are equal; non-zero - VM version are not equal
java-pkg_is-vm-version-eq() {
	debug-print-function ${FUNCNAME} $*

	local needed_version="$@"

	[[ -z "${needed_version}" ]] && die "need an argument"

	local vm_version="$(java-pkg_get-vm-version)"

	vm_version="$(get_version_component_range 1-2 "${vm_version}")"
	needed_version="$(get_version_component_range 1-2 "${needed_version}")"

	if [[ -z "${vm_version}" ]]; then
		debug-print "Could not get JDK version from DEPEND"
		return 1
	else
		if [[ "${vm_version}" == "${needed_version}" ]]; then
			debug-print "Detected a JDK(${vm_version}) = ${needed_version}"
			return 0
		else
			debug-print "Detected a JDK(${vm_version}) != ${needed_version}"
			return 1
		fi
	fi
}

# @FUNCTION: java-pkg_ensure-vm-version-ge
# @INTERNAL
# @DESCRIPTION:
# Die if the current VM is not greater than the desired version
#
# @param $@ - VM version to compare current to
java-pkg_ensure-vm-version-ge() {
	debug-print-function ${FUNCNAME} $*

	if ! java-pkg_is-vm-version-ge "$@" ; then
		debug-print "vm is not suffient"
		eerror "This package requires a Java VM version >= $@"
		einfo "Please use jem -S to set the correct one"
		die "Active Java VM too old"
	fi
}

# @FUNCTION: java-pkg_is-release-ge
# @INTERNAL
# @DESCRIPTION:
# @CODE
# Parameters:
# $@ - release to compare current release
# @CODE
# @RETURN: zero - current release is greater than checked release;
#          non-zero - current release is not greater than checked release
java-pkg_is-release-ge() {
	debug-print-function ${FUNCNAME} $*

	local needed=$@
	local release=$(java-pkg_get-release)
	if [[ -z "${release}" ]]; then
		debug-print "Could not get release from DEPEND"
		return 1
	else
		if version_is_at_least "${needed}" "${release}"; then
			debug-print "Detected release >= ${needed}"
			return 0
		else
			debug-print "Detected release < ${needed}"
			return 1
		fi
	fi
}

# @FUNCTION: java-pkg_is-vm-version-ge
# @INTERNAL
# @DESCRIPTION:
# @CODE
# Parameters:
# $@ - VM version to compare current VM to
# @CODE
# @RETURN: zero - current VM version is greater than checked version;
# 	non-zero - current VM version is not greater than checked version
java-pkg_is-vm-version-ge() {
	debug-print-function ${FUNCNAME} $*

	local needed_version=$@
	local vm_version=$(java-pkg_get-vm-version)
	if [[ -z "${vm_version}" ]]; then
		debug-print "Could not get JDK version from DEPEND"
		return 1
	else
		if version_is_at_least "${needed_version}" "${vm_version}"; then
			debug-print "Detected a JDK(${vm_version}) >= ${needed_version}"
			return 0
		else
			debug-print "Detected a JDK(${vm_version}) < ${needed_version}"
			return 1
		fi
	fi
}

java-pkg_set-current-vm() {
	export JEM_VM=${1}
}

java-pkg_current-vm-matches() {
	has $(java-pkg_get-current-vm) ${@}
	return $?
}

# @FUNCTION: java-pkg_get-release
# @DESCRIPTION:
# Determines what release version should be used, for passing to --release.
# version of your JDK.
#
# @RETURN: string - Either the current target, or JAVA_RELEASE
java-pkg_get-release() {
	local r
	r=${JAVA_RELEASE:-$(java-pkg_get-vm-version)}
	echo ${r/1./}
}

# @FUNCTION: java-pkg_get-javac
# @DESCRIPTION:
# Returns the compiler executable
java-pkg_get-javac() {
	debug-print-function ${FUNCNAME} $*

	java-pkg_init-compiler_
	local compiler="${GENTOO_COMPILER}"

	local compiler_executable
	if [[ "${compiler}" = "javac" ]]; then
		# nothing fancy needs to be done for javac
		compiler_executable="javac"
	else
		# for everything else, try to determine from an env file

		local compiler_env="/etc/jem/compiler/${compiler}"
		if [[ -f ${compiler_env} ]]; then
			local old_javac=${JAVAC}
			unset JAVAC
			# try to get value of JAVAC
			compiler_executable="$(source ${compiler_env} 1>/dev/null 2>&1; echo ${JAVAC})"
			export JAVAC=${old_javac}

			if [[ -z ${compiler_executable} ]]; then
				die "JAVAC is empty or undefined in ${compiler_env}"
			fi

			# check that it's executable
			if [[ ! -x ${compiler_executable} ]]; then
				die "${compiler_executable} doesn't exist, or isn't executable"
			fi
		else
			die "Could not find environment file for ${compiler}"
		fi
	fi
	echo ${compiler_executable}
}

# @FUNCTION: java-pkg_javac-args
# @DESCRIPTION:
# If an ebuild uses javac directly, instead of using ejavac, it should call this
# to know what -source/-target to use.
#
# @RETURN: string - arguments to pass to javac, complete with -target and -source
java-pkg_javac-args() {
	debug-print-function ${FUNCNAME} $*

	local want_release release_str version
	version="$(java-pkg_get-vm-version)"
	want_release="$(java-pkg_get-release)"
	if [[ ${version} -le 9 ]] &&
		[[ "${version}" != "${want_release}" ]]; then
		release_str="--release ${want_release}"
	fi

	debug-print "want release: ${want_release}"

	if [[ -z "${want_release}" ]]; then
		die "Could not find valid --release values for javac"
	else
		echo "${release_str}"
	fi
}

# @FUNCTION: java-pkg_get-jni-cflags
# @DESCRIPTION:
# Echos the CFLAGS for JNI compilations
java-pkg_get-jni-cflags() {
	local flags="-I${JAVA_HOME}/include"

	local platform="linux"
	use elibc_FreeBSD && platform="freebsd"

	# TODO do a check that the directories are valid
	flags="${flags} -I${JAVA_HOME}/include/${platform}"

	echo ${flags}
}

# @FUNCTION: java-pkg_register-ant-task
# @USAGE: [--version x.y] [<name>]
# @DESCRIPTION:
# Register this package as ant task, so that ant will load it when no specific
# ANT_TASKS are specified. Note that even without this registering, all packages
# specified in ANT_TASKS will be loaded. Mostly used by the actual ant tasks
# packages, but can be also used by other ebuilds that used to symlink their
# .jar into /usr/share/ant-core/lib to get autoloaded, for backwards
# compatibility.
#
# @CODE
# Parameters
# --version x.y Register only for ant version x.y (otherwise for any ant
#		version). Used by the ant-* packages to prevent loading of mismatched
#		ant-core ant tasks after core was updated, before the tasks are updated,
#		without a need for blockers.
# $1 Name to register as. Defaults to JAVA_PKG_NAME ($PN[-$SLOT])
# @CODE
java-pkg_register-ant-task() {
	local TASKS_DIR="tasks"

	# check for --version x.y parameters
	while [[ -n "${1}" && -n "${2}" ]]; do
		local var="${1#--}"
		local val="${2}"
		if [[ "${var}" == "version" ]]; then
			TASKS_DIR="tasks-${val}"
		else
			die "Unknown parameter passed to java-pkg_register-ant-tasks: ${1} ${2}"
		fi
		shift 2
	done

	local TASK_NAME="${1:-${JAVA_PKG_NAME}}"

	dodir /usr/share/ant/${TASKS_DIR}
	touch "${D}/usr/share/ant/${TASKS_DIR}/${TASK_NAME}"
}

# @FUNCTION: ejunit_
# @INTERNAL
# @DESCRIPTION:
# Internal Junit wrapper function. Makes it easier to run the tests and checks for
# dev-java/junit in DEPEND. Launches the tests using junit.textui.TestRunner.
# @CODE
# Parameters:
# $1 - junit package (junit or junit-4)
# $2 - -cp or -classpath
# $3 - classpath; junit and recorded dependencies get appended
# $@ - the rest of the parameters are passed to java
# @CODE
ejunit_() {
	debug-print-function ${FUNCNAME} $*

	local pkgs
	if [[ -f ${JAVA_PKG_DEPEND_FILE} ]]; then
		for atom in $(cat ${JAVA_PKG_DEPEND_FILE} | tr : ' '); do
			pkgs=${pkgs},$(echo ${atom} | sed -re "s/^.*@//")
		done
	fi

	local junit=${1}
	shift 1

	local cp=$(java-pkg_getjars --with-dependencies ${junit}${pkgs})
	if [[ ${1} = -cp || ${1} = -classpath ]]; then
		cp="${2}:${cp}"
		shift 2
	else
		cp=".:${cp}"
	fi

	local runner=junit.textui.TestRunner
	if [[ "${junit}" == "junit-4" ]] ; then
		runner=org.junit.runner.JUnitCore
	fi
	debug-print "Calling: java -cp \"${cp}\" -Djava.io.tmpdir=\"${T}\" -Djava.awt.headless=true ${runner} ${@}"
	java -cp "${cp}" -Djava.io.tmpdir="${T}/" -Djava.awt.headless=true ${runner} "${@}" || die "Running junit failed"
}

# @FUNCTION: ejunit
# @DESCRIPTION:
# Junit wrapper function. Makes it easier to run the tests and checks for
# dev-java/junit in DEPEND. Launches the tests using org.junit.runner.JUnitCore.
#
# @CODE
# Parameters:
# $1 - -cp or -classpath
# $2 - classpath; junit and recorded dependencies get appended
# $@ - the rest of the parameters are passed to java
#
# Examples:
# ejunit -cp build/classes org.blinkenlights.jid3.test.AllTests
# ejunit org.blinkenlights.jid3.test.AllTests
# ejunit org.blinkenlights.jid3.test.FirstTest org.blinkenlights.jid3.test.SecondTest
# @CODE
ejunit() {
	debug-print-function ${FUNCNAME} $*

	ejunit_ "junit" "${@}"
}

# @FUNCTION: ejunit4
# @DESCRIPTION:
# Junit4 wrapper function. Makes it easier to run the tests and checks for
# dev-java/junit:4 in DEPEND. Launches the tests using junit.textui.TestRunner.
#
# @CODE
# Parameters:
# $1 - -cp or -classpath
# $2 - classpath; junit and recorded dependencies get appended
# $@ - the rest of the parameters are passed to java
#
# Examples:
# ejunit4 -cp build/classes org.blinkenlights.jid3.test.AllTests
# ejunit4 org.blinkenlights.jid3.test.AllTests
# ejunit4 org.blinkenlights.jid3.test.FirstTest \
#         org.blinkenlights.jid3.test.SecondTest
# @CODE
ejunit4() {
	debug-print-function ${FUNCNAME} $*

	ejunit_ "junit-4" "${@}"
}

# @FUNCTION: java-utils-2_src_prepare
# @DESCRIPTION:
# src_prepare Searches for bundled jars
# Don't call directly, but via java-pkg-2_src_prepare!
java-utils-2_src_prepare() {
	case ${EAPI:-0} in
		[0-5]) ;;
		*) default ;;
	esac

	if [[ -z ${JAVA_SRC_DIR} ]]; then
		if [[ -d "${S}/src/main/java" ]]; then
			JAVA_SRC_DIR="src/main/java"
		elif [[ -d "${S}/src/java" ]]; then
			JAVA_SRC_DIR="src/java"
		elif [[ -d "${S}/src/main" ]]; then
			JAVA_SRC_DIR="src/main"
		elif [[ -d "${S}/src" ]]; then
			JAVA_SRC_DIR="src"
		fi
	fi

	# Check for files in JAVA_RM_FILES array.
	if [[ ${JAVA_RM_FILES[@]} ]]; then
		debug-print "$FUNCNAME: removing unneeded files"
		_java-pkg_rm_files "${JAVA_RM_FILES[@]}"
	fi

	java-pkg_func-exists java_prepare && java_prepare
}

# @FUNCTION: java-utils-2_pkg_preinst
# @DESCRIPTION:
# pkg_preinst Searches for missing and unneeded dependencies
# Don't call directly, but via java-pkg-2_pkg_preinst!
java-utils-2_pkg_preinst() {
	if is-java-strict; then
		if [[ ! -e "${JAVA_PKG_ENV}" ]]; then
			return
		fi

		if has_version dev-java/java-dep-check; then
			local output=$(JEM_VM= java-dep-check --image "${D}" "${JAVA_PKG_ENV}")
			[[ ${output} ]] && ewarn "${output}"
		fi
	fi
}

# @FUNCTION: ejavac
# @USAGE: <javac_arguments>
# @DESCRIPTION:
# Javac wrapper function. Will use the appropriate compiler, based on
# /etc/jem/compilers.conf
ejavac() {
	debug-print-function ${FUNCNAME} $*
	local compiler_executable javac_args

	compiler_executable=$(java-pkg_get-javac)

	javac_args="$(java-pkg_javac-args)"
	[[ -z ${JAVA_PKG_DEBUG} ]] && javac_args+=" -nowarn "
	javac_args+=" -J-Djava.io.tmpdir=\"${T}\" "

	if [[ -n ${JAVA_PKG_DEBUG} ]]; then
		einfo "Verbose logging for \"${FUNCNAME}\" function"
		einfo "Compiler executable: ${compiler_executable}"
		einfo "Extra arguments: ${javac_args}"
		einfo "Complete command:"
		einfo "${compiler_executable} ${javac_args} ${@}"
	fi

	ebegin "Compiling"
	${compiler_executable} ${javac_args} "${@}" || die "ejavac failed"
}

# @FUNCTION: ejavadoc
# @USAGE: <javadoc_arguments>
# @DESCRIPTION:
# javadoc wrapper function. Will set some flags based on the VM version
# due to strict javadoc rules in 1.8.
ejavadoc() {
	debug-print-function ${FUNCNAME} $*

	local javadoc_args
	javadoc_args="$(java-pkg_javac-args)"

	if java-pkg_is-vm-version-ge "1.8" ; then
		javadoc_args+=" -Xdoclint:none"
	fi

	if [[ -n ${JAVA_PKG_DEBUG} ]]; then
		einfo "Verbose logging for \"${FUNCNAME}\" function"
		einfo "Javadoc executable: javadoc"
		einfo "Extra arguments: ${javadoc_args}"
		einfo "Complete command:"
		einfo "javadoc ${javadoc_args} ${@}"
	fi

	ebegin "Generating JavaDoc"
	javadoc ${javadoc_args} "${@}" || die "ejavadoc failed"
}

# @FUNCTION: java-pkg_filter-compiler
# @USAGE: <compiler(s)_to_filter>
# @DESCRIPTION:
# Used to prevent the use of some compilers. Should be used in src_compile.
# Basically, it just appends onto JAVA_PKG_FILTER_COMPILER
java-pkg_filter-compiler() {
	JAVA_PKG_FILTER_COMPILER="${JAVA_PKG_FILTER_COMPILER} $@"
}

# @FUNCTION: java-pkg_force-compiler
# @USAGE: <compiler(s)_to_force>
# @DESCRIPTION:
# Used to force the use of particular compilers. Should be used in src_compile.
# A common use of this would be to force ecj-3.1 to be used on amd64, to avoid
# OutOfMemoryErrors that may come up.
java-pkg_force-compiler() {
	JAVA_PKG_FORCE_COMPILER="$@"
}

# @FUNCTION: java-pkg_init
# @INTERNAL
# @DESCRIPTION:
# The purpose of this function, as the name might imply, is to initialize the
# Java environment. It ensures that that there aren't any environment variables
# that'll muss things up. It initializes some variables, which are used
# internally. And most importantly, it'll switch the VM if necessary.
#
# This shouldn't be used directly. Instead, java-pkg and java-pkg-opt will
# call it during each of the phases of the merge process.
java-pkg_init() {
	debug-print-function ${FUNCNAME} $*

	# Don't set up build environment if installing from binary. #206024 #258423
	[[ "${MERGE_TYPE}" == "binary" ]] && return

	unset JAVAC
	unset JAVA_HOME

	jem --version >/dev/null || {
		eerror ""
		eerror "Unable to run jem --version"
		die "Unable run jem --version"
	}

	# People do all kinds of weird things.
	# https://forums.gentoo.org/viewtopic-p-3943166.html
	local silence="${SILENCE_JAVA_OPTIONS_WARNING}"
	local accept="${I_WANT_GLOBAL_JAVA_OPTIONS}"
	if [[ -n ${_JAVA_OPTIONS} && -z ${accept} && -z ${silence} ]]; then
		ewarn "_JAVA_OPTIONS changes what java -version outputs at least for"
		ewarn "oracle-jdk-bin vms and and as such break configure scripts that"
		ewarn "use it (for example app-office/openoffice) so we filter it out."
		ewarn "Use SILENCE_JAVA_OPTIONS_WARNING=true in the environment (use"
		ewarn "make.conf for example) to silence this warning or"
		ewarn "I_WANT_GLOBAL_JAVA_OPTIONS to not filter it."
	fi

	if [[ -z ${accept} ]]; then
		# export _JAVA_OPTIONS= doesn't work because it will show up in java
		# -version output
		unset _JAVA_OPTIONS
		# phase hooks make this run many times without this
		I_WANT_GLOBAL_JAVA_OPTIONS="true"
	fi

	java-pkg_switch-vm
	PATH=${JAVA_HOME}/bin:${PATH}

	# TODO we will probably want to set JAVAC and JAVACFLAGS

	# Do some QA checks

	# Can't use unset here because Portage does not save the unset
	# see https://bugs.gentoo.org/show_bug.cgi?id=189417#c11

	# When users have crazy classpaths some packages can fail to compile.
	# and everything should work with empty CLASSPATH.
	# This also helps prevent unexpected dependencies on random things
	# from the CLASSPATH.
	export CLASSPATH=
}

# @FUNCTION: java-pkg-init-compiler_
# @INTERNAL
# @DESCRIPTION:
# This function attempts to figure out what compiler should be used. It does
# this by reading the file at JAVA_PKG_COMPILERS_CONF, and checking the
# COMPILERS variable defined there.
# This can be overridden by a list in JAVA_PKG_FORCE_COMPILER
#
# It will go through the list of compilers, and verify that it supports the
# target and source that are needed. If it is not suitable, then the next
# compiler is checked. When JAVA_PKG_FORCE_COMPILER is defined, this checking
# isn't done.
#
# Once the which compiler to use has been figured out, it is set to
# GENTOO_COMPILER.
#
# If you hadn't guessed, JAVA_PKG_FORCE_COMPILER is for testing only.
#
# If the user doesn't defined anything in JAVA_PKG_COMPILERS_CONF, or no
# suitable compiler was found there, then the default is to use javac provided
# by the current VM.
#
#
# @RETURN name of the compiler to use
java-pkg_init-compiler_() {
	debug-print-function ${FUNCNAME} $*

	if [[ -n ${GENTOO_COMPILER} ]]; then
		debug-print "GENTOO_COMPILER already set"
		return
	fi

	local compilers;
	if [[ -z ${JAVA_PKG_FORCE_COMPILER} ]]; then
		compilers="$(source ${JAVA_PKG_COMPILERS_CONF} 1>/dev/null 2>&1; echo	${COMPILERS})"
	else
		compilers=${JAVA_PKG_FORCE_COMPILER}
	fi

	debug-print "Read \"${compilers}\" from ${JAVA_PKG_COMPILERS_CONF}"

	# Figure out if we should announce what compiler we're using
	local compiler
	for compiler in ${compilers}; do
		debug-print "Checking ${compiler}..."
		# javac should always be alright
		if [[ ${compiler} = "javac" ]]; then
			debug-print "Found javac... breaking"
			export GENTOO_COMPILER="javac"
			break
		fi

		if has ${compiler} ${JAVA_PKG_FILTER_COMPILER}; then
			if [[ -z ${JAVA_PKG_FORCE_COMPILER} ]]; then
				einfo "Filtering ${compiler}" >&2
				continue
			fi
		fi

		# for non-javac, we need to make sure it supports the right target and
		# source
		local compiler_env="${JAVA_PKG_COMPILER_DIR}/${compiler}"
		if [[ -f ${compiler_env} ]]; then
			local desired_release="$(java-pkg_get-release)"

			# Verify that the compiler supports target
			local supported_release=$(source ${compiler_env} 1>/dev/null 2>&1; echo ${SUPPORTED_TARGET})
			if ! has ${desired_release} ${supported_release}; then
				ewarn "${compiler} does not support --release ${desired_release}, skipping"
				continue
			fi

			# if you get here, then the compiler should be good to go
			export GENTOO_COMPILER="${compiler}"
			break
		else
			ewarn "Could not find configuration for ${compiler}, skipping"
			ewarn "Perhaps it is not installed?"
			continue
		fi
	done

	# If it hasn't been defined already, default to javac
	if [[ -z ${GENTOO_COMPILER} ]]; then
		if [[ -n ${compilers} ]]; then
			einfo "No suitable compiler found: defaulting to JDK default for compilation" >&2
		else
			# probably don't need to notify users about the default.
			:;#einfo "Defaulting to javac for compilation" >&2
		fi
		if jem -g GENTOO_COMPILER 2> /dev/null; then
			export GENTOO_COMPILER=$(jem -g GENTOO_COMPILER)
		else
			export GENTOO_COMPILER=javac
		fi
	else
		einfo "Using ${GENTOO_COMPILER} for compilation" >&2
	fi

}

# @FUNCTION: init_paths_
# @INTERNAL
# @DESCRIPTION:
# Initializes some variables that will be used. These variables are mostly used
# to determine where things will eventually get installed.
java-pkg_init_paths_() {
	debug-print-function ${FUNCNAME} $*

	local pkg_name
	if [[ "${SLOT%/*}" == "0" ]] ; then
		JAVA_PKG_NAME="${PN}"
	else
		JAVA_PKG_NAME="${PN}-${SLOT%/*}"
	fi

	JAVA_PKG_SHAREPATH="/usr/share/${JAVA_PKG_NAME}"
	JAVA_PKG_SOURCESPATH="${JAVA_PKG_SHAREPATH}/sources/"
	JAVA_PKG_ENV="${D}${JAVA_PKG_SHAREPATH}/package.env"
	JAVA_PKG_VIRTUALS_PATH="/etc/jem/virtuals.d/"
	JAVA_PKG_VIRTUAL_PROVIDER="${D}/${JAVA_PKG_VIRTUALS_PATH}/${JAVA_PKG_NAME}"

	[[ -z "${JAVA_PKG_JARDEST}" ]] && JAVA_PKG_JARDEST="${JAVA_PKG_SHAREPATH}/lib"
	[[ -z "${JAVA_PKG_LIBDEST}" ]] && JAVA_PKG_LIBDEST="/usr/$(get_libdir)/${JAVA_PKG_NAME}"
	[[ -z "${JAVA_PKG_WARDEST}" ]] && JAVA_PKG_WARDEST="${JAVA_PKG_SHAREPATH}/webapps"

	# TODO maybe only print once?
	debug-print "JAVA_PKG_SHAREPATH: ${JAVA_PKG_SHAREPATH}"
	debug-print "JAVA_PKG_ENV: ${JAVA_PKG_ENV}"
	debug-print "JAVA_PKG_JARDEST: ${JAVA_PKG_JARDEST}"
	debug-print "JAVA_PKG_LIBDEST: ${JAVA_PKG_LIBDEST}"
	debug-print "JAVA_PKG_WARDEST: ${JAVA_PKG_WARDEST}"
}

# @FUNCTION: java-pkg_do_write_
# @INTERNAL
# @DESCRIPTION:
# Writes the package.env out to disk.
#
# TODO change to do-write, to match everything else
java-pkg_do_write_() {
	debug-print-function ${FUNCNAME} $*
	java-pkg_init_paths_
	# Create directory for package.env
	dodir "${JAVA_PKG_SHAREPATH}"

	# Create package.env
	(
		echo "DESCRIPTION=\"${DESCRIPTION}\""
		echo "SLOT=\"${SLOT}\""
		echo "CATEGORY=\"${CATEGORY}\""
		echo "PVR=\"${PVR}\""

		[[ -n "${JAVA_PKG_CLASSPATH}" ]] && echo "CLASSPATH=\"${JAVA_PKG_CLASSPATH}\""
		[[ -n "${JAVA_PKG_LIBRARY}" ]] && echo "LIBRARY_PATH=\"${JAVA_PKG_LIBRARY}\""
		[[ -n "${JAVA_PROVIDE}" ]] && echo "PROVIDES=\"${JAVA_PROVIDE}\""
		[[ -f "${JAVA_PKG_DEPEND_FILE}" ]] \
			&& echo "DEPEND=\"$(sort -u "${JAVA_PKG_DEPEND_FILE}" | tr '\n' ':')\""
		[[ -f "${JAVA_PKG_OPTIONAL_DEPEND_FILE}" ]] \
			&& echo "OPTIONAL_DEPEND=\"$(sort -u "${JAVA_PKG_OPTIONAL_DEPEND_FILE}" | tr '\n' ':')\""
		echo "VM=\"$(echo ${RDEPEND} ${DEPEND} | sed -e 's/ /\n/g' | sed -n -e '/virtual\/\(jre\|jdk\)/ { p;q }')\"" # TODO cleanup !
		[[ -f "${JAVA_PKG_BUILD_DEPEND_FILE}" ]] \
			&& echo "BUILD_DEPEND=\"$(sort -u "${JAVA_PKG_BUILD_DEPEND_FILE}" | tr '\n' ':')\""
	) > "${JAVA_PKG_ENV}"

	# register release
	local release="$(java-pkg_get-release)"
	[[ -n ${release} ]] && echo "RELEASE=\"${release}\"" >> "${JAVA_PKG_ENV}"

	# register javadoc info
	[[ -n ${JAVADOC_PATH} ]] && echo "JAVADOC_PATH=\"${JAVADOC_PATH}\"" \
		>> ${JAVA_PKG_ENV}
	# register source archives
	[[ -n ${JAVA_SOURCES} ]] && echo "JAVA_SOURCES=\"${JAVA_SOURCES}\"" \
		>> ${JAVA_PKG_ENV}

	echo "MERGE_VM=\"${JEM_VM}\"" >> "${JAVA_PKG_ENV}"
	[[ -n ${GENTOO_COMPILER} ]] && echo "MERGE_COMPILER=\"${GENTOO_COMPILER}\"" >> "${JAVA_PKG_ENV}"

	# extra env variables
	if [[ -n "${JAVA_PKG_EXTRA_ENV_VARS}" ]]; then
		cat "${JAVA_PKG_EXTRA_ENV}" >> "${JAVA_PKG_ENV}" || die
		# nested echo to remove leading/trailing spaces
		echo "ENV_VARS=\"$(echo ${JAVA_PKG_EXTRA_ENV_VARS})\"" \
			>> "${JAVA_PKG_ENV}" || die
	fi

	# Strip unnecessary leading and trailing colons
	# TODO try to cleanup if possible
	sed -e "s/=\":/=\"/" -e "s/:\"$/\"/" -i "${JAVA_PKG_ENV}" || die "Did you forget to call java_init ?"
}

# @FUNCTION: java-pkg_record-jar_
# @INTERNAL
# @DESCRIPTION:
# Record an (optional) dependency to the package.env
# @CODE
# Parameters:
# --optional - record dependency as optional
# --build - record dependency as build_only
# $1 - package to record
# $2 - (optional) jar of package to record
# @CODE
JAVA_PKG_DEPEND_FILE="${T}/java-pkg-depend"
JAVA_PKG_OPTIONAL_DEPEND_FILE="${T}/java-pkg-optional-depend"
JAVA_PKG_BUILD_DEPEND_FILE="${T}/java-pkg-build-depend"

java-pkg_record-jar_() {
	debug-print-function ${FUNCNAME} $*

	local depend_file="${JAVA_PKG_DEPEND_FILE}"
	case "${1}" in
		"--optional") depend_file="${JAVA_PKG_OPTIONAL_DEPEND_FILE}"; shift;;
		"--build-only") depend_file="${JAVA_PKG_BUILD_DEPEND_FILE}"; shift;;
	esac

	local pkg=${1} jar=${2} append
	if [[ -z "${jar}" ]]; then
		append="${pkg}"
	else
		append="$(basename ${jar})@${pkg}"
	fi

	echo "${append}" >> "${depend_file}"
}

# @FUNCTION: java-pkg_append_
# @INTERNAL
# @DESCRIPTION:
# Appends a value to a variable
#
# @CODE
# Parameters:
# $1 variable name to modify
# $2 value to append
#
# Examples:
#	java-pkg_append_ CLASSPATH foo.jar
# @CODE
java-pkg_append_() {
	debug-print-function ${FUNCNAME} $*

	local var="${1}" value="${2}"
	if [[ -z "${!var}" ]] ; then
		export ${var}="${value}"
	else
		local oldIFS=${IFS} cur haveit
		IFS=':'
		for cur in ${!var}; do
			if [[ ${cur} == ${value} ]]; then
				haveit="yes"
				break
			fi
		done
		[[ -z ${haveit} ]] && export ${var}="${!var}:${value}"
		IFS=${oldIFS}
	fi
}

# @FUNCTION: java-pkg_expand_dir_
# @INTERNAL
# @DESCRIPTION:
# Gets the full path of the file/directory's parent.
# @CODE
# Parameters:
# $1 - file/directory to find parent directory for
# @CODE
# @RETURN: path to $1's parent directory
java-pkg_expand_dir_() {
	pushd "$(dirname "${1}")" >/dev/null 2>&1 || die
	pwd
	popd >/dev/null 2>&1 || die
}

# @FUNCTION: java-pkg_func-exists
# @INTERNAL
# @DESCRIPTION:
# Does the indicated function exist?
# @RETURN: 0 - function is declared, 1 - function is undeclared
java-pkg_func-exists() {
	declare -F ${1} > /dev/null
}

# @FUNCTION: java-pkg_setup-vm
# @INTERNAL
# @DESCRIPTION:
# Sets up the environment for a specific VM
java-pkg_setup-vm() {
	debug-print-function ${FUNCNAME} $*

	local vendor="$(java-pkg_get-vm-vendor)"
	if [[ "${vendor}" == "oracle" ]] || [[ "${vendor}" == icedtea* ]]; then
		addpredict "/dev/random"
		addpredict "/proc/self/coredump_filter"
	fi
}

# @FUNCTION: java-pkg_needs-vm
# @INTERNAL
# @DESCRIPTION:
# Does the current package depend on virtual/jdk or does it set
# JAVA_PKG_WANT_BUILD_VM?
#
# @RETURN: 0 - Package depends on virtual/jdk; 1 - Package does not depend on virtual/jdk
java-pkg_needs-vm() {
	debug-print-function ${FUNCNAME} $*

	if [[ "${JAVA_PKG_NV_DEPEND:-${DEPEND}}" == *"virtual/jdk"* ]] || \
		[[ -n "${JAVA_PKG_WANT_BUILD_VM}" ]]; then
		return 0
	fi

	return 1
}

# @FUNCTION: java-pkg_get-current-vm
# @INTERNAL
# @RETURN - The current VM being used
java-pkg_get-current-vm() {
	jem -f
}

# @FUNCTION: java-pkg_get-vm-vendor
# @INTERNAL
# @RETURN - The vendor of the current VM
java-pkg_get-vm-vendor() {
	debug-print-function ${FUNCNAME} $*

	local vm="$(java-pkg_get-current-vm)"
	vm="${vm/-*/}"
	echo "${vm}"
}

# @FUNCTION: java-pkg_get-vm-version
# @INTERNAL
# @RETURN - The version of the current VM
java-pkg_get-vm-version() {
	debug-print-function ${FUNCNAME} $*

	jem -g PROVIDES_VERSION
}

# @FUNCTION: java-pkg_build-vm-from-handle
# @INTERNAL
# @DESCRIPTION:
# Selects a build vm from a list of vm handles. First checks for the system-vm
# beeing usable, then steps through the listed handles till a suitable vm is
# found.
#
# @RETURN - VM handle of an available JDK
java-pkg_build-vm-from-handle() {
	debug-print-function ${FUNCNAME} "$*"

	local vm
	vm=$(java-pkg_get-current-vm 2>/dev/null)
	if [[ $? -eq 0 ]]; then
		if has ${vm} ${JAVA_PKG_WANT_BUILD_VM}; then
			echo ${vm}
			return 0
		fi
	fi

	for vm in ${JAVA_PKG_WANT_BUILD_VM}; do
		if jem --select-vm=${vm} 2>/dev/null; then
			echo ${vm}
			return 0
		fi
	done

	eerror "${FUNCNAME}: No vm found for handles: ${JAVA_PKG_WANT_BUILD_VM}"
	return 1
}

# @FUNCTION: java-pkg_switch-vm
# @INTERNAL
# @DESCRIPTION:
# Switch VM if we're allowed to (controlled by JAVA_PKG_ALLOW_VM_CHANGE), and
# verify that the current VM is sufficient.
# Setup the environment for the VM being used.
java-pkg_switch-vm() {
	debug-print-function ${FUNCNAME} $*

	if java-pkg_needs-vm; then
		# Use the VM specified by JAVA_PKG_FORCE_VM
		if [[ -n "${JAVA_PKG_FORCE_VM}" ]]; then
			# If you're forcing the VM, I hope you know what your doing...
			debug-print "JAVA_PKG_FORCE_VM used: ${JAVA_PKG_FORCE_VM}"
			export JEM_VM="${JAVA_PKG_FORCE_VM}"
		# if we're allowed to switch the vm...
		elif [[ "${JAVA_PKG_ALLOW_VM_CHANGE}" == "yes" ]]; then
			# if there is an explicit list of handles to choose from
			if [[ -n "${JAVA_PKG_WANT_BUILD_VM}" ]]; then
				debug-print "JAVA_PKG_WANT_BUILD_VM used: ${JAVA_PKG_WANT_BUILD_VM}"
				JEM_VM=$(java-pkg_build-vm-from-handle)
				if [[ $? != 0 ]]; then
					eerror "${FUNCNAME}: No VM found for handles: ${JAVA_PKG_WANT_BUILD_VM}"
					die "${FUNCNAME}: Failed to determine VM for building"
				fi
				# JAVA_RELEASE is required as
				# it cannot be deduced from handles.
				if [[ -z "${JAVA_RELEASE}" ]]; then
					eerror "JAVA_PKG_WANT_BUILD_VM specified without JAVA_RELEASE"
					die "Specify JAVA_RELEASE"
				fi
			else
				JEM_VM=$(java-pkg_get-current-vm)
			fi
			export JEM_VM
		fi

		java-pkg_ensure-vm-version-sufficient

		debug-print "Using: $(jem -f)"

		java-pkg_setup-vm

		export JAVA=$(jem --java)
		export JAVAC=$(jem --javac)
		JAVACFLAGS="$(java-pkg_javac-args)"
		[[ -n ${JAVACFLAGS_EXTRA} ]] && JAVACFLAGS="${JAVACFLAGS_EXTRA} ${JAVACFLAGS}"
		export JAVACFLAGS

		export JAVA_HOME="$(jem -g JAVA_HOME)"
		export JDK_HOME=${JAVA_HOME}

		#TODO If you know a better solution let us know.
		java-pkg_append_ LD_LIBRARY_PATH "$(jem -g LDPATH)"

		local tann="${T}/announced-vm"
		# With the hooks we should only get here once from pkg_setup but better safe than sorry
		# if people have for example modified eclasses some where
		if [[ -n "${JAVA_PKG_DEBUG}" ]] || [[ ! -f "${tann}" ]] ; then
			einfo "Using: $(jem -f)"
			[[ ! -f "${tann}" ]] && touch "${tann}"
		fi

	else
		[[ -n "${JAVA_PKG_DEBUG}" ]] && ewarn "!!! This package inherits java-pkg but doesn't depend on a JDK. -bin or broken dependency!!!"
	fi
}

# @FUNCTION: java-pkg_die
# @INTERNAL
# @DESCRIPTION:
# Enhanced die for Java packages, which displays some information that may be
# useful for debugging bugs on bugzilla.
#register_die_hook java-pkg_die
if ! has java-pkg_die ${EBUILD_DEATH_HOOKS}; then
	EBUILD_DEATH_HOOKS+=" java-pkg_die"
fi

java-pkg_die() {
	echo "Please include the following information in bug reports:" >&2
	echo "" >&2
	echo "JEM_VM=${JEM_VM}" >&2
	echo "JAVA_HOME=\"${JAVA_HOME}\"" >&2
	echo "COMPILER=\"${JEM_COMPILER}\"" >&2
	echo "JAVAC_FLAGS=\"${JAVAC_FLAGS}\"" >&2
	echo "CLASSPATH=\"${JAVA_CLASSPATH}\"" >&2
	echo "emerge --info =${P}" >&2
	echo "" >&2
	echo "Please report bugs to" >&2
	echo "https://github.com/Obsidian-StudiosInc/os-xtoo/issues" >&2
}

# @FUNCTION: java-pkg_verify-classes
# @INTERNAL
# @DESCRIPTION:
# Verify that the classes were compiled for the right source / target. Dies if
# not.
# @CODE
# $1 (optional) - the file to check, otherwise checks whole ${D}
# @CODE
java-pkg_verify-classes() {
	#$(find ${D} -type f -name '*.jar' -o -name '*.class')

	local version_verify="/usr/bin/class-version-verify.py"

	if [[ ! -x "${version_verify}" ]]; then
		version_verify="/usr/$(get_libdir)/javatoolkit/bin/class-version-verify.py"
	fi

	if [[ ! -x "${version_verify}" ]]; then
		ewarn "Unable to perform class version checks as"
		ewarn "class-version-verify.py is unavailable"
		ewarn "Please install dev-java/javatoolkit."
		return
	fi

	local release=$(java-pkg_get-release)
	local result
	local log="${T}/class-version-verify.log"
	if [[ -n "${1}" ]]; then
		${version_verify} -v -t ${release} "${1}" > "${log}"
		result=$?
	else
		ebegin "Verifying java class versions (target: ${target})"
		${version_verify} -v -t ${release} -r "${D}" > "${log}"
		result=$?
		eend ${result}
	fi
	[[ -n ${JAVA_PKG_DEBUG} ]] && cat "${log}"
	if [[ ${result} != 0 ]]; then
		eerror "Incorrect bytecode version found"
		[[ -n "${1}" ]] && eerror "in file: ${1}"
		eerror "See ${log} for more details."
		die "Incorrect bytecode found"
	fi
}

# @FUNCTION: java-pkg_ensure-dep
# @INTERNAL
# @DESCRIPTION:
# Check that a package being used in jarfrom, getjars and getjar is contained
# within DEPEND or RDEPEND with the correct SLOT. See this mail for details:
# https://archives.gentoo.org/gentoo-dev/message/dcb644f89520f4bbb61cc7bbe45fdf6e
# @CODE
# Parameters:
# $1 - empty - check both vars; "runtime" or "build" - check only
#	RDEPEND, resp. DEPEND
# $2 - Package name and slot.
# @CODE
java-pkg_ensure-dep() {
	debug-print-function ${FUNCNAME} $*

	local limit_to="${1}"
	local target_pkg="${2}"
	local dev_error=""

	# Transform into a regular expression to look for a matching package
	# and SLOT. SLOTs don't have to be numeric so foo-bar could either
	# mean foo-bar:0 or foo:bar. So you want to get your head around the
	# line below?
	#
	# * The target package first has any dots escaped, e.g. foo-1.2
	#   becomes foo-1\.2.
	#
	# * sed then looks at the component following the last - or :
	#   character, or the whole string if there is no - or :
	#   character. It uses this to build a new regexp with two
	#   significant branches.
	#
	# * The first checks for the whole target package string, optionally
	#   followed by a version number, and then :0.
	#
	# * The second checks for the first part of the target package
	#   string, optionally followed by a version number, followed by the
	#   aforementioned component, treating that as a SLOT.
	#
	local stripped_pkg=/$(sed -r 's/[-:]?([^-:]+)$/(\0(-[^:]+)?:0|(-[^:]+)?:\1)/' <<< "${target_pkg//./\\.}")\\b

	debug-print "Matching against: ${stripped_pkg}"

	if [[ ${limit_to} != runtime && ! ( "${DEPEND}" =~ $stripped_pkg ) ]]; then
		dev_error="The ebuild is attempting to use ${target_pkg}, which is not "
		dev_error+="declared with a SLOT in DEPEND."
		eqawarn "java-pkg_ensure-dep: ${dev_error}"
	elif [[ ${limit_to} != build && ! ( "${RDEPEND}${PDEPEND}" =~ ${stripped_pkg} ) ]]; then
		dev_error="The ebuild is attempting to use ${target_pkg}, which is not "
		dev_error+="declared with a SLOT in [RP]DEPEND and --build-only wasn't given."
		eqawarn "java-pkg_ensure-dep: ${dev_error}"
	fi
}

java-pkg_check-phase() {
	local phase=${1}
	local funcname=${FUNCNAME[1]}
	if [[ ${EBUILD_PHASE} != ${phase} ]]; then
		local msg="${funcname} used outside of src_${phase}"
		java-pkg_announce-qa-violation "${msg}"
	fi
}

java-pkg_check-versioned-jar() {
	local jar=${1}

	if [[ ${jar} =~ ${PV} ]]; then
		java-pkg_announce-qa-violation "installing versioned jar '${jar}'"
	fi
}


java-pkg_announce-qa-violation() {
	local nodie
	if [[ ${1} == "--nodie" ]]; then
		nodie="true"
		shift
	fi
	echo "Java QA Notice: $@" >&2
	[[ -z "${nodie}" ]] && is-java-strict && die "${@}"
}

is-java-strict() {
	[[ -n ${JAVA_PKG_STRICT} ]]
	return $?
}

# @FUNCTION: java-pkg_clean
# @DESCRIPTION:
# Java package cleaner function. This will remove all *.class and *.jar
# files, removing any bundled dependencies. Set JAVA_PKG_NO_CLEAN to any
# value to override
# @CODE
# Parameters:
# $@ - arguments passed to find (optional)
# @CODE
java-pkg_clean() {
	debug-print-function ${FUNCNAME} "${@}"

	if [[ -z "${JAVA_PKG_NO_CLEAN}" ]]; then
		find "${@}" '(' -name '*.class' -o -name '*.jar' ')' \
			-type f -delete -print || die
	fi
}

# @FUNCTION: java-pkg_gen-cp
# @INTERNAL
# @DESCRIPTION:
# Java package generate classpath will create a classpath based on
# special variable CP_DEPEND in the ebuild.
#
# @CODE
# Parameters:
# $1 - classpath variable either JAVA_CLASSPATH or other
# @CODE
java-pkg_gen-cp() {
	debug-print-function ${FUNCNAME} "${@}"

	local atom
	for atom in ${CP_DEPEND}; do
		if [[ ${atom} =~ /(([[:alnum:]+_-]+)-[0-9]+(\.[0-9]+)*[a-z]?(_[[:alnum:]]+)?(_[[:alnum:]]+)?(-r[0-9]*)?|[[:alnum:]+_-]+):([[:alnum:]+_.-]+) ]]; then
			atom=${BASH_REMATCH[2]:-${BASH_REMATCH[1]}}
			[[ ${BASH_REMATCH[7]} != 0 ]] && atom+=-${BASH_REMATCH[7]}
			local regex="(^|\s|,)${atom}($|\s|,)"
			[[ ${!1} =~ ${regex} ]] || declare -g ${1}+=${!1:+,}${atom}
		else
			die "Invalid CP_DEPEND atom ${atom}, ensure a SLOT is included"
		fi
	done
}
