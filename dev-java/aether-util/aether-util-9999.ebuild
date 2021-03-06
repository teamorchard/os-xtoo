# Copyright 2018 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

JAVA_PKG_IUSE="doc source"

MY_PN="${PN%%-*}"
MY_PV="${PV/201/v201}"
MY_P="${MY_PN}-${MY_PV}"

BASE_URI="https://github.com/eclipse/${MY_PN}-core"

if [[ ${PV} != *9999* ]]; then
	SRC_URI="${BASE_URI}/archive/${MY_P}.tar.gz"
	MY_S="${MY_PN}-core-${MY_P}"
fi

SLOT="0"

CP_DEPEND="~dev-java/aether-api-${PV}:${SLOT}"

inherit java-pkg

DESCRIPTION="A collection of utility classes to ease usage of the repository system."
HOMEPAGE="https://www.eclipse.org/aether/"
LICENSE="EPL-1.0"

S="${WORKDIR}/${MY_S}/${PN}"
