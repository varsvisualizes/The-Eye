/*

 Final Project - The Eye
 
 This project shows an eye that watches the person as they walk back and forth. If you get too close, the Eye will get angry.
 
 If you stand still for a while, the Eye will fall asleep. You’ll need to wake it up! If you move back and forth too quickly, the Eye will get dizzy.
 
 Please run the cVargas_Final Arduino code before executing this program.
 
 The Dizzy function was based on the code in this Stack Overflow forum by Kevin Workman: 
 https://stackoverflow.com/questions/34842502/processing-how-do-i-make-an-object-move-in-a-circular-path
 
 The Ani code is based on the Ani_Sequence example from looksgood.de: 
 http://www.looksgood.de/libraries/Ani/examples/Ani_Sequence_Basics/Ani_Sequence_Basics.pde
  
 20 Dec 2021
 Carmen Vargas
 
 */

/*------------- Start Variables —------------*/

// Importing the Serial, Sound, and Ani libraries
import processing.serial.*;
import processing.sound.*;
import de.looksgood.ani.*;

// Establish Arduino and variables for incoming values
Serial myPort;
String val;
int[] intVals;

// variable names for the sensor values
int distance_eye;
int distance_closeness;
int photocell;
int soundDetector;

// establish Sound variables
SoundFile neutralSound;
SoundFile angrySound;
SoundFile tooClose;

// array for images of the Eye opening and closing
PImage[] eyeNeutral = new PImage[20];

// variable for angry eye expression
PImage eyeAngry;

// variable for squinting eye expression
PImage eyeSquint;

// variable for shocked eye expression
PImage eyeShocked;

// Variables for the animation
AniSequence seq1;
AniSequence seq2;
int indexNeutral;
float animSpeed = 0.01;

// x-value for the pupil's location
float x_distance;
float pupilX;

// size of the Eye of the pupil
int pupilSize;

// openFlag to determine whether the Eye is opened or closed
boolean openFlag = false;

// make the Eye sleep if the person is still for over 5 seconds
// (will run 3x in draw)
boolean sleepyFlag = false;
int pauseStart;
int pauseTrigger = 2000;

// Variables to track how long the person has been standing still
int positionTracker[] = new int[3];
int positionIndex;

// Variable to determine the reaction of the Eye when woken up
int reactionVal;

// Variables for the Dizzy Trick function
// if you go back and forth quickly enough, the Eye will get "dizzy"
boolean dizzyFlag = false;
int dizzyCounter;
PVector centerPoint;
float angle;
float radius;

int startTime;
int endTime;
int trigger = 3000;

int endCounter = 0;

/*------------- End Variables —------------*/

void setup() {
  size(1000, 1000);

  // Arduino setup
  myPort = new Serial(this, Serial.list()[2], 9600);

  // add in the expression images
  eyeAngry = loadImage("Angry_eye_transparent.png");
  eyeSquint = loadImage("Squinting_eye_transparent.png");
  eyeShocked = loadImage("Shocked_eye_transparent.png");

  // initiate the animation images
  for (int i = 0; i < 20; i++) {
    eyeNeutral[i] = loadImage("EyeClosing_File_" + i + ".png");
  }

  // initialize the animation
  Ani.init(this);
  indexNeutral = 0;

  // Create sequence to close the Eye
  seq1 = new AniSequence(this);
  seq1.beginSequence();
  for (int i = 0; i < 20; i++) {
    seq1.add(Ani.to(this, animSpeed, "indexNeutral", i));
  }
  seq1.endSequence();

  // start the whole sequence
  // seq1.start();
  // println("Begin eye-opening animation");

  // Create sequence to open the Eye
  seq2 = new AniSequence(this);
  seq2.beginSequence();

  for (int i = 19; i > -1; i--) {
    seq2.add(Ani.to(this, animSpeed, "indexNeutral", i));
  }

  seq2.endSequence();

  // loading up the Sound files
  neutralSound = new SoundFile(this, "BackgroundNeutral_1.wav");
  angrySound = new SoundFile(this, "BackgroundAngry_1.wav");
  tooClose = new SoundFile(this, "BackgroundTooClose_1.wav");

  // start a timer for the movement of the person
  pauseStart = millis();

  // Calculations for the Dizzy Trick
  centerPoint = new PVector(width/2, (0.45*height));
  PVector point = new PVector((width/2)+100, (0.45*height)+75);

  float deltaX = centerPoint.x - point.x;
  float deltaY = centerPoint.y - point.y;
  angle = atan2(deltaX, deltaY);
  radius = dist(centerPoint.x, centerPoint.y, point.x, point.y);

  ellipseMode(RADIUS);

  // initialize the size of the pupil
  pupilSize = 45;
}

