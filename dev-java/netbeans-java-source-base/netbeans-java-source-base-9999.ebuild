# Copyright 2017 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="6"
inherit java-netbeans

CP_DEPEND="
	dev-java/lucene-core:3
	~dev-java/netbeans-api-annotations-common-${PV}:${SLOT}
	~dev-java/netbeans-api-java-${PV}:${SLOT}
	~dev-java/netbeans-api-java-classpath-${PV}:${SLOT}
	~dev-java/netbeans-editor-mimelookup-${PV}:${SLOT}
	~dev-java/netbeans-editor-settings-${PV}:${SLOT}
	~dev-java/netbeans-java-lexer-${PV}:${SLOT}
	~dev-java/netbeans-lexer-${PV}:${SLOT}
	~dev-java/netbeans-openide-filesystems-${PV}:${SLOT}
	~dev-java/netbeans-openide-modules-${PV}:${SLOT}
	~dev-java/netbeans-openide-util-${PV}:${SLOT}
	~dev-java/netbeans-openide-util-lookup-${PV}:${SLOT}
	~dev-java/netbeans-parsing-api-${PV}:${SLOT}
	~dev-java/netbeans-parsing-lucene-${PV}:${SLOT}
	~dev-java/netbeans-projectapi-${PV}:${SLOT}
	~dev-java/netbeans-queries-${PV}:${SLOT}
"

DEPEND="${CP_DEPEND}
	>=virtual/jdk-9"

RDEPEND="${CP_DEPEND}
	>=virtual/jre-9"

JAVAC_ARGS+="--add-exports=jdk.javadoc/com.sun.tools.javadoc.main=ALL-UNNAMED "
JAVAC_ARGS+="--add-exports=jdk.compiler/com.sun.tools.javac=ALL-UNNAMED "
JAVAC_ARGS+="--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED "
JAVAC_ARGS+="--add-exports=jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED "
JAVAC_ARGS+="--add-exports=jdk.compiler/com.sun.tools.javac.comp=ALL-UNNAMED "
JAVAC_ARGS+="--add-exports=jdk.compiler/com.sun.tools.javac.jvm=ALL-UNNAMED "
JAVAC_ARGS+="--add-exports=jdk.compiler/com.sun.tools.javac.model=ALL-UNNAMED "
JAVAC_ARGS+="--add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED "
JAVAC_ARGS+="--add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED "
