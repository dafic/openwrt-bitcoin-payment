include $(TOPDIR)/rules.mk

PKG_NAME:=coinspot
PKG_VERSION:=1
PKG_RELEASE=$(PKG_SOURCE_VERSION)
PKG_MAINTAINER:=SP <hello@example.com>
PKG_LICENSE:=ISC

include $(INCLUDE_DIR)/package.mk

define Package/lw/default
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=Bitcoin Hotspot
endef

define Package/coinspot
  $(Package/lw/default)
  DEPENDS:=+luci +luci-ssl
endef

define Package/coinspot/description
	Public Wi-Fi Hotspot for bitcoin users
endef

define Package/coinspot/install
	$(CP) ./files/* $(1)/
endef

define Build/Compile
	true
endef

$(eval $(call BuildPackage,coinspot))