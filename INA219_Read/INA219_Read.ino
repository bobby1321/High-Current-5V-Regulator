//
//    FILE: INA219_array.ino
//  AUTHOR: Rob Tillaart
// PURPOSE: demo array of INA219 sensors
//     URL: https://github.com/RobTillaart/INA219


#include "INA219.h"

INA219 arr_ina[2] = { INA219(0x42), INA219(0x43) };
String incomingString = "";  // for incoming serial data

void setup() {
  Serial.begin(115200);
  // Serial.println(__FILE__);
  // Serial.print("INA219_LIB_VERSION: ");
  // Serial.println(INA219_LIB_VERSION);

  Wire.begin();

  for (int i = 0; i < 2; i++) {
    if (!arr_ina[i].begin()) {
      Serial.print("Could not connect:  ");
      Serial.print(i);
      Serial.println(". Fix and Reboot");
    }
  }

  for (int i = 0; i < 2; i++) {
    arr_ina[i].setMaxCurrentShunt(10, 0.005);
    arr_ina[i].setBusVoltageRange(32);
    arr_ina[i].setGain(2);
    arr_ina[i].setShuntADC(0xB);
    delay(1000);
    // Serial.println(arr_ina[i].getBusVoltageRange());
  }
}


void loop() {

  if (Serial.available() > 0) {
    // read the incoming byte:
    incomingString = Serial.readString();
    incomingString.trim();

    if (incomingString == "read") {
      // Serial.println("\n\t#\tBUS(V)\t\tSHUNT(mV)\tCURRENT(mA)\tPOWER(mW)\tOVF\t\tCNVR");
      for (int i = 0; i < 2; i++) {
        // Serial.print("\t");
        // Serial.print(i);
        // Serial.print("\t");
        Serial.print(arr_ina[i].getBusVoltage(), 4);
        Serial.print(" ");
        // Serial.print(arr_ina[i].getShuntVoltage_mV(), 4);
        // Serial.print(" ");
        Serial.print(arr_ina[i].getCurrent_mA(), 4);
        Serial.print(" ");
        Serial.print(arr_ina[i].getPower_mA(), 4);
        // Serial.print(" ");
        // Serial.print(arr_ina[i].getMathOverflowFlag());
        // Serial.print("\t\t");
        // Serial.print(arr_ina[i].getConversionFlag());
        Serial.println();
      }
    }
  }
}


  //  -- END OF FILE --