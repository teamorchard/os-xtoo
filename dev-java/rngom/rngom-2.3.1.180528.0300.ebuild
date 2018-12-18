# Copyright 2017-2018 Obsidian-Studios, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

JAVA_PKG_IUSE="doc source"

MY_PN="jaxb-v2"
MY_PV="${PV/.18/-b18}"
MY_P="${MY_PN}-${MY_PV}"
BASE_URI="https://github.com/javaee/${MY_PN}"

if [[ ${PV} != *9999* ]]; then
	SRC_URI="${BASE_URI}/archive/${MY_PV}.tar.gz -> ${MY_P}.tar.gz"
	MY_S="${MY_P}"
fi

CP_DEPEND="dev-java/relaxng-datatype-java:0"

inherit java-pkg

DESCRIPTION="RNGOM is a RelaxNG Object model library (XSOM for RelaxNG)."
HOMEPAGE="${BASE_URI}"
LICENSE="|| ( CDDL GPL-2-with-classpath-exception )"
SLOT="0"

S="${WORKDIR}/${MY_S}/jaxb-ri/external/${PN}/"

JAVA_RM_FILES=( src/main/java/module-info.java )