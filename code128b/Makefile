include $(TOPDIR)/rules.mk

PKG_NAME:=code128b
PKG_VERSION:=0.2
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/code128b
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Barcode to png encoder for CODE128B
  MAINTAINER:=ePoint Systems Ltd <info@epointsystem.org>
  DEPENDS:=+libpng
endef

define Package/code128b/description
 Barcode to png encoder for CODE128B
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	make -C ./src clean
	$(CP) ./src/* $(PKG_BUILD_DIR)
endef

define Package/code128b/install
	mkdir -p $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/code128b $(1)/usr/bin/
endef

$(eval $(call BuildPackage,code128b))
