#
# Copyright (C) 2009 ePoint Systems Ltd.
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk

PKG_NAME:=qrencode
PKG_VERSION:=3.0.3
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
PKG_SOURCE_URL:=http://megaui.net/fukuchi/works/qrencode/
PKG_MD5SUM:=413e126aa8d1b1fdd1f65cfa43e0bf4b

include $(INCLUDE_DIR)/package.mk

define Package/qrencode
  SECTION:=libs
  CATEGORY:=Libraries
  DEPENDS:=+libpng
  TITLE:=QRcode encoder library
  URL:=http://megaui.net/fukuchi/works/qrencode/index.en.html
endef

define Package/qrencode/description
	Libqrencode is a C library for encodingdata in a QR Code symbol, a
	kind of 2D symbology that can be scanned by handy terminals such as
	a mobile phone with CCD. The capacity of QR Code is up to 7000
	digits or 4000 characters, and is highly robust.
endef

define Build/Configure
	$(call Build/Configure/Default, \
	                --enable-shared \
                        --enable-static \
                            --without-tests, \
			LDFLAGS="-nodefaultlibs -L$(STAGING_DIR)/usr/lib -L$(STAGING_DIR)/lib -lpng -lz" \
	)                                       
endef

TARGET_CFLAGS += $(FPIC)

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
        	DESTDIR="$(PKG_INSTALL_DIR)" \
		all install
endef

define Build/InstallDev
	mkdir -p $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/qrencode.h $(1)/usr/include/
	mkdir -p $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libqrencode.{a,so*} $(1)/usr/lib/
	mkdir -p $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/qrencode $(1)/usr/bin/
	$(SED) 's,-I$$$${prefix}/include,,g' $(1)/usr/bin/qrencode
	$(SED) 's,-L$$$${exec_prefix}/lib,,g' $(1)/usr/bin/qrencode
endef                                                                

define Package/qrencode/install	
	$(INSTALL_DIR) $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/* $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/usr/lib/
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/*.so* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,qrencode))
