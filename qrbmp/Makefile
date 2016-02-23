include $(TOPDIR)/rules.mk

PKG_NAME:=qrbmp
PKG_VERSION:=0.1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/qrbmp
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=QR code to Windows bitmap (bmp) encoder
  MAINTAINER:=ePoint Systems Ltd <info@epointsystem.org>
  DEPENDS:=+qrencode
endef

define Package/qrbmp/description
  QR code to Windows bitmap (bmp) encoder
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	make -C ./src clean
	$(CP) ./src/* $(PKG_BUILD_DIR)
endef

define Package/qrbmp/install
	mkdir -p $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/qrbmp $(1)/usr/bin/
endef

$(eval $(call BuildPackage,qrbmp))
