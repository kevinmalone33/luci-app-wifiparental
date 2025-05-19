include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-wifiparental
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk
PKG_INSTALL:=1

define Package/luci-app-wifiparental
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  MAINTAINER:=Bob Malooga
  TITLE:=wifiparental for OpenWrt LUCI. 
  DEPENDS:=luci
  PKGARCH:=all
endef

define Package/luci-app-wifiparental/description
  wifiparental description
endef

define Build/Compile
endef

define Build/Install
endef

define Package/luci-app-wifiparental/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(CP) ./luasrc/* $(1)/usr/lib/lua/luci
	mkdir -p $(1)/etc/config $(1)/etc/init.d/ $(1)/sbin/ $(1)/etc/wifiparental/
	$(CP) ./files/wifiparental.conf $(1)/etc/config/wifiparental
	$(CP) ./files/wifiparental.sh $(1)/etc/wifiparental/wifiparental.sh
endef

$(eval $(call BuildPackage,luci-app-wifiparental))
