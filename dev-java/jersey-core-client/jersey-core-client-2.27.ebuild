# Copyright 2016-2018 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

JAVA_PKG_IUSE="doc source"

MY_PN="${PN%%-*}"
MY_PV="${PV/_beta/-b}"
MY_P="${MY_PN}-${MY_PV}"

BASE_URI="https://github.com/${MY_PN}/${MY_PN}"

if [[ ${PV} != *9999* ]]; then
	SRC_URI="${BASE_URI}/archive/${PV}.tar.gz -> ${MY_P}.tar.gz"
	MY_S="${PN}-${MY_P}"
fi

SLOT="${PV%%.*}"

CP_DEPEND="
	dev-java/javax-inject:0
	dev-java/jax-rs:2
	dev-java/jax-rs:2.1
	~dev-java/jersey-core-common-${PV}:${SLOT}
	dev-java/javax-annotation:0
"

inherit java-pkg

DESCRIPTION="Jersey RESTful Web Services in Java Core Client"
HOMEPAGE="https://jersey.github.io/"
LICENSE="CDDL GPL-2-with-linking-exception"

DEPEND+=" dev-java/istack-commons-buildtools:0"

S="${WORKDIR}/${MY_P}/${PN#*-*}"

java_prepare() {
	# Generate LocalizationMessages
	istack-cli -b "src/main/resources/" -d "src/main/java/" \
		-r "**/localization.properties" \
		-p "org.glassfish.jersey.internal.l10n" \
		|| die "Failed to generate java files from resources"

	sed -i -e '484d;476d' \
		src/main/java/org/glassfish/jersey/client/JerseyInvocation.java \
		|| die "Could not remove @Override"

	sed -i -e '171d;161d;155d;149d' \
		src/main/java/org/glassfish/jersey/client/JerseyClientBuilder.java \
		|| die "Could not remove @Override"
}