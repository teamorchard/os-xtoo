# Copyright 2018 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

SLOT="0"

CP_DEPEND="
	dev-java/commons-io:0
	dev-java/commons-lang:2
	~dev-java/gradle-base-services-${PV}:${SLOT}
	~dev-java/gradle-core-${PV}:${SLOT}
	~dev-java/gradle-core-api-${PV}:${SLOT}
	~dev-java/gradle-model-core-${PV}:${SLOT}
	~dev-java/gradle-resources-${PV}:${SLOT}
	dev-java/guava:27
	dev-java/httpcomponents-core:4.4
	dev-java/httpcomponents-client:4.5
	dev-java/jcifs:0
	dev-java/jsr305:0
	dev-java/nekohtml:0
	dev-java/slf4j-api:0
	dev-java/xerces:2
"

inherit gradle
