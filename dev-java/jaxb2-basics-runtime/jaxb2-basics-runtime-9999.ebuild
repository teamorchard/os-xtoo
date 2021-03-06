# Copyright 2017-2018 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

JAVA_PKG_IUSE="doc source"

MY_PN="${PN%-*}"
MY_PV="${PV}"
MY_P="${MY_PN}-${MY_PV}"
BASE_URI="https://github.com/highsource/${MY_PN}"

if [[ ${PV} != *9999* ]]; then
	SRC_URI="${BASE_URI}/archive/${PV}.tar.gz -> ${MY_P}.tar.gz"
	MY_S="${MY_P}"
fi

CP_DEPEND="
	dev-java/javax-activation:0
	dev-java/jaxb-api:0
	dev-java/jaxb-runtime:0
"

inherit java-pkg

DESCRIPTION="Useful plugins and tools for JAXB2"
HOMEPAGE="${BASE_URI}"
LICENSE="BSD-2-clause"
SLOT="0"

S="${WORKDIR}/${MY_S}/${PN##*-}"
