bool loadConfig() 
{
  File configFile = SPIFFS.open("/config.json", "r");
  
  if (!configFile)
  {
    //Serial.println("Failed to open config file");
    saveConfig();
    return false;
  }
  
  size_t size = configFile.size();
  
  if (size > 1024) 
  {
    //Serial.println("Config file size is too large");
    return false;
  }

  jsonConfig = configFile.readString();
  DynamicJsonBuffer jsonBuffer;
  JsonObject& root = jsonBuffer.parseObject(jsonConfig);
  
  ssid = root["ssidName"].as<String>(); 
  password = root["ssidPassword"].as<String>();
  
  staticIP_oct1 = root["staticIPdevice_oct1"].as<String>();
  staticIP_oct2 = root["staticIPdevice_oct2"].as<String>();
  staticIP_oct3 = root["staticIPdevice_oct3"].as<String>();
  staticIP_oct4 = root["staticIPdevice_oct4"].as<String>();
  
  gateway_oct1 = root["Gatewaydevice_oct1"].as<String>();
  gateway_oct2 = root["Gatewaydevice_oct2"].as<String>();
  gateway_oct3 = root["Gatewaydevice_oct3"].as<String>();
  gateway_oct4 = root["Gatewaydevice_oct4"].as<String>();
  
  setStaticIPaddress(staticIP_oct1, staticIP_oct2, staticIP_oct3, staticIP_oct4);
  setGatewayaddress(gateway_oct1, gateway_oct2, gateway_oct3, gateway_oct4);
  
  return true;
}

bool saveConfig() 
{
  DynamicJsonBuffer jsonBuffer;
  JsonObject& json = jsonBuffer.parseObject(jsonConfig); 
  
  json["ssidName"] = ssid;
  json["ssidPassword"] = password;
  
  json["staticIPdevice_oct1"] = staticIP_oct1;
  json["staticIPdevice_oct2"] = staticIP_oct2;
  json["staticIPdevice_oct3"] = staticIP_oct3;
  json["staticIPdevice_oct4"] = staticIP_oct4;
  
  json["Gatewaydevice_oct1"] = gateway_oct1;
  json["Gatewaydevice_oct2"] = gateway_oct2;
  json["Gatewaydevice_oct3"] = gateway_oct3;
  json["Gatewaydevice_oct4"] = gateway_oct4;
  
  json.printTo(jsonConfig);
  File configFile = SPIFFS.open("/config.json", "w");
  
  if (!configFile) 
  {
    return false;
  }

  json.printTo(configFile);
  return true;
}

void setStaticIPaddress(String oct1, String oct2, String oct3, String oct4)
{
  char oct1_conv[3];
  char oct2_conv[3];
  char oct3_conv[3];
  char oct4_conv[3];
  
  strcpy(oct1_conv, oct1.c_str());
  ip_oct1 = atoi(oct1_conv);
  strcpy(oct2_conv, oct2.c_str());
  ip_oct2 = atoi(oct2_conv);
  strcpy(oct3_conv, oct3.c_str());
  ip_oct3 = atoi(oct3_conv);
  strcpy(oct4_conv, oct4.c_str());
  ip_oct4 = atoi(oct4_conv);
}

void setGatewayaddress(String sgw_oct1, String sgw_oct2, String sgw_oct3, String sgw_oct4)
{
  char gw_oct1_conv[3];
  char gw_oct2_conv[3];
  char gw_oct3_conv[3];
  char gw_oct4_conv[3];
  
  strcpy(gw_oct1_conv, sgw_oct1.c_str());
  gw_oct1 = atoi(gw_oct1_conv);
  strcpy(gw_oct2_conv, sgw_oct2.c_str());
  gw_oct2 = atoi(gw_oct2_conv);
  strcpy(gw_oct3_conv, sgw_oct3.c_str());
  gw_oct3 = atoi(gw_oct3_conv);
  strcpy(gw_oct4_conv, sgw_oct4.c_str());
  gw_oct4 = atoi(gw_oct4_conv);
}
