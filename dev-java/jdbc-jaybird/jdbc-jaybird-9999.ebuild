# Copyright 2017-2018 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

JAVA_PKG_IUSE="doc source"

MY_PN="${PN/jdbc-/}"
MY_PV="${PV/_/-}"
MY_PV="${MY_PV/beta/beta-}"
MY_P="${MY_PN}-${MY_PV}"

BASE_URI="https://github.com/FirebirdSQL/${MY_PN}"

if [[ ${PV} == 9999 ]]; then
	ECLASS="git-r3"
	EGIT_REPO_URI="${BASE_URI}.git"
	MY_S="${P}"
else
	SRC_URI="${BASE_URI}/archive/v${MY_PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64"
	MY_S="${MY_P}"
fi

inherit java-pkg-2 java-pkg-simple ${ECLASS}

DESCRIPTION="JDBC Type 4 driver for Firebird SQL server"
HOMEPAGE="https://jaybirdwiki.firebirdsql.org/"
LICENSE="LGPL-2"
SLOT="0"

CP_DEPEND="
	dev-java/antlr:4
	dev-java/jna:4
	dev-java/javax-resource:0
"

DEPEND="${CP_DEPEND}
	>=virtual/jdk-9"

RDEPEND="${CP_DEPEND}
	>=virtual/jre-9"

S="${WORKDIR}/${MY_S}"

JAVA_SRC_DIR="
	src/jdbc_42
	src/jna-client
	src/main
"
JAVA_RES_DIR="src/resources"

src_install() {
	java-pkg-simple_src_install
	dosym ../../../../usr/share/${PN}/lib/${PN}.jar \
		/usr/share/${PN}/lib/${MY_PN}-full.jar
}
