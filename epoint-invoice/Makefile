include $(TOPDIR)/rules.mk

PKG_NAME:=epoint-invoice
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/epoint-invoice
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Invoice management for ePoint vending machines
  MAINTAINER:=ePoint Systems Ltd <info@epointsystem.org>
  DEPENDS:=+epoint
endef

define Package/epoint-invoice/description
 Invoice management for ePoint vending machines
endef

define Package/epoint-invoice/conffiles
/etc/config/epoint-invoice
endef

define Package/epoint-invoice/install
	tar c -C ./files . --exclude .svn --exclude '*~' | tar x -C $(1)
endef

define Build/Compile
endef

$(eval $(call BuildPackage,epoint-invoice))
