# Copyright 2017 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

JAVA_PKG_IUSE="doc source"

BASE_URI="https://github.com/FasterXML/${PN}"

if [[ ${PV} == 9999 ]]; then
	ECLASS="git-r3"
	EGIT_REPO_URI="${BASE_URI}.git"
	MY_S="${P}"
else
	SRC_URI="${BASE_URI}/archive/${P}.tar.gz"
	KEYWORDS="~amd64"
	MY_S="${PN}-${P}"
fi

inherit java-pkg-2 java-pkg-simple ${ECLASS}

DESCRIPTION="Extension API for Stax, Java pull-parsing API (STreaming Api for Xml)"
HOMEPAGE="${BASE_URI}"
LICENSE="BSD"
SLOT="0"

DEPEND=">=virtual/jdk-9"
RDEPEND=">=virtual/jre-9"

S="${WORKDIR}/${MY_S}"
