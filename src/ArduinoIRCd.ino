/*
 * ArduinoIRCd - Small IRCd for Arduinos with Ethernet Shield
 *
 * Written by Aaron Blakely
 */
 
#if defined(ARDUINO) && ARDUINO > 18
#include <SPI.h>
#endif
#include <Ethernet.h>

struct IRCServer {
  char *netName;
  char *name;
  char *ver;
  char *description;
  int users;
  int maxusers;
  char *starttime;
};

struct IRCClient {
  char *nick;
  char *user;
  char *host;
  char *ipAddr;
  char *name;
  int lastping;
  uint8_t socket;
};

byte mac[] = {
  0xA0, 0xEF, 0xAE, 0xFE, 0xEF, 0xAD};
  
EthernetServer server(6667);
IRCServer ircd;

void notice(EthernetClient user, char *tg, char *str);
const char *ip_to_str(const uint8_t* ipAddr);
void welcome_user(EthernetClient u, char *nick, char *user, const char *host);

void setup()
{
  Serial.begin(9600);
  Serial.println("\r\n\r\nArduinoIRCd: starting...");
  
  if (Ethernet.begin(mac) == 0) {
    Serial.println("Failed to configure Ethernet using DHCP.");
    for(;;);
  }
  
  Serial.print("IP Address:");
  for (byte thisByte = 0; thisByte < 4; thisByte++) {
    Serial.print(Ethernet.localIP()[thisByte], DEC);
    Serial.print(".");
  }
  Serial.println();
  
  /* init our server struct - these values may later be filled by config file */
  ircd.netName      = "Ephasic";
  ircd.name         = "ardircd.ephasic.org";
  ircd.ver          = "ArduinoIRCd-0.0.1";
  ircd.description  = "test server";
  ircd.users        = ircd.maxusers = 0;
}

void loop()
{
  IRCClient user;
  EthernetClient client = server.available();
  
  user.socket = client.getSocket();
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
          notice(client, "AUTH", "*** Looking up your hostnamem...");
          notice(client, "AUTH", "*** Found your hostname");
          
          byte remoteip[4];
          client.getRemoteIP(user.socket, remoteip);
          const char *ipAddr = ip_to_str(remoteip);
          
          user_welcome(client, "Dark_Aaron", "aaron", ipAddr);
          
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

void notice(EthernetClient client, char *tg, char *str)
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

void user_welcome(EthernetClient u, char *nick, char *user, const char *host)
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
