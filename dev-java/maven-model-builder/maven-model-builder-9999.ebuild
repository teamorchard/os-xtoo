# Copyright 2018 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

JAVA_PKG_IUSE="doc source"

MY_PN="${PN%%-*}"
MY_PV="${PV}"
MY_P="${MY_PN}-${MY_PV}"
BASE_URI="https://github.com/apache/${MY_PN}"

if [[ ${PV} != 9999 ]]; then
	#SRC_URI="${BASE_URI}/archive/${MY_P}.tar.gz"
	SRC_URI="http://repo1.maven.org/maven2/org/apache/${MY_PN}/${PN}/${PV}/${P}-sources.jar"
	KEYWORDS="~amd64"
	MY_S="${MY_PN}-${MY_P}"
fi

SLOT="0"

CP_DEPEND="
	dev-java/commons-lang:3
	~dev-java/maven-artifact-${PV}:${SLOT}
	~dev-java/maven-builder-support-${PV}:${SLOT}
	~dev-java/maven-model-${PV}:${SLOT}
	dev-java/plexus-component-annotations:0
	dev-java/plexus-interpolation:0
	dev-java/plexus-utils:0
"

inherit java-pkg

DESCRIPTION="${PN//-/ }"
HOMEPAGE="https://maven.apache.org"
LICENSE="Apache-2.0"

DEPEND+=" dev-java/modello-plugin-java:0"

#S="${WORKDIR}/${MY_S}/${PN}"

#java_prepare() {
#	modello "src/main/mdo/profiles.mdo" java src/main/java \
#		4.0.0 false true \
#		|| die "Failed to generate .java files via modello cli"
#}
