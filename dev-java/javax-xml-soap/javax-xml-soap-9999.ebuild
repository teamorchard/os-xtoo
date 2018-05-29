# Copyright 2018 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

JAVA_PKG_IUSE="doc source"

MY_PN="${PN//-/.}"
MY_PV="${PV}"
MY_P="${MY_PN}-${MY_PV}"
BASE_URI="https://github.com/javaee/${MY_PN}"

if [[ ${PV} != 9999 ]]; then
	SRC_URI="${BASE_URI}/archive/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64"
	MY_S="${MY_P}"
fi

CP_DEPEND="dev-java/javax-activation:0"

inherit java-pkg

DESCRIPTION="SAAJ API"
HOMEPAGE="${BASE_URI}"
LICENSE="CDDL GPL-2-with-classpath-exception"
SLOT="0"

S="${WORKDIR}/${MY_S}"
