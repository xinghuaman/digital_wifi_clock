void wifiInit(void)
{
  byte cnt = 10;


 
  WiFi.mode(WIFI_STA);
  scanNetworks(); 
  delay(1000);
  WiFi.begin(ssid.c_str(), password.c_str());

  IPAddress ipSTA(ip_oct1, ip_oct2, ip_oct3, ip_oct4);
  IPAddress gatewaySTA(gw_oct1, gw_oct2, gw_oct3, gw_oct4);
  IPAddress subnetSTA(255, 255, 255, 0);
  
  WiFi.config(ipSTA, gatewaySTA, subnetSTA);
  
  while(--cnt && WiFi.status() != WL_CONNECTED)
  {  
    delay(500);
    //Serial.print("Connecting to WiFi");
    delay(500);
    //Serial.print(".");
    delay(500);
    //Serial.print(".");
    delay(500);
    //Serial.println(".");
  }

  Serial.println("");
  
  if (WiFi.status() != WL_CONNECTED)
  {
    //Serial.println("Connection fail!");
    startAPMode();
    //Serial.println("Accsess point mode initialized");
  }
  //else
  //{
    //Serial.print("WiFi connected to ");
    //Serial.println(ssid);
    //Serial.print("Local IP: ");
    //Serial.println(WiFi.localIP());
  //}
}

bool startAPMode()
{
  WiFi.disconnect();
  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(ipAP, gatewayAP, subnetAP);
  WiFi.softAP(APssid, APpassword);
  return true;
}

void scanNetworks() 
{
  //Serial.print("Scan Networks");
  delay(500);
  //Serial.print(".");
  delay(500);
  //Serial.print(".");
  delay(500);
  //Serial.print(".\n");
  byte num_ssid = WiFi.scanNetworks();
  //Serial.print("SSID List:\n");
  
  //for (int thisNet = 0; thisNet<num_ssid; thisNet++) 
  //{
    //Serial.print(thisNet);
    //Serial.print(" - Network: ");
    //Serial.println(WiFi.SSID(thisNet));
  //}
}