// Assign Arduino readings into an array
void serialEvent (Serial myPort) {
  // if the Arduino is available
  if (myPort.available() > 0) {

    // read the values as they come in
    val = myPort.readStringUntil('\n');

    // So long as we have values . . .
    if (val != null) {

      // Trim off any whitespace in the incoming values
      val = trim(val);

      // Split the values based on the delimiter, "split", and place them
      // in the intVals array
      intVals = int(split(val, "split"));

      // assign the value for the distance sensor that determines
      // the pupil positition
      distance_eye = intVals[0];
      //println("Distance for the eye is = " + distance_eye);

      // assign the value for the distance sensor that determines
      // the closeness of the person
      distance_closeness = intVals[1];
      //println("How close you stand to the sensor is = " + distance_closeness);

      // assign the value for the photocell to determine the light value
      photocell = intVals[2];
      //println("Photocell is = " + photocell);

      // assign the value for the sound detector to determine sound values
      soundDetector = intVals[3];
      //println("Sound Detector is = " + photocell);
    }
  }
}

void draw() {
  background(0);

  // convert distance_eye to float so we can map it across the screen
  // This will be our pupil’s x-position
  // Please calibrate distance sensor

  if (distance_eye < 150) {
    pupilX = float(distance_eye);
    pupilX = map(pupilX, 0, 150, 800, 200);
  } else if (distance_eye >= 150) {
    pupilX = width/2;
  }

  /*-------- Print statements to un-comment when I want to check my sensors —----*/

  // println("PupilX is " + pupilX);
  // println("Distance_eye is = " + distance_eye);
  // println("Distance closeness sensor is " + distance_closeness);
  //  println("Photocell val is " + photocell);
  // println("Sound detector val = " + soundDetector);

  image(eyeNeutral[indexNeutral], 0, 0);

  // if the room is dark, then open the Eye and display the pupil
  // Please calibrate light sensor to your environment

  if (photocell < 200) {
    openFlag = true;
    eyeOpen(openFlag);
    fill(255, 255, 255);
    circle(pupilX, (0.45*height), pupilSize);

    // check if the Eye fell asleep
    sleepyFunction();
    
    // check if we made the Eye dizzy
    dizzyCheck();

    // check if we've startled the Eye
    if (soundDetector >= 30) {
      // If the Eye is asleep, wake it up!
      if (sleepyFlag == true) {
        sleepyFlag = false;
        eyeReact();
      }
      // if the Eye is not asleep, make it blink!
      else {
        openFlag = false;
        eyeOpen(openFlag);
        delay(1000);
      }
    }
  }
  // if the room is bright, close the Eye
  else if (photocell >= 400) {
    openFlag = false;
    eyeOpen(openFlag);
    println("Too bright");
  }

  // if the person is within a certain range of ultrasonic sensor 2, we'll
  // hear specific music and get a certain reaction from the Eye.
  // Please calibrate distance sensor to preferred "closeness"
  // The music will stop playing when the Eye is "asleep"
  
    // If the person is imminently close
    if (distance_closeness < 15) {
      
      // Can't sleep!
      sleepyFlag = false;
      
      // display the angry eye
      background(0);
      image(eyeAngry, 0, 0);
      ellipse(pupilX, (0.45*height), pupilSize, pupilSize);
      
      // Stop playing the neutral and angry sounds and play the alarm sound
      if (neutralSound.isPlaying()) {
        neutralSound.pause();
      }
      if (angrySound.isPlaying()) {
        angrySound.pause();
      }
      if (tooClose.isPlaying()==false) {
        tooClose.play();
        // println("Too Close is "  + tooClose.isPlaying());
      }
    }
    // If the person is approaching but not too close
    else if (distance_closeness >= 15 && distance_closeness < 30) {
      
      // Can't sleep!
      sleepyFlag = false;
      
     // display the Squinting eye
      background(0);
      image(eyeSquint, 0, 0);
      ellipse(pupilX, (0.45*height), pupilSize, pupilSize);
      
     // Play the angry sound and stop the neutral / alarm sounds
      if (neutralSound.isPlaying()) {
        neutralSound.pause();
      }
      if (tooClose.isPlaying()) {
        tooClose.pause();
      }
      if (angrySound.isPlaying()==false) {
        angrySound.play();
        // println("Angry Sound is "  + angrySound.isPlaying());
      }
    }
    // If the person is a “safe” distance away, play the neutral sound
    else if (distance_closeness >= 30) {

      if (tooClose.isPlaying()) {
        tooClose.pause();
      }
      if (angrySound.isPlaying()) {
        angrySound.pause();
      }
      if (neutralSound.isPlaying()==false) {
        neutralSound.play();
        // println("Neutral Sound is "  + neutralSound.isPlaying());
      }
    }
  
    if (sleepyFlag == true) {
    tooClose.stop();
    angrySound.stop();
    neutralSound.stop();
  }
}

