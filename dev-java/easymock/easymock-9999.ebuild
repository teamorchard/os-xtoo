# Copyright 2017-2018 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

JAVA_PKG_IUSE="doc source"

BASE_URI="https://github.com/${PN}/${PN}"

if [[ ${PV} != *9999* ]]; then
	SRC_URI="${BASE_URI}/archive/${P}.tar.gz"
	KEYWORDS="~amd64"
	MY_S="${PN}-${P}"
fi

inherit java-pkg

DESCRIPTION="Mocking easier"
HOMEPAGE="http://easymock.org"
LICENSE="Apache-2.0"
SLOT="0"

#	dev-java/dexmaker:0
CP_DEPEND="
	dev-java/cglib:3
	dev-java/junit:4
	dev-java/objenesis:2
	dev-java/testng:0
"

DEPEND="${CP_DEPEND}
	>=virtual/jdk-9"

RDEPEND="${CP_DEPEND}
	>=virtual/jre-9"

S="${WORKDIR}/${MY_S}/core"

# need to package org.droidparts.dexmaker.stock.ProxyBuilder
JAVA_RM_FILES=( src/main/java/org/easymock/internal/AndroidClassProxyFactory.java )

java_prepare(){
	sed -i -e '150,154d' \
		src/main/java/org/easymock/internal/MocksControl.java \
		|| die "Failed to sed remove AndroidClassProxyFactory usage"
}
