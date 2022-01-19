/*
 This example sketch gives you exactly what the SparkFun Pulse Oximiter and
 Heart Rate Monitor is designed to do: read heart rate and blood oxygen levels.
 This board requires I-squared-C connections but also connections to the reset
 and mfio pins. When using the device keep LIGHT and CONSISTENT pressure on the
 sensor. Otherwise you may crush the capillaries in your finger which results
 in bad or no results. A summary of the hardware connections are as follows: 
 SDA -> SDA
 SCL -> SCL
 RESET -> PIN 4
 MFIO -> PIN 5

 Author: Elias Santistevan
 Date: 8/2019
 SparkFun Electronics

 If you run into an error code check the following table to help diagnose your
 problem: 
 1 = Unavailable Command
 2 = Unavailable Function
 3 = Data Format Error
 4 = Input Value Error
 5 = Try Again
 255 = Error Unknown
*/

#include <SparkFun_Bio_Sensor_Hub_Library.h>
#include <Wire.h>
#include <String.h>

// Reset pin, MFIO pin
char val;
int resPin = 4;
int mfioPin = 5;
int spkPin = 12;
String mode = "";
long totalTime = 0;
long minutes = 0;
long seconds = 0;
bool started = false;



// Takes address, reset pin, and MFIO pin.
SparkFun_Bio_Sensor_Hub bioHub(resPin, mfioPin); 

bioData body;  
// ^^^^^^^^^
// What's this!? This is a type (like int, byte, long) unique to the SparkFun
// Pulse Oximeter and Heart Rate Monitor. Unlike those other types it holds
// specific information on your heartrate and blood oxygen levels. BioData is
// actually a specific kind of type, known as a "struct". 
// You can choose another variable name other than "body", like "blood", or
// "readings", but I chose "body". Using this "body" varible in the 
// following way gives us access to the following data: 
// body.heartrate  - Heartrate
// body.confidence - Confidence in the heartrate value
// body.oxygen     - Blood oxygen level
// body.status     - Has a finger been sensed?


void setup(){

  Serial.begin(115200); //start the comunication with the serial monitor
  pinMode(12, OUTPUT); //set pin 12 as output
  
  Wire.begin();
  int result = bioHub.begin();
  if (result == 0) // Zero errors!
    Serial.println("Sensor started!");
  else
    Serial.println("Could not communicate with the sensor!!!");
 
  Serial.println("Configuring Sensor...."); 
  int error = bioHub.configBpm(MODE_ONE); // Configuring just the BPM settings. 
  if(error == 0){ // Zero errors!
    Serial.println("Sensor configured.");
  }
  else {
    Serial.println("Error configuring sensor.");
    Serial.print("Error: "); 
    Serial.println(error); 
  }

  // Data lags a bit behind the sensor, if you're finger is on the sensor when
  // it's being configured this delay will give some time for the data to catch
  // up. 
  Serial.println("Loading up the buffer with data....");
  delay(4000); 
   establishContact();
}

void loop(){

    // Information from the readBpm function will be saved to our "body" variable.  
    if (Serial.available() > 0) { // If data is available to read,
      val = Serial.read(); // read it and store it in val
      
        if(val != 'W'){//Mode check --> Se val è diverso da Wait (W) allora metti mode = val
          if(val == 'F'){
            mode = "F";
          }
          else if(val == 'R'){
             mode = "R";
          }
          else if(val == 'H'){
             mode = "H";
          }
  
          if(val == 'S') //if we get a 1 --> S è il valore di val preliminare che serve per settare started=true
          {
              started = true;
              totalTime = 0; 
              seconds = 0; 
              minutes = 0;        
              Serial.println("S");
          } 
         
           if(mode.equals("H") && started && val == 'C' ){
            //raccoglie dati per 30 secondi, li salva in body e poi li mette in una stringa
             if(totalTime <= 30000 && totalTime >= 0){
              Serial.println("Reading Sensor");
              body = bioHub.readBpm();
              String heartRate = String(body.heartRate);   //li trasforma in stringhe e poi li unisce in una unica
              String confidence = String(body.confidence);
              String oxygen = String(body.oxygen);
              String readStatus = String(body.status);
              String currentTime = String(totalTime);
              String combined = heartRate + "," + confidence + "," + oxygen + "," + readStatus + "," + currentTime;
              Serial.println(combined);
              delay(250); 
              totalTime += 250;
            }
          }
          
  
          if(mode.equals("F") && started && val == 'C'){   //loop per registrare i dati per la modalità fitness (Mode1)
              Serial.println("Reading Sensor");
              body = bioHub.readBpm();
              String heartRate = String(body.heartRate);
              String confidence = String(body.confidence);
              String oxygen = String(body.oxygen);
              String readStatus = String(body.status);
              String currentTime = "";
              
              
              if( seconds != 0 && seconds % 60000 == 0){             //conta il tempo
                minutes += 1;
                seconds = 0;
              }
             
              if(minutes == 0){
                currentTime = "00:";                                 //current time è la stringa del tempo passato
              }
              else{
                if(minutes < 10){
                  currentTime = "0" + String(minutes) + ":";        
                }
                else{
                  currentTime = String(minutes) + ":";       
                }
              }
              
              if(seconds == 0){
                currentTime += "00";
              }
              else{
                if((seconds/1000) < 10){
                  currentTime += "0" + String(seconds/1000);        
                }
                else{
                  currentTime += String(seconds/1000);     
                }
              }
             
              String combined = heartRate +"," + confidence + "," + oxygen + "," + readStatus + "," + currentTime;
              Serial.println(combined);
              delay(250); 
              seconds += 250;
          }

          if(mode.equals("R") && started && (val == 'C' || val == 'L')){
              if(val == 'L'){
                 tone(spkPin, 1000, 1000);   //accensione del buzzer se sei stressato --> "L"
                 delay(3000);
                 tone(spkPin, 1000, 1000);
              }
              Serial.println("Reading Sensor");
              body = bioHub.readBpm();
              String heartRate = String(body.heartRate);
              String confidence = String(body.confidence);
              String oxygen = String(body.oxygen);
              String readStatus = String(body.status);
               String currentTime = "";
             if( seconds != 0 && seconds % 60000 == 0){
                minutes += 1;
                seconds = 0;
              }
             
              if(minutes == 0){
                currentTime = "00:";
              }
              else{
                if(minutes < 10){
                  currentTime = "0" + String(minutes) + ":";        
                }
                else{
                  currentTime = String(minutes) + ":";       
                }
              }
              
              if(seconds == 0){
                currentTime += "00";
              }
              else{
                if((seconds/1000) < 10){
                  currentTime += "0" + String(seconds/1000);        
                }
                else{
                  currentTime += String(seconds/1000);     
                }
              }
             
              String combined = heartRate +"," + confidence + "," + oxygen + "," + readStatus + "," + currentTime;
              Serial.println(combined);
              delay(250); 
              seconds += 250;
          }
         }
         else{
          
          delay(250);
          if(!started){
            Serial.println("W");
          }
          else{
            started = false;
            Serial.println("C");
          }
         }
       
     }
}

void establishContact() {
  while (Serial.available() <= 0) {
    Serial.println("A");   // send a capital A
    delay(300);
  }
}
