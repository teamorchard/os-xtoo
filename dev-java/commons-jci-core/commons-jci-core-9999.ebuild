# Copyright 2017-2018 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

JAVA_PKG_IUSE="doc source"
JAVA_NO_COMMONS=1

MY_PN="${PN:0:11}"
MY_PV="${PV}"
MY_P="${MY_PN}-${MY_PV}"
BASE_URI="https://github.com/apache/${MY_PN}"

if [[ ${PV} != *9999* ]]; then
	SRC_URI="${BASE_URI}/archive/${PV}.tar.gz -> ${MY_P}.tar.gz"
	MY_S="${MY_P}"
fi
SLOT="0"

CP_DEPEND="
	dev-java/commons-logging:0
	dev-java/commons-io:0
	~dev-java/commons-jci-fam-${PV}:${SLOT}
"

inherit java-pkg

DESCRIPTION="A java compiler interface - ${PN:12}"
HOMEPAGE="https://commons.apache.org/proper/${PN}/"
LICENSE="Apache-2.0"

S="${WORKDIR}/${MY_S}/${PN:12}"
