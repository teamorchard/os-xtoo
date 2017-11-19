# Copyright 2017 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

JAVA_PKG_IUSE="doc source"

MY_PN="${PN%%-*}-java"
MY_PV="${PV}"
MY_P="${MY_PN}-${MY_PV}"
BASE_URI="https://github.com/hamcrest/JavaHamcrest"

if [[ ${PV} == 9999 ]]; then
	ECLASS="git-r3"
	EGIT_REPO_URI="${BASE_URI}.git"
	MY_S="${P}"
else
	SRC_URI="${BASE_URI}/archive/${MY_P}.tar.gz"
	KEYWORDS="~amd64"
	MY_S="JavaHamcrest-${MY_P}"
fi

inherit java-pkg-2 java-pkg-simple ${ECLASS}

DESCRIPTION="Library of matchers for building test expressions"
HOMEPAGE="https://hamcrest.org/JavaHamcrest/"
LICENSE="BSD-3-clause"
SLOT="${PV%%.*}"

CP_DEPEND="~dev-java/hamcrest-core-${PV}:${SLOT}"

DEPEND="${CP_DEPEND}
	>=virtual/jdk-1.7"

RDEPEND="${CP_DEPEND}
	>=virtual/jre-1.7"

S="${WORKDIR}/${MY_S}/${PN}"
