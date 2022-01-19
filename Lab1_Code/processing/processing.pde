import grafica.*;
import g4p_controls.*;
import processing.serial.*;
import java.awt.Font;

GPlot plot;
Serial myPort;
String val;
String comma = ",";
String FitnessMode = "F";
String RelaxVStressMode = "R";
String Wait = "W";
String Start = "S";
String Done = "D";
String Resting = "H";
String Continue = "C";
String Stressed = "L";
String result="";
String currentMode = "";

boolean workingOut = false;
boolean checkingStress = false;
boolean firstContact = false;
boolean buzzed = false;
boolean workedOutLongEnough = false;
boolean lookingAtResults = false;

int totalHeartRate = 0;
int totalConfidence = 0;
int totalOxygen = 0;
int totalPointsRead = 0;
int userAge;
int totalStressPoints = 0;
int maximumHeartRate;


//long timeInVeryLight = 190;
//long timeInLight = 240;
//long timeInModerate = 1680;
//long timeInHard = 5740;
//long timeInMaximum = 3720;
long timeInVeryLight = 0;
long timeInLight = 0;
long timeInModerate = 0;
long timeInHard = 0;
long timeInMaximum = 0;


//define the cardiozones
double minimumVeryLight = .5 * maximumHeartRate;
double maximumVeryLight = .6 * maximumHeartRate;

double minimumLight = .6 * maximumHeartRate;
double maximumLight = .7 * maximumHeartRate;

double minimumModerate = .7 * maximumHeartRate;
double maximumModerate = .8 * maximumHeartRate;

double minimumHard = .8 * maximumHeartRate;
double maximumHard = .9 * maximumHeartRate;

double minimumMaximum = .9 * maximumHeartRate;
double maximumMaximum = 1 * maximumHeartRate;

float globalAverageBeatsBetween = 0.0;
float globalAverageRestingHeartRate = 0.0;
float globalAverageConfidenceLevel = 0.0;
float globalAverageOxygenLevel= 0.0;
float averageRestingHeartRate = 0.0;
float averageConfidenceLevel = 0.0;
float averageOxygenLevel = 0.0;

//labels
GGroup groupHome;
GGroup groupResting;
GGroup groupSelect;
GGroup groupFitnessDuring;
GGroup groupFitnessAfter;
GGroup groupStress;

GLabel lblVeryLightText; 
GLabel lblLightText; 
GLabel lblModerateText; 
GLabel lblHardText; 
GLabel lblMaximumText; 

GLabel lblVeryLightTextInfo; 
GLabel lblLightTextInfo; 
GLabel lblModerateTextInfo; 
GLabel lblHardTextInfo; 
GLabel lblMaximumTextInfo; 


void setup(){
  size(480, 480);
   
 
  createGUI();
  createGroups();
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 115200);
  myPort.bufferUntil('\n'); 
    plot = new GPlot(this);
  plot.setPos(40, 240);
  plot.setDim(300, 130);
  plot.getTitle().setText("Heartrate graph");
  plot.getXAxis().getAxisLabel().setText("Time (sec) ");
  plot.getYAxis().getAxisLabel().setText("Heartrate (bpm)");
  
}



