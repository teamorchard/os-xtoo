# Copyright 2018 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

inherit java-netbeans

CP_DEPEND="
	~dev-java/netbeans-api-annotations-common-${PV}:${SLOT}
	~dev-java/netbeans-api-java-${PV}:${SLOT}
	~dev-java/netbeans-api-java-classpath-${PV}:${SLOT}
	~dev-java/netbeans-api-progress-${PV}:${SLOT}
	~dev-java/netbeans-api-progress-nb-${PV}:${SLOT}
	~dev-java/netbeans-editor-${PV}:${SLOT}
	~dev-java/netbeans-editor-bracesmatching-${PV}:${SLOT}
	~dev-java/netbeans-editor-codetemplates-${PV}:${SLOT}
	~dev-java/netbeans-editor-completion-${PV}:${SLOT}
	~dev-java/netbeans-editor-document-${PV}:${SLOT}
	~dev-java/netbeans-editor-errorstripe-${PV}:${SLOT}
	~dev-java/netbeans-editor-fold-${PV}:${SLOT}
	~dev-java/netbeans-editor-indent-${PV}:${SLOT}
	~dev-java/netbeans-editor-lib-${PV}:${SLOT}
	~dev-java/netbeans-editor-lib2-${PV}:${SLOT}
	~dev-java/netbeans-editor-mimelookup-${PV}:${SLOT}
	~dev-java/netbeans-editor-settings-${PV}:${SLOT}
	~dev-java/netbeans-editor-util-${PV}:${SLOT}
	~dev-java/netbeans-java-completion-${PV}:${SLOT}
	~dev-java/netbeans-java-editor-base-${PV}:${SLOT}
	~dev-java/netbeans-java-editor-lib-${PV}:${SLOT}
	~dev-java/netbeans-java-lexer-${PV}:${SLOT}
	~dev-java/netbeans-java-preprocessorbridge-${PV}:${SLOT}
	~dev-java/netbeans-java-source-${PV}:${SLOT}
	~dev-java/netbeans-java-source-base-${PV}:${SLOT}
	~dev-java/netbeans-java-sourceui-${PV}:${SLOT}
	~dev-java/netbeans-lexer-${PV}:${SLOT}
	~dev-java/netbeans-o-n-swing-plaf-${PV}:${SLOT}
	~dev-java/netbeans-openide-awt-${PV}:${SLOT}
	~dev-java/netbeans-openide-dialogs-${PV}:${SLOT}
	~dev-java/netbeans-openide-explorer-${PV}:${SLOT}
	~dev-java/netbeans-openide-filesystems-${PV}:${SLOT}
	~dev-java/netbeans-openide-loaders-${PV}:${SLOT}
	~dev-java/netbeans-openide-nodes-${PV}:${SLOT}
	~dev-java/netbeans-openide-text-${PV}:${SLOT}
	~dev-java/netbeans-openide-util-${PV}:${SLOT}
	~dev-java/netbeans-openide-util-lookup-${PV}:${SLOT}
	~dev-java/netbeans-openide-util-ui-${PV}:${SLOT}
	~dev-java/netbeans-openide-windows-${PV}:${SLOT}
	~dev-java/netbeans-options-api-${PV}:${SLOT}
	~dev-java/netbeans-options-editor-${PV}:${SLOT}
	~dev-java/netbeans-parsing-api-${PV}:${SLOT}
	~dev-java/netbeans-projectapi-${PV}:${SLOT}
	~dev-java/netbeans-refactoring-api-${PV}:${SLOT}
	~dev-java/netbeans-refactoring-java-${PV}:${SLOT}
	~dev-java/netbeans-settings-${PV}:${SLOT}
	~dev-java/netbeans-spi-editor-hints-${PV}:${SLOT}
	~dev-java/netbeans-spi-tasklist-${PV}:${SLOT}
	~dev-java/netbeans-whitelist-${PV}:${SLOT}
"

DEPEND="${CP_DEPEND}
	>=virtual/jdk-9"

RDEPEND="${CP_DEPEND}
	>=virtual/jre-9"
