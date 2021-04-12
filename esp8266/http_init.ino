void httpInit(void)
{
  HTTP.on("/reset", handleReset);
  HTTP.on("/configSSID", handleConfigSSID);
  HTTP.on("/configPassword", handleConfigPassword);
  HTTP.on("/configStaticIPdevice", handleConfigStaticIP);
  HTTP.on("/configGatewaydevice", handleConfigGateway);
 
  HTTP.begin();
  //Serial.println("HTTP server started");
}

void handleReset()
{
  String code = "<html><head><title>RESET digital WIFI clock</title></head><body><p>Device rebooted. If necessary, update the device ip-address in the search bar.</p><p><A href=\"index.htm\"><-Back</A></p></body></html>";
  String resetChip = HTTP.arg("device");
  if(resetChip == "yes")
  {
    HTTP.send(200, "text/html", code);
    delay(1000);
    ESP.restart();
  }   
}

void handleConfigSSID()
{
  String newSSID = HTTP.arg("SSID");
  //Serial.print("New SSID is ");
  //Serial.println(HTTP.arg("SSID"));
  ssid = newSSID;
  saveConfig();
  handleFileRead("/wifi_settings.htm");
}

void handleConfigPassword()
{
  String newPassword = HTTP.arg("Password");
  //Serial.print("New password is ");
  //Serial.println(HTTP.arg("Password"));
  password = newPassword;
  saveConfig();
  handleFileRead("/wifi_settings.htm");
}

void handleConfigStaticIP()
{
  String newStaticIPdevice_oct1 = HTTP.arg("StaticIPdevice_oct1");
  String newStaticIPdevice_oct2 = HTTP.arg("StaticIPdevice_oct2");
  String newStaticIPdevice_oct3 = HTTP.arg("StaticIPdevice_oct3");
  String newStaticIPdevice_oct4 = HTTP.arg("StaticIPdevice_oct4");
  staticIP_oct1 = newStaticIPdevice_oct1;
  staticIP_oct2 = newStaticIPdevice_oct2;
  staticIP_oct3 = newStaticIPdevice_oct3;
  staticIP_oct4 = newStaticIPdevice_oct4;
  //Serial.print("New static IP-address is ");
  //Serial.print(HTTP.arg("StaticIPdevice_oct1"));
  //Serial.print(".");
  //Serial.print(HTTP.arg("StaticIPdevice_oct2"));
  //Serial.print(".");
  //Serial.print(HTTP.arg("StaticIPdevice_oct3"));
  //Serial.print(".");
  //Serial.println(HTTP.arg("StaticIPdevice_oct4"));
  saveConfig();
  handleFileRead("/wifi_settings.htm");
}

void handleConfigGateway()
{
  String newGatewaydevice_oct1 = HTTP.arg("Gatewaydevice_oct1");
  String newGatewaydevice_oct2 = HTTP.arg("Gatewaydevice_oct2");
  String newGatewaydevice_oct3 = HTTP.arg("Gatewaydevice_oct3");
  String newGatewaydevice_oct4 = HTTP.arg("Gatewaydevice_oct4");
  
  gateway_oct1 = newGatewaydevice_oct1;
  gateway_oct2 = newGatewaydevice_oct2;
  gateway_oct3 = newGatewaydevice_oct3;
  gateway_oct4 = newGatewaydevice_oct4;
  
  saveConfig();
  handleFileRead("/wifi_settings.htm");
}
