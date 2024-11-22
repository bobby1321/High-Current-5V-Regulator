#include <Wire.h>

void setup() {
  Serial.begin(115200);
  Wire.begin();
  delay(100);
  Wire.beginTransmission(33);
  Wire.write(3);
  Wire.write(255); // 0 to 255 for each channel
  Serial.println(String(Wire.endTransmission()));
  delay(100);
  Wire.beginTransmission(33);
  Wire.write(1);
  Wire.write(0);
  Serial.println(String(Wire.endTransmission()));
}

void loop() {
  
  // for (int pin = 0; pin < 8; pin++) {
  //   Wire.beginTransmission(33);;
  //   Wire.write(1);
  //   Wire.write(1<<pin);
  //   Wire.endTransmission();
  //   delay(100);
  // }
  Wire.beginTransmission(33);
  int output_reg;
  Wire.write(1);
    
  Wire.requestFrom(33, 1);
  while (Wire.available()) 
  {                                   
    output_reg = Wire.read();
    // output_reg = 0;
    // Serial.println(String(output_reg));
  }
  Serial.println(String(output_reg));
  Serial.println(String(Wire.endTransmission()));
  delay(100);
}
