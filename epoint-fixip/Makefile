include $(TOPDIR)/rules.mk

PKG_NAME:=epoint-fixip
PKG_VERSION:=0.1
PKG_RELEASE:=4

include $(INCLUDE_DIR)/package.mk

define Package/epoint-fixip
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Fixed IP VPN for ePoint public Wi-Fi networks
  MAINTAINER:=ePoint Systems Ltd <info@epointsystem.org>
  DEPENDS:=+lua +epoint
endef

define Package/epoint-fixip/description
 Fixed IP VPN for ePoint public Wi-Fi networks
endef

define Package/epoint-fixip/conffiles
/etc/tariffs-fixip
endef

define Package/epoint-fixip/install
	tar c -C ./files . --exclude .svn --exclude '*~' | tar x -C $(1)
	$(INSTALL_DIR) $(1)/usr/lib/lua
	tar c -C ./luasrc . --exclude .svn --exclude '*~' | tar x -C $(1)/usr/lib/lua
endef

define Build/Compile
endef

$(eval $(call BuildPackage,epoint-fixip))
