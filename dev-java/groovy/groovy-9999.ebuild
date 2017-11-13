# Copyright 2017 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

# Original work Copyright 1999-2016 Gentoo Foundation

EAPI="6"

JAVA_PKG_IUSE="doc source"

MY_PN="${PN^^}"
MY_PV="${PV//./_}"
MY_P="${MY_PN}_${MY_PV}"
BASE_URI="https://github.com/apache/${PN}"

if [[ ${PV} == 9999 ]]; then
	ECLASS="git-r3"
	EGIT_REPO_URI="${BASE_URI}.git"
	MY_S="${P}"
else
	SRC_URI="${BASE_URI}/archive/${MY_P}.tar.gz"
#	SRC_URI="mirror://apache/${PN}/${PV}/sources/apache-${PN}-src-${PV}.zip -> ${P}.zip"
	KEYWORDS="~amd64"
	MY_S="${PN}-${MY_P}"
#	MY_S="${P}"
fi

inherit java-pkg-2 java-pkg-simple ${ECLASS}

DESCRIPTION="A multi-faceted language for the Java platform"
HOMEPAGE="https://www.groovy-lang.org/"
LICENSE="Apache-2.0"
SLOT="0"

CP_DEPEND="
	dev-java/ant-ivy:0
	>=dev-java/antlr-2.7.7-r7:0
	dev-java/asm:5
	dev-java/commons-cli:1
	dev-java/jansi:0
	dev-java/xstream:0
"

DEPEND="app-arch/unzip
	${CP_DEPEND}
	>=virtual/jdk-1.7"

RDEPEND="${CP_DEPEND}
	>=virtual/jre-1.7"

S="${WORKDIR}/${MY_S}"

JAVA_SRC_DIR="src/main"
JAVA_RES_DIR="resources"

# Add to the cp as we're generating an extra class there.
JAVA_GENTOO_CLASSPATH_EXTRA="${JAVA_RES_DIR}"

# ExceptionUtil filename.
EU="ExceptionUtils.java"

ANTLR_GRAMMAR_FILES=(
	org/codehaus/groovy/antlr/groovy.g
	org/codehaus/groovy/antlr/java/java.g
)

# Patches utils.gradle. It basically rewrites ExceptionUtils.
PATCHES=(
	"${FILESDIR}/utils.gradle.patch"
)

# This function generates the ANTLR grammar files.
generate_antlr_grammar() {
	for grammar_file in "${@}"; do
		local my_grammar_file=$(basename ${grammar_file})

		einfo "Generating \"${my_grammar_file}\" grammar file"
		local my_grammar_dir=$(dirname ${grammar_file})

		cd "${S}/src/main/${my_grammar_dir}" || die
		antlr ${my_grammar_file} || die

		cd "${S}" || die
	done
}

# This function generates ExceptionUtils.class.
# ExceptionUtils is a helper class needed when compiling Groovy 2.x.
# Normally, this class is generated via a Gradle task at compile time. Since we
# don't use Gradle here.. we've translated it into a plain Java file and have
# it generate the same data.
generate_exceptionutils() {
	local tmpdir
	tmpdir="org/codehaus/groovy/runtime"
	mkdir -p "${JAVA_RES_DIR}/${tmpdir}" || die "Failed to create dir"

	# rename to .java
	mv "gradle/utils.gradle" "${EU}" \
		|| die "Failed to rename/move utils.gradle -> ${EU}"

	einfo "Compile ${EU%.java}"
	ejavac -cp "$(java-pkg_getjars asm-5)" "${EU}"

	einfo "Run ${EU%.java}"
	java -cp ".:$(java-pkg_getjars asm-5)" "${EU%.java}" \
		|| die "Failed to run ${EU%.java}"

	mv "${JAVA_SRC_DIR}/${tmpdir}/${EU%.java}.class" \
		"${JAVA_RES_DIR}/${tmpdir}" \
		|| die "Failed to move generated ${EU%.java}.class"

	mv "${JAVA_SRC_DIR}/META-INF" "${JAVA_RES_DIR}" \
		|| die "Failed to move META-INF"
}

src_compile() {
	generate_antlr_grammar "${ANTLR_GRAMMAR_FILES[@]}"
	generate_exceptionutils
	java-pkg-simple_src_compile

	# Temp needs to be moved to groovy eclass
	local sources classes
	sources=groovy_sources.lst
	classes=target/groovy_classes
	find "${S}/src/main" -name \*.groovy > ${sources}
	sed -i -e "s|\$GROOVY_HOME/lib/@GROOVYJAR@|${S}/${PN}.jar:$(java-pkg_getjars antlr,asm-5,commons-cli-1)|" \
		"src/bin/startGroovy" \
		|| die "Could not modify startGroovy"
	chmod 775 "src/bin/groovyc" "src/bin/startGroovy"\
		|| die "Failed to make groovyc,startGroovy executable"
	"src/bin/groovyc" -d ${classes} \
		-cp "${PN}.jar:$(java-pkg_getjars ant-ivy-2,commons-cli-1)" \
		@${sources} \
		|| die "Failed to compile groovy files"
	# ugly should be included with existing
	jar uf ${PN}.jar -C ${classes} . || die "update jar failed"

	# revert modifications
	sed -i -e "s|${S}/${PN}.jar.*|\$GROOVY_HOME/lib/@GROOVYJAR@|" \
		"src/bin/startGroovy" \
		|| die "Could not revert startGroovy"

}

src_install() {
	java-pkg_dolauncher "groovyc" --main org.codehaus.groovy.tools.FileSystemCompiler
	java-pkg_dolauncher "groovy" --main groovy.ui.GroovyMain
	java-pkg-simple_src_install
}