//in questa sezione si plotta il grafico della Mode1
void draw(){
background(#F3F3F3);
  if(lookingAtResults){
    if(workedOutLongEnough){
     fill(0);
     rect(16, 20, 444, 210);
    }
     
     GPointsArray pointsArray = plot.getPoints();
  //println("num points=" + pointsArray.getNPoints());
  int numTotalPoints = pointsArray.getNPoints();
  // to set colors we must fist analyze all the collected points, not possible dynamically 
  color[] pointColors = new color[numTotalPoints];
  for (int i = 0; i < numTotalPoints; i++) {
     GPoint curr = pointsArray.get(i);
     float currBPM = curr.getY();  // y is the bpm
     
     int colorVal = heartRateLevelInt(int(currBPM));  //classifica i punti assegnandogli un colore in base alla loro zona cardiaca
     if (colorVal == 1) {
       pointColors[i] = color(153, 243, 255, 100);
     } else if (colorVal == 2) {
       pointColors[i] = color(135, 250, 162, 100);
     } else if (colorVal == 3) {
       pointColors[i] = color(247, 216, 124, 100);
     } else if (colorVal == 4) {
       pointColors[i] = color(243, 255, 112, 100);
     } else if (colorVal == 5) {
       pointColors[i] = color(255, 97, 129, 100);
     }
     
     
  }
  
  
  plot.setPointColors(pointColors);    
  // Draw the plot  
  plot.beginDraw();
  plot.drawBackground();
  plot.drawBox();
  plot.drawXAxis();
  plot.drawYAxis();
  plot.drawTitle();
  plot.drawGridLines(GPlot.BOTH);
  plot.drawLines();
  plot.drawPoints();
  plot.endDraw();

     
  }
  
  

}



void serialEvent(Serial myPort) {

//put the incoming data into a String - 
//the '\n' is our end delimiter indicating the end of a complete packet
val = myPort.readStringUntil('\n');
//make sure our data isn't empty before continuing
if (val != null) {
  //trim whitespace and formatting characters (like carriage return)
  val = trim(val);
  println(val);

  //look for our 'A' string to start the handshake --------------------------------> prima la porta seriale di arduino inviava A, serve per l'handshake
  //if it's there, clear the buffer, and send a request for data
  if (firstContact == false) {
    if (val.equals("A")) {
      myPort.clear();
      firstContact = true;
      myPort.write(Wait);
      println("contact");
    }
  }
  else { //if we've already established contact, keep getting and parsing data
    if(val.equals("S")){   //S=start
     myPort.write("C");   //C=continue
    }
    else if(val.contains(comma)){

      if(currentMode.equals("F")){ //---------------------------> Fitness Mode
         String[] info = split(val, ',');
        int heartRate = int(info[0]);
        int status = int(info[3]);
        String time = info[4];
        
        String[] secondsSplit = split(time, ':');
        int seconds = int(secondsSplit[1]) * 1000;
        
        int graphTime = (int(secondsSplit[0]) * 60) + (seconds / 1000); 
        lblCurrWorkOutTime.setText(time);

        //compute averages
        if(totalPointsRead != 0){
          averageRestingHeartRate = totalHeartRate / totalPointsRead;
          averageConfidenceLevel = totalConfidence / totalPointsRead;
          averageOxygenLevel = totalOxygen / totalPointsRead;
        }
        
        
        if(seconds % 1000 == 0){ //se è passato un secondo
          if(status == 3 && heartRate > 20){ //se una hearthrate è rilavata e c'è un dito sopra il sensore
            
            lblWorkoutBPMV.setText(str(heartRate));
            String level = heartRateLevel(heartRate);  //save the heartRate level
            lblCardioZoneVal.setText(level);
             plot.addPoint(graphTime, heartRate, "(" + str(graphTime) + " , " + str(heartRate) + ")");
          }
        }
        
        if(workingOut){
          myPort.write(Continue);
        }
        
      }
      else if(currentMode.equals("R")){ //--------------------------------> Mode2
        String[] info = split(val, ',');
        int heartRate = int(info[0]);
        int status = int(info[3]);
        String time = info[4];
        
        String[] secondsSplit = split(time, ':');
        int seconds = int(secondsSplit[1]) * 1000;
        
        lblCurrentStressTimeV.setText(time);

        if(seconds % 1000 == 0){
          if(status == 3 && heartRate > 20){
            lblStessedBPMV.setText(str(heartRate));
           if(heartRate - globalAverageRestingHeartRate <= 10){
             
              totalHeartRate += heartRate;
              totalPointsRead += 1;
           }
           else{
             totalStressPoints += 1;
           }
         }
        }
        if(totalStressPoints >= 10){
            lblStressStatusV.setText("You are pretty stressed");
            background(#FF0000);
          }
          else{
            lblStressStatusV.setText("You are most likely not stressed");
            background(#3f33ff);
        } 
        if(checkingStress){
          if(totalStressPoints >= 10 && !buzzed){
              buzzed = true;
              myPort.write(Stressed);
          }
          else{
             myPort.write(Continue);
          }
        }
      }
      else if(currentMode.equals("H")){  //----------------> resting
        int[] info = int(split(val, ','));
        int heartRate = info[0];
        int confidence = info[1];
        int oxygen = info[2];
        int status = info[3];
        int totalTime = info[4];
        if(status == 3 && heartRate > 20){
            totalHeartRate += heartRate;
            totalConfidence += confidence;
            totalOxygen += oxygen;
            totalPointsRead += 1;
        }
        
         if(totalTime == 30000){
          if(totalPointsRead != 0){
            averageRestingHeartRate = totalHeartRate / totalPointsRead;
            averageConfidenceLevel = totalConfidence / totalPointsRead;
            averageOxygenLevel = totalOxygen / totalPointsRead;
          }
          globalAverageRestingHeartRate = averageRestingHeartRate;  //set the user resting values
          globalAverageConfidenceLevel = averageConfidenceLevel;
          globalAverageOxygenLevel = averageOxygenLevel;
          lblSEC.setText("Done");
          myPort.write(Wait);
          delay(2000);
          leaveResting();
          setSelectScreen();
          resetVariables();
          
        }
        else if(totalTime % 1000 == 0 && totalTime < 30000 && totalTime >= 0){
          
           int time = 30 - totalTime/1000;
           String tT = str(time) + " seconds";
           lblSEC.setText(tT);
           if(status == 3 && heartRate > 20){
             lblBPM.setText(str(heartRate));
             lblOX.setText(str(oxygen));
             lblConfidence.setText(str(confidence));
           }
           myPort.write(Continue);
        }
        else{
          myPort.write(Continue);
        }
      }
    }
    else{
       
      }   
    }
  }
}


//function able to return you the string that said to you in witch cardio zone you are
// also measure how much time you stay in that zone
String heartRateLevel(int heartRate){
  if( heartRate <=  maximumVeryLight){
    timeInVeryLight += 1;
    return ("You are in the very light cardio zone");
  }
  else if(heartRate >= minimumLight && heartRate <  maximumLight){
    timeInLight += 1;
    return ("You are in the light cardio zone");
  }
  else if(heartRate >= minimumModerate && heartRate <  maximumModerate){
    timeInModerate += 1;
    return ("You are in the moderate cardio zone");
  }
  else if(heartRate >= minimumHard && heartRate <  maximumHard){
    timeInHard += 1;
    return ("You are in the hard cardio zone");
  }
  else{
    timeInMaximum += 1;
    return ("You are in the maximum cardio zone");
  }
  
}


//funzione che permette di determinare a che zona cardiaca apartengono i punti del grafico
int heartRateLevelInt(int heartRate){     
  if(heartRate < 5){
   
   return 0;
  }
  else if(heartRate <  maximumVeryLight){
    
    return 1;
  }
  else if(heartRate >= minimumLight && heartRate <  maximumLight){
   return 2;
  }
  else if(heartRate >= minimumModerate && heartRate <  maximumModerate){
    
    return 3;
  }
  else if(heartRate >= minimumHard && heartRate <  maximumHard){
    return 4;
  }
  else{
    return 5;
  }
  
}


//function that allow you to change the actual mode of the device. Change "currentMode" and another variable depending on the case
void setMode(String mode){

  if(mode.equals(FitnessMode)){
     currentMode = FitnessMode;
     workingOut = true;
     myPort.write(FitnessMode);

  }
  else if(mode.equals(RelaxVStressMode)){
     currentMode = RelaxVStressMode;
     checkingStress = true;
     myPort.write(RelaxVStressMode);
  }
  else if(mode.equals(Resting)){
     currentMode = Resting;
     myPort.write(Resting);
  }
       
}


//Scrive start sulla porta seriale
void startTracking(){
  myPort.write(Start);
}

//set limits for cardio zones
void setAgeAndHeartRateRange(int age){
     
     userAge = age;
     maximumHeartRate = 220 - userAge;
     minimumVeryLight = .5 * maximumHeartRate;
     maximumVeryLight = .6 * maximumHeartRate;
    
     minimumLight = .6 * maximumHeartRate;
     maximumLight = .7 * maximumHeartRate;
    
     minimumModerate = .7 * maximumHeartRate;
     maximumModerate = .8 * maximumHeartRate;
    
     minimumHard = .8 * maximumHeartRate;
     maximumHard = .9 * maximumHeartRate;
    
     minimumMaximum = .9 * maximumHeartRate;
     maximumMaximum = 1 * maximumHeartRate;
}


public void createGroups(){
  groupHome = new GGroup(this);   // definisce i gruppi
  groupResting = new GGroup(this);
  groupSelect = new GGroup(this);
  groupFitnessDuring = new GGroup(this);
  groupFitnessAfter = new GGroup(this);
  groupStress = new GGroup(this);
  
  groupHome.addControl(txtAGE);  //aggiunge dei campi ai gruppi
  groupHome.addControl(btnSubmit);
  groupHome.addControl(lblError);
  groupHome.addControl(lblAge);

  groupResting.setVisible(0,false);
  groupResting.addControl(lblRestingHeart);
  groupResting.addControl(lblPlaceFingerOn);
  groupResting.addControl(btnStartAVG);
  groupResting.addControl(lblCurrBPM);
  groupResting.addControl(lblSEC);
  groupResting.addControl(lblBPM);
  groupResting.addControl(lblTimeLeft);
  groupResting.addControl(lblConfidence);
  groupResting.addControl(lblOX);
  groupResting.addControl(lblCURRConf);
  groupResting.addControl(lblCURROx);
  lblConfidence.setFont(new Font("Monospaced", Font.PLAIN, 60));
  lblOX.setFont(new Font("Monospaced", Font.PLAIN, 60));
  lblBPM.setFont(new Font("Monospaced", Font.PLAIN, 60));
  
  groupSelect.setVisible(0,false);
  groupSelect.addControl(lblBetweenBeats);
  groupSelect.addControl(lblTimeBetweenBeatsV);
  groupSelect.addControl(lblAverageHR);
  groupSelect.addControl(lblAverageOX);
  groupSelect.addControl(lblAverageConf);
  groupSelect.addControl(lblAverageRHV);
  groupSelect.addControl(lblConfV);
  groupSelect.addControl(lblOXV);
  groupSelect.addControl(btnWorkingOut);
  groupSelect.addControl(btnStress);
  
  groupFitnessDuring.setVisible(0,false);
  groupFitnessDuring.addControl(btnStartWorkOut);
  groupFitnessDuring.addControl(btnStopWorkOut);
  groupFitnessDuring.addControl(lblCurrWorkOutTime);
  groupFitnessDuring.addControl(lblWorkOutTime);
  groupFitnessDuring.addControl(lblWorkOutCurrBPM);
  groupFitnessDuring.addControl(lblWorkoutBPMV);
  groupFitnessDuring.addControl(lblWorkoutLevel);
  groupFitnessDuring.addControl(lblCardioZoneVal);
  groupFitnessDuring.addControl(btnHomeWorkoutDuring);
  lblWorkoutBPMV.setFont(new Font("Monospaced", Font.PLAIN, 60));
  btnStopWorkOut.setEnabled(false);
  
  groupFitnessAfter.setVisible(0,false);
  groupFitnessAfter.addControl(lblVeryLightText);
  groupFitnessAfter.addControl(lblLightText);
  groupFitnessAfter.addControl(lblModerateText);
  groupFitnessAfter.addControl(lblHardText);
  groupFitnessAfter.addControl(lblMaximumText);
  groupFitnessAfter.addControl(lblVeryLightTextInfo);
  groupFitnessAfter.addControl(lblLightTextInfo);
  groupFitnessAfter.addControl(lblModerateTextInfo);
  groupFitnessAfter.addControl(lblHardTextInfo);
  groupFitnessAfter.addControl(lblMaximumTextInfo);
  groupFitnessAfter.addControl(lblDidntWorkout);
  groupFitnessAfter.addControl(btnWorkoutAfterHome);
  lblDidntWorkout.setVisible(false);
  
  groupStress.setVisible(0,false);
  groupStress.addControl(lblStressedCurrentBPM);
  groupStress.addControl(lblStessedBPMV);
  groupStress.addControl(btnStartStressed);
  groupStress.addControl(lblStressedInfo);
  groupStress.addControl(lblStessStatus);
  groupStress.addControl(lblStressStatusV);
  groupStress.addControl(lblStressTime);
  groupStress.addControl(lblCurrentStressTimeV);
  groupStress.addControl(btnStopCheckingStress);
  groupStress.addControl(btnStressHome);
  lblStessedBPMV.setFont(new Font("Monospaced", Font.PLAIN, 60));
  btnStopCheckingStress.setEnabled(false);
  
}

public void setHomeScreen(String previousScreen){
    if(previousScreen.equals("Stress Check")){
        groupStress.setVisible(0,false);
    }
    else if(previousScreen.equals("Working Out")){
         groupFitnessDuring.setVisible(0,false);
    }
    else if(previousScreen.equals("Workout Results")){
       groupFitnessAfter.setVisible(0,false);
    }
    setSelectScreen();
}

public void setRestingScreen(){
  groupHome.setVisible(0, false);
  groupResting.setVisible(0,true);
  setMode(Resting);
}

public void leaveResting(){
   groupResting.setVisible(0,false);
   
}

public void setSelectScreen(){
  globalAverageBeatsBetween = 60.0/globalAverageRestingHeartRate;
  lblTimeBetweenBeatsV.setText(str(globalAverageBeatsBetween));
  lblAverageRHV.setText(str(globalAverageRestingHeartRate));
  lblConfV.setText(str(globalAverageConfidenceLevel));
  lblOXV.setText(str(globalAverageOxygenLevel));
  groupSelect.setVisible(0,true);
}

public void setFitnessDuringScreen(){
  setMode(FitnessMode);
  groupSelect.setVisible(0,false);
  btnStartWorkOut.setEnabled(true);
  btnStopWorkOut.setEnabled(false);
  groupFitnessDuring.setVisible(0,true);
}

public void updateFitnessScreen(boolean starting){    //bottoni per l'interfaccia prima di inziare l'esercizio
  if(starting){
    startTracking();
   btnStartWorkOut.setEnabled(false);
   btnStopWorkOut.setEnabled(true);
   btnHomeWorkoutDuring.setEnabled(false);
  }
  else{
    btnStartWorkOut.setEnabled(false);
    btnStopWorkOut.setEnabled(false);
    btnHomeWorkoutDuring.setEnabled(true);
    workingOut = false;
    setFitnessAfterScreen();
  }
}

public void setFitnessAfterScreen(){
   groupFitnessDuring.setVisible(0,false);
   lookingAtResults = true;
   long total = timeInVeryLight + timeInLight + timeInModerate +timeInHard +timeInMaximum;
   if(total > 60){
     workedOutLongEnough = false;
     lblDidntWorkout.setVisible(true);
   }
   float veryLightPercent = (float(str(timeInVeryLight)) / total) * 416;   //set the instogram
   float lightPercent = (float(str(timeInLight)) / total) * 416;
   float moderatePercent = (float(str(timeInModerate)) / total) * 416;
   float hardPercent = (float(str(timeInHard)) / total) * 416;
   float maximumPercent = (float(str(timeInMaximum)) / total) * 416;
    println("timeInVeryLight" + veryLightPercent);
    println("lightPercent" + lightPercent);
    println("moderatePercent" + moderatePercent);
    println("hardPercent" + hardPercent);
    println("maximumPercent" + maximumPercent);
   if(timeInVeryLight >= 0 && timeInVeryLight < 60){

   }
   else{
       String veryLightMin = int(timeInVeryLight/60) + " min";
       if(veryLightPercent >= 208){
         lblVeryLightText = new GLabel(this, 42, 40, veryLightPercent, 32);
         lblVeryLightText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblVeryLightText.setText(veryLightMin);
         lblVeryLightText.setLocalColorScheme(GCScheme.CYAN_SCHEME);
         lblVeryLightText.setOpaque(true);
          lblVeryLightText.setFont(new Font("Monospaced", Font.PLAIN, 18));
       }
       else{
         lblVeryLightText = new GLabel(this, 42, 40, veryLightPercent, 32);
         lblVeryLightText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblVeryLightText.setText("");
         lblVeryLightText.setLocalColorScheme(GCScheme.CYAN_SCHEME);
         lblVeryLightText.setOpaque(true);
         lblVeryLightTextInfo = new GLabel(this, 42+veryLightPercent, 40, 416-veryLightPercent, 32);
         lblVeryLightTextInfo.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
         lblVeryLightTextInfo.setText(veryLightMin);
         lblVeryLightTextInfo.setLocalColorScheme(GCScheme.CYAN_SCHEME);
         lblVeryLightTextInfo.setOpaque(false);
          lblVeryLightTextInfo.setFont(new Font("Monospaced", Font.PLAIN, 18));
       }
   }
   
   if(timeInLight >= 0 && timeInLight < 60){
    
   }
   else{
     String lightMin = int(timeInLight/60) + " min";
       if(lightPercent >= 208){
         lblLightText = new GLabel(this, 42, 80, lightPercent, 32);
         lblLightText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblLightText.setText(lightMin);
         lblLightText.setLocalColorScheme(GCScheme.GREEN_SCHEME);
         lblLightText.setOpaque(true);
         lblLightText.setFont(new Font("Monospaced", Font.PLAIN, 18));
       }
       else{
         lblLightText = new GLabel(this, 42, 80, lightPercent, 32);
         lblLightText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblLightText.setText("");
         lblLightText.setLocalColorScheme(GCScheme.GREEN_SCHEME);
         lblLightText.setOpaque(true);
         lblLightTextInfo = new GLabel(this, 42+lightPercent, 80, 416-lightPercent, 32);
         lblLightTextInfo.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
         lblLightTextInfo.setText(lightMin);
         lblLightTextInfo.setLocalColorScheme(GCScheme.GREEN_SCHEME);
         lblLightTextInfo.setOpaque(false);
         lblLightTextInfo.setFont(new Font("Monospaced", Font.PLAIN, 18));
       }
      
   }
   
   if(timeInModerate >= 0 && timeInModerate < 60){
     
   }
   else{
       String moderateMin = int(timeInModerate/60) + " min";
       if(moderatePercent >= 208){
         lblModerateText = new GLabel(this, 42, 120, moderatePercent, 32);
         lblModerateText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblModerateText.setText(moderateMin);
         lblModerateText.setLocalColorScheme(GCScheme.ORANGE_SCHEME);
         lblModerateText.setOpaque(true);
         lblModerateText.setFont(new Font("Monospaced", Font.PLAIN, 18));
       }
       else{
         lblModerateText = new GLabel(this, 42, 120, moderatePercent, 32);
         lblModerateText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblModerateText.setText("");
         lblModerateText.setLocalColorScheme(GCScheme.ORANGE_SCHEME);
         lblModerateText.setOpaque(true);
         lblModerateTextInfo = new GLabel(this, 42+moderatePercent, 120, 416-moderatePercent, 32);
         lblModerateTextInfo.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
         lblModerateTextInfo.setText(moderateMin);
         lblModerateTextInfo.setLocalColorScheme(GCScheme.ORANGE_SCHEME);
         lblModerateTextInfo.setOpaque(false);
         lblModerateTextInfo.setFont(new Font("Monospaced", Font.PLAIN, 18));
       }
      
   }
   
   if(timeInHard >= 0 && timeInHard < 60){
    
   }
   else{
       String hardMin = int(timeInHard/60) + " min";
       if(hardPercent >= 208){
         lblHardText = new GLabel(this, 42, 160, hardPercent, 32);
         lblHardText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblHardText.setText(hardMin);
         lblHardText.setLocalColorScheme(GCScheme.GOLD_SCHEME);
         lblHardText.setOpaque(true);
         lblHardText.setFont(new Font("Monospaced", Font.PLAIN, 18));
       }
       else{
         lblHardText = new GLabel(this, 42, 160, hardPercent, 32);
         lblHardText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblHardText.setText("");
         lblHardText.setLocalColorScheme(GCScheme.GOLD_SCHEME);
         lblHardText.setOpaque(true);
         lblHardTextInfo = new GLabel(this, 42+hardPercent, 160, 416-hardPercent, 32);
         lblHardTextInfo.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
         lblHardTextInfo.setText(hardMin);
         lblHardTextInfo.setLocalColorScheme(GCScheme.GOLD_SCHEME);
         lblHardTextInfo.setOpaque(false);
          lblHardTextInfo.setFont(new Font("Monospaced", Font.PLAIN, 18));
       }
   }
   
   if(timeInMaximum >= 0 && timeInMaximum <= 60){
    
   }
   else{
      String maxMin = int(timeInMaximum/60) + " min";
       if(maximumPercent >= 208){
         lblMaximumText = new GLabel(this, 42, 200, maximumPercent, 32);
         lblMaximumText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblMaximumText.setText(maxMin);
         lblMaximumText.setLocalColorScheme(GCScheme.RED_SCHEME);
         lblMaximumText.setOpaque(true);
         lblMaximumText.setFont(new Font("Monospaced", Font.PLAIN, 18));
       }
       else{
         lblMaximumText = new GLabel(this, 42, 200, maximumPercent, 32);
         lblMaximumText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblMaximumText.setText("");
         lblMaximumText.setLocalColorScheme(GCScheme.RED_SCHEME);
         lblMaximumText.setOpaque(true);
         lblMaximumTextInfo = new GLabel(this, 42+maximumPercent, 200, 416-maximumPercent, 32);
         lblMaximumTextInfo.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
         lblMaximumTextInfo.setText(maxMin);
         lblMaximumTextInfo.setLocalColorScheme(GCScheme.RED_SCHEME);
         lblMaximumTextInfo.setOpaque(false);
         lblMaximumTextInfo.setFont(new Font("Monospaced", Font.PLAIN, 18));
       }
    
   }
   
 
  
  
  
  
   groupFitnessAfter.setVisible(0,true);
  
  
}


public void setStressScreen(){
  setMode(RelaxVStressMode);
  groupSelect.setVisible(0,false);
  btnStartStressed.setEnabled(true);
  btnStopCheckingStress.setEnabled(false);
  groupStress.setVisible(0,true);
}

public void updateStressScreen(boolean starting){
   if(starting){
    startTracking();
    btnStartStressed.setEnabled(false);
    btnStopCheckingStress.setEnabled(true);
    btnStressHome.setEnabled(false);
  }
  else{
    btnStartStressed.setEnabled(false);
    btnStopCheckingStress.setEnabled(false);
    btnStressHome.setEnabled(true);
    checkingStress = false;
  }
}



public void resetVariables(){
  totalHeartRate = 0;
  totalConfidence = 0;
  totalOxygen = 0;
  totalPointsRead = 0;
  averageRestingHeartRate = 0.0;
  averageConfidenceLevel = 0.0;
  averageOxygenLevel = 0.0;

}
