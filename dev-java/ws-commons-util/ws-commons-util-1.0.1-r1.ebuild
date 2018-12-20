# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

JAVA_PKG_IUSE="source doc"

inherit java-pkg java-pkg-simple

DESCRIPTION="Utility classes that allow high performance XML processing based on SAX"
HOMEPAGE="http://ws.apache.org/commons/util/"
SRC_URI="mirror://apache/ws/commons/util/sources/${P}-src.tar.gz"
LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 ~ppc64 x86"
IUSE=""

DEPEND=">=virtual/jdk-9"
RDEPEND=">=virtual/jre-9"

JAVA_SRC_DIR="src"

java_prepare() {
	mv "${S}"/"${P}"/src . || die
	rm -rf "${S}"/"${P}" src/test || die
}