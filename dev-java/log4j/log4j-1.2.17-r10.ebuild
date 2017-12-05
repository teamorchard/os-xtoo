# Copyright 2017 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

JAVA_PKG_IUSE="doc source"

inherit java-pkg-2 java-pkg-simple ${ECLASS}

DESCRIPTION="Java-based logging utility"
HOMEPAGE="https://logging.apache.org/log4j/"
SRC_URI="https://archive.apache.org/dist/logging/${PN}/${PV}/${P}.tar.gz"
LICENSE="Apache-2.0"
KEYWORDS="~amd64"
SLOT="0"

CP_DEPEND="
	dev-java/glassfish-jms-api:0
	dev-java/javamail:0
"

DEPEND="${CP_DEPEND}
	>=virtual/jdk-9"

RDEPEND="${CP_DEPEND}
	>=virtual/jre-9"

S="${WORKDIR}/apache-${P}"
