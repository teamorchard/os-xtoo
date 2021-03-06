# Copyright 2018 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

JAVA_PKG_IUSE="doc source"

MY_PN="checker-framework"
MY_PV="${PV}"
MY_P="${MY_PN}-${MY_PV}"
BASE_URI="https://github.com/typetools/${MY_PN}"

if [[ ${PV} != *9999* ]]; then
	SRC_URI="${BASE_URI}/archive/${MY_P}.tar.gz"
	MY_S="${MY_PN}-${MY_P}"
fi

SLOT="0"

CP_DEPEND="~dev-java/checker-qual-${PV}:${SLOT}"

inherit java-pkg

DESCRIPTION="Pluggable type-checking framework - ${PN##*-}"
HOMEPAGE="https://${MY_PN/-/}.org/"
LICENSE="Apache-2.0"

S="${WORKDIR}/${MY_S}/${PN##*-}"

JAVAC_ARGS+=" --add-exports=jdk.compiler/com.sun.tools.javac=ALL-UNNAMED "
JAVAC_ARGS+=" --add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED "
JAVAC_ARGS+=" --add-exports=jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED "
JAVAC_ARGS+=" --add-exports=jdk.compiler/com.sun.tools.javac.code.Kinds=ALL-UNNAMED "
JAVAC_ARGS+=" --add-exports=jdk.compiler/com.sun.tools.javac.comp=ALL-UNNAMED "
JAVAC_ARGS+=" --add-exports=jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED "
JAVAC_ARGS+=" --add-exports=jdk.compiler/com.sun.tools.javac.model=ALL-UNNAMED "
JAVAC_ARGS+=" --add-exports=jdk.compiler/com.sun.tools.javac.processing=ALL-UNNAMED "
JAVAC_ARGS+=" --add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED "
JAVAC_ARGS+=" --add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED "

PATCHES=( "${FILESDIR}/TypeAnnotationUtils-9+.patch" )

java_prepare() {
	sed -i -e "s|Kinds\.|Kind\.|g" \
		-e "s|code\.Kinds|code.Kinds.Kind|" \
		src/main/java/org/checkerframework/javacutil/Resolver.java \
		|| die "Failed to sed/change java 9+ imports"
}
