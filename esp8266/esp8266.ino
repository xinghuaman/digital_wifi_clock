#include <NTPClient.h>
#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <ESP8266WebServer.h>
#include <ESP8266SSDP.h>
#include <FS.h>
#include <ArduinoJson.h>
#include <stdlib.h>

const char* ssdp = "fpga_wifi_clock";

String ssid = "ASUS-DSLN17U-sboldenko_";
String password = "361128ad";

String staticIP_oct1;
String staticIP_oct2;
String staticIP_oct3;
String staticIP_oct4;

uint8_t ip_oct1=192;
uint8_t ip_oct2=168;
uint8_t ip_oct3=1;
uint8_t ip_oct4=17;

String gateway_oct1;
String gateway_oct2;
String gateway_oct3;
String gateway_oct4;

uint8_t gw_oct1;
uint8_t gw_oct2;
uint8_t gw_oct3;
uint8_t gw_oct4;

const char* APssid = "fpga_wifi_clock";
const char* APpassword = "";

String jsonConfig ="{}";

IPAddress ipAP(192, 168, 0, 1);
IPAddress gatewayAP(192, 168, 0, 1);
IPAddress subnetAP(255, 255, 255, 0);

ESP8266WebServer HTTP(80);

File fsUploadFile;

const long utcOffsetInSeconds = 10800;
const long timeUpdateInterval = 1000;
//const long timeUpdateInterval = 86400000;

WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", utcOffsetInSeconds, timeUpdateInterval);

void setup(void)
{
  Serial.begin(9600);
  fsInit();
  loadConfig();
  wifiInit();
  timeClient.begin();
  ssdpInit();
  httpInit();
}

uint8_t no_time_counter = 0;
uint8_t hr_int; 
uint8_t min_int;
uint8_t sec_int;

void loop()
{
  HTTP.handleClient();
  
  if (timeClient.update())
  {
    no_time_counter = 0;
    
    uint8_t hr_int_high = highByte(timeClient.getHours()); 
    uint8_t hr_int_low = lowByte(timeClient.getHours());
    uint8_t min_int_high = highByte(timeClient.getMinutes()); 
    uint8_t min_int_low = lowByte(timeClient.getMinutes()); 
    uint8_t sec_int_high = highByte(timeClient.getSeconds()); 
    uint8_t sec_int_low = lowByte(timeClient.getSeconds()); 

    uint8_t hr_int_dec = (hr_int_low / 10);
    uint8_t hr_int_num = hr_int_low - (hr_int_dec * 10);
    hr_int = (hr_int_dec << 4) + hr_int_num;
    
    uint8_t min_int_dec = min_int_low / 10;
    uint8_t min_int_num = min_int_low - (min_int_dec *10);
    min_int = (min_int_dec << 4) + min_int_num;
    
    uint8_t sec_int_dec = sec_int_low / 10;
    uint8_t sec_int_num = sec_int_low - (sec_int_dec *10);
    sec_int = (sec_int_dec << 4) + sec_int_num;

    Serial.write(0xAA);
    Serial.write(hr_int);
    Serial.write(min_int);
    Serial.write(sec_int);
  }
  else
  {
    //Serial.println("No time :(");
    no_time_counter = no_time_counter + 1;
  }

  if (no_time_counter == 5)
    ESP.reset();
    
  delay(1000);
} 
