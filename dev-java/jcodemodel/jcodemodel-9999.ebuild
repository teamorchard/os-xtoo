# Copyright 2017-2018 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

JAVA_PKG_IUSE="doc source"

BASE_URI="https://github.com/phax/${PN}"

if [[ ${PV} != *9999* ]]; then
	SRC_URI="${BASE_URI}/archive/${P}.tar.gz"
	MY_S="${PN}-${P}"
fi

CP_DEPEND="
	dev-java/jsr305:0
	dev-java/spotbugs-annotations:0
"

inherit java-pkg

DESCRIPTION="A fork of the com.sun.codemodel"
HOMEPAGE="${BASE_URI}"
LICENSE="CDDL GPL-2"
SLOT="0"

S="${WORKDIR}/${MY_S}"