// use the openFlag boolean to determine whether
// the Eye is opened or closed

void eyeOpen(boolean openFlag) {

  if (openFlag == true) {
    seq2.start();
    //   println("openFlag is true");
  } else if (openFlag == false) {
    seq1.start();
    //   println("openFlag is false - eye will close");
  }
}

// Test if the person is standing still for over 5 seconds. If so,
// Make the Eye fall asleep.
void sleepyFunction() {

  if (sleepyFlag == false) {
    eyeOpen(openFlag);
    //println("SleepyFlag is down!");
    // circle(pupilX, (0.45*height), pupilSize);
  } else if (sleepyFlag == true) {
    println("SleepyFlag is up!");
    background(random(0, 255), random(0, 255), random(0, 255));
    openFlag = false;
    eyeOpen(openFlag);
    image(eyeNeutral[0], 0, 0);
    delay(750);
  }

  // Set a timer to check the position every 3 seconds
  if ( (millis() - pauseStart) > pauseTrigger) {
    println("Timer hit!");
    pauseStart = millis();

    // Put the position value in an array so we can compare
    // the positions after 6 seconds
    if (positionIndex < 3) {
      positionTracker[positionIndex] = distance_eye;
      positionIndex++;

      println(positionTracker);
    } else if (positionIndex >= 3) {
      // If we get a match, the person is standing still
      if (positionTracker[0] == positionTracker[1] ||
        positionTracker[1] == positionTracker[2]) {
        println("Standing still");

        sleepyFlag = true;

        //delay(500);
      }
      // Reset the position index
      positionIndex = 0;
    }
  }
}

// Randomly display a reaction when you wake up the Eye
void eyeReact() {
  reactionVal = floor(random(0, 10));
  if (reactionVal % 2 == 0) {
    println("Angry! >:(");
    background(0);
    image(eyeAngry, 0, 0);
    ellipse(width/2, (0.45*height), pupilSize, pupilSize);
    delay(250);
  } else {
    println("Sad! :(");
    background(0);
    image(eyeShocked, 0, 0);
    ellipse(width/2, (0.45*height), pupilSize, pupilSize);
    delay(250);
  }
}

void dizzyCheck() {
  // check for Dizzy–-see if the person goes way to the left,
  // then way to the right. If they do it 2x, the Eye will be dizzy.
  if (pupilX < 300) {
    dizzyFlag = true;
    println("dizzyFlag is up");
  }
  if (pupilX > 600 && dizzyFlag == true) {
    dizzyCounter++;
    dizzyFlag = false;
    println("dizzyFlag is down, counter is " + dizzyCounter);
  }
  if (dizzyCounter == 2) {
    println("Running dizzy trick");

    // Make the Eye spin like it's dizzy
    dizzyTrick();
    println("End Counter is " + endCounter);

    // Using endCounter as a timer, stop when you've hit a certain point
    // Also break if we click again to stop the function early
    if (endCounter >= 250 || dizzyCounter >= 3) {
      dizzyCounter = 0;
      endCounter = 0;
    }
  }
}

// Make the Eye spin in a loop 3x
void dizzyTrick() {
  background(0);
  image(eyeNeutral[19], 0, 0);
  float x;
  float y;
  x = centerPoint.x + cos(angle) * radius;
  y = centerPoint.y + sin(angle)* radius;
  fill(255, 255, 255);
  ellipse(x, y, pupilSize, pupilSize);
  angle += PI/50;
  endCounter++;
}
