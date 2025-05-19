
module "luci.controller.wifiparental"

function index()
	entry({"admin", "services", "wifiparental"}, cbi("wifiparental/wifiparental"), _("wifiparental"), 40)
end
