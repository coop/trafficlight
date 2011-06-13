#include <SPI.h>
#include <Ethernet.h>
#include <EthernetDHCP.h>
#include <EthernetDNS.h>

#define DEBUG 1

const char* ip_to_str(const uint8_t*);

int redPin   = 5;
int amberPin = 8;
int greenPin = 3;

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte localhost[] = { 192, 168, 1, 9 };
String currentState = "building";

Client client(localhost, 4567);

void resetPins() {
  digitalWrite(redPin,   LOW);
  digitalWrite(amberPin, LOW);
  digitalWrite(greenPin, LOW);
}

void building() {
  Serial.println("building");
  digitalWrite(amberPin, HIGH);
}

void failing() {
  Serial.println("failing");
  digitalWrite(redPin, HIGH);
}

void passing() {
  Serial.println("passing");
  digitalWrite(greenPin, HIGH);
}

void setup() {
  pinMode(redPin,   OUTPUT);
  pinMode(amberPin, OUTPUT);
  pinMode(greenPin, OUTPUT);

  resetPins();

  Serial.begin(9600);
  EthernetDHCP.begin(mac);

  if (DEBUG) {
    print_ip_conf();
  }

  if (client.connect()) {
    Serial.println("Working...");
    client.println("GET /ping HTTP/1.0");
    client.println();
  } else {
    Serial.println("Not working fucker");
  }
}

void loop() {
  String result = "";

  EthernetDHCP.maintain();

  while (client.available()) {
    char inChar = client.read();
    result += inChar;
    delay(50);
  }

  if (result.length() > 0) {
    Serial.println(result);

    // Both building and failing tests contain a 412 response
    if (result.indexOf("HTTP/1.1 412") >= 0) {
      if (result.indexOf("building") >= 0) {
        building();
      } else {
        failing();
      }
    } else {
      if (result.indexOf("HTTP/1.1 200") >= 0) {
        passing();
      }
    }
  }
}

void print_ip_conf() {
  const byte* ipAddr      = EthernetDHCP.ipAddress();
  const byte* gatewayAddr = EthernetDHCP.gatewayIpAddress();
  const byte* dnsAddr     = EthernetDHCP.dnsIpAddress();

  Serial.println("A DHCP lease has been obtained.");

  Serial.print("My IP address is ");
  Serial.println(ip_to_str(ipAddr));

  Serial.print("Gateway IP address is ");
  Serial.println(ip_to_str(gatewayAddr));

  Serial.print("DNS IP address is ");
  Serial.println(ip_to_str(dnsAddr));
}

const char* ip_to_str(const uint8_t* ipAddr) {
  static char buf[16];
  sprintf(buf, "%d.%d.%d.%d\0", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
  return buf;
}