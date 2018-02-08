# Copyright 2016-2018 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

JAVA_PKG_IUSE="doc source"

MY_P="${P/_/-}"

BASE_URI="https://github.com/google/auto/"

if [[ ${PV} != *9999* ]]; then
	SRC_URI="${BASE_URI}/archive/${MY_P}.tar.gz"
	KEYWORDS="~amd64"
	MY_S="auto-${MY_P}"
fi

inherit java-pkg

DESCRIPTION="A configuration/metadata generator for service providers"
HOMEPAGE="${BASE_URI}"
LICENSE="Apache-2.0"
SLOT="0"

CP_DEPEND="
	dev-java/auto-common:0
	dev-java/guava:23
"

DEPEND="
	${CP_DEPEND}
	>=virtual/jdk-9"

RDEPEND="${CP_DEPEND}
	>=virtual/jre-9"

S="${WORKDIR}/${MY_S}/${PN##*-}/"
