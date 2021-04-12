void ssdpInit(void)
{
  HTTP.on("/description.xml", HTTP_GET, [](){SSDP.schema(HTTP.client());});
  SSDP.setSchemaURL("description.xml");
  SSDP.setHTTPPort(80);
  SSDP.setName(ssdp);
  SSDP.setSerialNumber("000000000001");
  SSDP.setModelNumber("000000000001");
  SSDP.setURL("/");
  SSDP.setModelName("digital WiFi clock");
  SSDP.setModelURL("https://github.com/sboldenko/digital_wifi_clock");
  SSDP.setManufacturer("sboldenko");
  SSDP.setManufacturerURL(""); 
  //Serial.println("SSDP initialized");
}
