# Copyright 2017 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

JAVA_PKG_IUSE="doc source"

MY_PN="REL"
MY_PV="${PV//./_}"
MY_PV="${MY_PV^^}"
MY_P="${MY_PN}_${MY_PV}"
[[ ${PV} != *beta* ]] && MY_P+="_FINAL"
BASE_URI="https://github.com/apache/${PN:0:3}"

if [[ ${PV} == 9999 ]]; then
	ECLASS="git-r3"
	EGIT_REPO_URI="${BASE_URI}.git"
	MY_S="${P}"
else
	SRC_URI="${BASE_URI}/archive/${MY_P}.tar.gz"
	KEYWORDS="~amd64"
	MY_S="${PN:0:3}-${MY_P}"
fi

inherit java-pkg-2 java-pkg-simple ${ECLASS}

DESCRIPTION="Java API for Microsoft Documents"
HOMEPAGE="https://poi.apache.org/"
LICENSE="Apache-2.0"
SLOT="0"

CP_DEPEND="~dev-java/poi-${PV}:${SLOT}"

DEPEND="${CP_DEPEND}
	>=virtual/jdk-1.8"

RDEPEND="${CP_DEPEND}
	>=virtual/jre-1.8"

S="${WORKDIR}/${MY_S}/src/${PN#*-*-}"

JAVA_SRC_DIR="src"
