/*
  Final Project - The Eye. 

  In the Processing file, an Eye will be generated and follow your movements back and
  forth. If you get too close, it will set off an alarm. The Eye prefers when it's dark,
  and if it falls asleep, you can wake it up by clapping at the sound detector. 

  The Smoothing function for this code was based on the example written by David A. Mellis.
  https://www.arduino.cc/en/Tutorial/BuiltInExamples/Smoothing
  
  The Sound Detector set-up is based on the tutorial from SparkFun. 
  https://learn.sparkfun.com/tutorials/sound-detector-hookup-guide?_ga=2.16477758.960734892.1639737868-1922730318.1639737868

  The Ultrasonic Sensor set-up was based on the tutorial by the YouTube channel, How to 
  Mechatronics.
  https://www.youtube.com/watch?v=ZejQOX69K5M
  
*/

// initiate the pins for the ultrasonic 1
// x-position ultrasonic
int trigPin1 = 9;
int echoPin1 = 10;

// initiate pins for ultrasonic 2
// front-facing ultrasonic
int trigPin2 = 5;
int echoPin2 = 6;

// initiate the photocell
int photocellPin = 0;
int photocellReading;

// initiate sound detector
int soundGatePin = 2;
int gateInterruptPin = 0;
int soundLED = 13;
int soundPin = A4;
int soundReading;

// ultrasonic calculation values
long duration1;
long duration2;
int distance1_unsmoothed;
int distance1;
int distance2;

// array of values to send to Processing
int values[4];

// smooth out the ultrasonic 1 readings
// using Tom Igoe's code
const int numReadings = 10;

int readings[numReadings];      // the readings from the analog input
int readIndex = 0;              // the index of the current reading
int total = 0;                  // the running total
int average = 0;                // the average


// soundISR() function updates the sound reading as the program runs
void soundISR() {

  int pin_val;
  pin_val = digitalRead(soundGatePin);
  digitalWrite(soundLED, pin_val);

}

void setup() {

  // Set up the ultrasonic pins
  pinMode(trigPin1, OUTPUT);
  pinMode(trigPin2, OUTPUT);
  pinMode(echoPin1, INPUT);
  pinMode(echoPin2, INPUT);

  // Set up the sound detector
  pinMode(soundLED, OUTPUT);
  pinMode(soundGatePin, INPUT);
  attachInterrupt(gateInterruptPin, soundISR, CHANGE);

  Serial.begin(9600);

}

void loop() {

  // get the photocell reading of the room
  photocellReading = analogRead(photocellPin);

  // get the sound reading of the room
  soundReading = analogRead(soundPin);

  // If you need to check the photocell
  // Serial.print("Photocell reading = ");
  // Serial.println(photocellReading);

  // Set off the first ultrasonic sensor
  digitalWrite(trigPin1, LOW);
  delayMicroseconds(2);

  digitalWrite(trigPin1, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin1, LOW);

  duration1 = pulseIn(echoPin1, HIGH);
  distance1_unsmoothed = duration1 * 0.034 / 2;

  // Smooth the data using the Example function
  total = total - readings[readIndex];
  // read from the sensor:
  readings[readIndex] = distance1_unsmoothed;
  // add the reading to the total:
  total = total + readings[readIndex];
  // advance to the next position in the array:
  readIndex = readIndex + 1;

  if (readIndex >= numReadings) {
    readIndex = 0;
  }

  // calculate the average:
  distance1 = total / numReadings;

  // Set off the second ultrasonic sensor
  digitalWrite(trigPin2, LOW);
  delayMicroseconds(2);

  digitalWrite(trigPin2, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin2, LOW);

  duration2 = pulseIn(echoPin2, HIGH);
  distance2 = duration2 * 0.034 / 2;

  // Assign sensor values to the array
  values[0] = distance1;
  values[1] = distance2;
  values[2] = photocellReading;
  values[3] = soundReading;

  //Serial print the values so Processing can read them
   Serial.println(String(values[0]) + "split" + String(values[1]) +
                   "split" + String(values[2]) + "split" + String(values[3]));

// Uncomment these print statements as needed when you want to check sensor values.
//  Serial.print("Distance 1 = ");
//  Serial.print(values[0]);
//  Serial.print('\t');
//  Serial.print("Distance 2 = ");
//  Serial.print(values[1]);
//  Serial.print('\t');
//  Serial.print("Photocell = ");
//  Serial.print(values[2]);
//  Serial.print('\t');
//  Serial.print("Sound detector = ");
//  Serial.println(values[3]);

  delay(50);
}
