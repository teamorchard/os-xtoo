# Copyright 2017 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

JAVA_PKG_IUSE="doc source"

MY_PN="${PN%*-*}"
MY_PN="${MY_PN//-/.}"
MY_PV="${PV/_/-}"
MY_P="${MY_PN}-${MY_PV}"
BASE_URI="https://github.com/javaee/${MY_PN}"

if [[ ${PV} == 9999 ]]; then
	ECLASS="git-r3"
	EGIT_REPO_URI="${BASE_URI}.git"
	MY_S="${P}"
else
	SRC_URI="${BASE_URI}/archive/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64"
	MY_S="${MY_P}"
fi

inherit java-pkg-2 java-pkg-simple ${ECLASS}

DESCRIPTION="Project GlassFish Enterprise XML RPC API"
HOMEPAGE="${BASE_URI}"
LICENSE="CDDL GPL-2-with-classpath-exception"
SLOT="0"

CP_DEPEND="dev-java/tomcat-servlet-api:4.0"

DEPEND="${CP_DEPEND}
	>=virtual/jdk-9"

RDEPEND="${CP_DEPEND}
	>=virtual/jre-9"

S="${WORKDIR}/${MY_S}"

JAVAC_ARGS+=" --add-modules=java.xml.ws "
