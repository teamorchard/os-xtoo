# Copyright 2017-2018 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

MY_PN="${PN%%-*}"
MY_PV="${PV}"
MY_P="${MY_PN}-${MY_PV}"

JAVA_PKG_IUSE="doc source"

BASE_URI="https://github.com/codehaus-plexus/${MY_PN}"

if [[ ${PV} != *9999* ]]; then
	SRC_URI="${BASE_URI}/archive/${MY_P}.tar.gz"
	MY_S="${MY_PN}-${MY_P}"
fi

SLOT="0"

CP_DEPEND="
	~dev-java/modello-core-${PV}:${SLOT}
	dev-java/plexus-build-api:0
	dev-java/plexus-utils:0
	dev-java/sisu-plexus:0
"

inherit java-pkg

DESCRIPTION="Modello plugin java"
HOMEPAGE="http://codehaus-plexus.github.io/modello/"
LICENSE="MIT"

S="${WORKDIR}/${MY_S}/${PN%-*}s/${PN}"
