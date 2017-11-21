# Copyright 2016-2017 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

JAVA_PKG_IUSE="doc source"

MY_PN="${PN%%-*}"
HOMEPAGE="https://github.com/ning/${MY_PN}"

if [[ ${PV} == 9999 ]]; then
	ECLASS="git-r3"
	EGIT_REPO_URI="${HOMEPAGE}.git"
	MY_S="${P}"
else
	SRC_URI="${HOMEPAGE}/archive/${P}.tar.gz"
	KEYWORDS="~amd64"
	MY_S="${MY_PN}-${P}"
fi

inherit java-pkg-2 java-pkg-simple ${ECLASS}

DESCRIPTION="High-performance, streaming/chunking Java LZF codec"
LICENSE="Apache-2.0"
SLOT="0"

RDEPEND=">=virtual/jre-9"

DEPEND=">=virtual/jdk-9"

S="${WORKDIR}/${MY_S}/"

JAVAC_ARGS="--add-exports jdk.unsupported/sun.misc=ALL-UNNAMED"
