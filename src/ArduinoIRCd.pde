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


struct IRCServer {
  char *netName;
  char *name;
  char *ver;
  char *description;
  int users;
  int maxusers;
  char *starttime;
};

byte mac[] = { 
  0xA0, 0xEF, 0xAE, 0xFE, 0xEF, 0xAD };
  
Server server(6667);
IRCServer ircd;


/* some function defs */
void notice(Client user, char *tg, char *str);
const char *ip_to_str(const uint8_t* ipAddr);
void welcome_user(Client user, char *nick);

void setup()
{
  Serial.begin(9600);
  
  Serial.println("\r\n\r\nArduinoIRCd: starting...");
  EthernetDHCP.begin(mac, 1);
  
  ircd.netName = "Ephasic";
  ircd.name = "ardircd.ephasic.org";
  ircd.ver  = "ArduinoIRCd-0.0.1";
  ircd.description = "test server";
  ircd.users = ircd.maxusers = 0;
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
    
    ircd.users++;
    if (ircd.users > ircd.maxusers) {
      ircd.maxusers = ircd.users;
    }
    
    boolean sentHeader = false;
    boolean currentLineIsBlank = false;
    
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        if (sentHeader == false) {
          notice(client, "AUTH", "*** Looking up your hostname...");
          notice(client, "AUTH", "*** Found your hostname");
          user_welcome(client, "Dark_Aaron", "aaron", "192.168.1.7");
          
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


void notice(Client client, char *tg, char *str)
{
  char buf[1024];
  sprintf(buf, ":%s NOTICE %s :%s\r\n", ircd.name, tg, str);
  client.print(buf);
  memset(buf, 0, 1024);
}

const char *ip_to_str(const uint8_t* ipAddr)
{
  static char buf[16];
  sprintf(buf, "%d.%d.%d.%d\0", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
  return buf;
}

void user_welcome(Client u, char *nick, char *user, char *host)
{
  char buf[2048];
  sprintf(buf, ":%s 001 %s :Welcome to the %s IRC network, %s!%s@%s\r\n", ircd.name, nick, ircd.netName, nick, user, host);
  u.print(buf);
  sprintf(buf, ":%s 002 %s :Your host is %s, running version %s\r\n", ircd.name, nick, ircd.name, ircd.ver);
  u.print(buf);
  sprintf(buf, ":%s 003 %s :This server was created %s\r\n", ircd.name, nick, ircd.starttime);
  u.print(buf);
  sprintf(buf, ":%s 004 %s %s %s iowghraAsORTVSxNCWqBzvdHtGp lvhopsmntikrRcaqOALQbSeIKVfMCuzNTGjZ\r\n", ircd.name, nick, ircd.name, ircd.ver, ircd.ver);
  u.print(buf);
  sprintf(buf, ":%s 005 %s NETWORK=%s PREFIX=(qaohv)~&@%%+ NICKLEN=35 TOPICLEN=130 USERLEN=20 :is supported by this server\r\n", ircd.name, nick, ircd.netName);
  u.print(buf);
  memset(buf, 0, 2048);
}

