/*
 * ArduinoIRCd - Small IRCd for Arduinos with Ethernet Sheild
 *
 * Written by Aaron Blakely
 */

#if defined(ARDUINO) && ARDUINO > 18
#include <SPI.h>
#endif
#include <Ethernet.h>
#include <EthernetDHCP.h>

byte mac[] = { 
  0xA0, 0xEF, 0xAE, 0xFE, 0xEF, 0xAD };
Server server(6667);

void setup()
{
  Serial.begin(9600);
  EthernetDHCP.begin(mac, 1);
}

void notice(Client user, char *tg, char *str)
{
  char buf[1024];
  sprintf(buf, ":ardircd.ephasic.org NOTICE %s :%s\r\n", tg, str);
  user.print(buf);
}

const char *ip_to_str(const uint8_t* ipAddr) {
  static char buf[16];
  sprintf(buf, "%d.%d.%d.%d\0", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
  return buf;
}

void loop()
{
  static DhcpState prevState = DhcpStateNone;
  static unsigned long prevTime = 0;

  DhcpState state = EthernetDHCP.poll();
  if (prevState != state)
  {
    switch(state) {
    case DhcpStateDiscovering:
      Serial.print("Discovering DHCP servers.");
      break;
    case DhcpStateLeased: 
      {
        Serial.println();
        Serial.print("obtained IP address: ");
        const byte *ipAddr = EthernetDHCP.ipAddress();

        Serial.println(ip_to_str(ipAddr));
        server.begin();

        break;
      }
    }
  }
  else if (state != DhcpStateLeased && millis() - prevTime > 300)
  {
    prevTime = millis();
    Serial.print('.');
  }

  prevState = state;

  Client client = server.available();
  if (client) {
    boolean sentHeader = false;
    boolean currentLineIsBlank = false;
    
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        if (sentHeader == false) {
          notice(client, "AUTH", "*** Looking up your hostname...");
          notice(client, "AUTH", "*** Found your hostname");
          
          sentHeader = true;
           
        }

        Serial.print(c);
        if (c == '\n') {
          currentLineIsBlank = true;
        } 
        else if (c != '\r') {
          currentLineIsBlank = false;
        }
      }
      delay(1);
    }
  }
}
