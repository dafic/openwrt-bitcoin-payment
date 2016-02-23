include $(TOPDIR)/rules.mk

PKG_NAME:=epoint
PKG_VERSION:=0.5.1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/epoint
  SUBMENU:=Captive Portals
  SECTION:=net
  CATEGORY:=Network
  TITLE:=ePoint vending machine for public Wi-Fi networks
  MAINTAINER:=ePoint Systems Ltd <info@epointsystem.org>
  DEPENDS:=+firewall +iptables +iptables-mod-nat-extra +epoint-libopencdk +xinetd +luci +luci-ssl +luasocket +lpeg +ntpclient
endef

define Package/epoint/description
 ePoint vending machine for public Wi-Fi networks
endef

define epoint-locale
  define Package/epoint-i18n-$(1)
    SUBMENU:=Captive Portals
    SECTION:=net
    CATEGORY:=Network
    TITLE:=ePoint HotSpot, $(2) language support
    MAINTAINER:=ePoint Systems Ltd <info@epointsystem.org>
    DEPENDS:=epoint
  endef

  define Package/epoint-i18n-$(1)/install
    $(INSTALL_DIR) $$(1)/usr/lib/lua/epoint/i18n
	cp luasrc/epoint/i18n/$(1).lua $$(1)/usr/lib/lua/epoint/i18n/
  endef

  epoint_locales += epoint-i18n-$(1)
endef

$(eval $(call epoint-locale,de,German))
$(eval $(call epoint-locale,fr,French))
$(eval $(call epoint-locale,hu,Hungarian))
$(eval $(call epoint-locale,kk,Kazakh))
$(eval $(call epoint-locale,pt,Portuguese))
$(eval $(call epoint-locale,ru,Russian))
$(eval $(call epoint-locale,uk,Ukrainian))

define Package/epoint/conffiles
/etc/epoint.issuers
/etc/config/epoint
/etc/epoint/tariffs
/etc/uhttpd.key
/etc/uhttpd.crt
/usr/lib/lua/luci/view/epoint/client/error.htm
/usr/lib/lua/luci/view/epoint/client/form.htm
/usr/lib/lua/luci/view/epoint/client/status.htm
/usr/lib/lua/luci/view/epoint/client/upload.htm
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	make -C ./src clean
	$(CP) ./src/* $(PKG_BUILD_DIR)
endef

define Package/epoint/install
	tar c -C ./files . --exclude .svn --exclude '*~' | tar x -C $(1)
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/urldecode $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/getsockname $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/epoint $(1)/usr/bin
	ln -sf epoint $(1)/usr/bin/epoint_sign
	ln -sf epoint $(1)/usr/bin/epoint_verify
	ln -sf epoint $(1)/usr/bin/epoint_dsakey
	ln -sf epoint $(1)/usr/bin/b64decode
	
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_DIR) $(1)/usr/lib/lua/epoint
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/crypto.so $(1)/usr/lib/lua/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/util.so $(1)/usr/lib/lua/epoint/
	tar c -C ./luasrc . --exclude .svn --exclude '*~' | tar x -C $(1)/usr/lib/lua
	find $(1)/usr/lib/lua/epoint/i18n/*lua | grep -v en\.lua$ | xargs rm
endef

$(eval $(call BuildPackage,epoint))
$(foreach pkg,$(epoint_locales),$(eval $(call BuildPackage,$(pkg))))
