# Copyright 2016-2018 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

JAVA_PKG_IUSE="doc source"

MY_PN="mongo-java-driver"
MY_P="${MY_PN}-r${PV}"

BASE_URI="https://github.com/${PN##*-}/${MY_PN}"

if [[ ${PV} != *9999* ]]; then
	SRC_URI="${BASE_URI}/archive/r${PV}.tar.gz -> ${MY_P}.tar.gz"
	KEYWORDS="~amd64"
	MY_S="${MY_P}"
fi

inherit java-pkg

DESCRIPTION="MongoDB Java Driver Core"
HOMEPAGE="https://mongodb.github.io/${MY_PN}/"
LICENSE="Apache-2.0"
SLOT="${PV%%.*}"

NETTY_SLOT="4.1"

CP_DEPEND="
	~dev-java/bson-${PV}:${SLOT}
	dev-java/jnr-enxio:0
	dev-java/jnr-unixsocket:0
	dev-java/jsr305:0
	dev-java/netty-buffer:${NETTY_SLOT}
	dev-java/netty-common:${NETTY_SLOT}
	dev-java/netty-codec:${NETTY_SLOT}
	dev-java/netty-handler:${NETTY_SLOT}
	dev-java/netty-transport:${NETTY_SLOT}
	dev-java/slf4j-api:0
	dev-java/snappy-java:0
"

RDEPEND="${CP_DEPEND}
	>=virtual/jre-9"

DEPEND="${CP_DEPEND}
	>=virtual/jdk-9"

S="${WORKDIR}/${MY_S}/${PN#*-}"
