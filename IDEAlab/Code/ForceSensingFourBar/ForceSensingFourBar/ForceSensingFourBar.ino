#include <Encoder.h>

//structure to hold joint control data
struct joint{
  char enPort, phPort;
  char encA, encB;
  char hallPort;
  long ticks=0;
  signed short hallAngle=0, encAngle = 0, deflectionAngle = 0;
  float deflectionDistance = 0, force =0;
  float target=0, error, pError;
  long P, D, I;
  long output;            //10
  const float kP=1, kD = 0, kI = 0;
};

//create as many stuctures as robot has joints
joint Joint[6];
//create ISR function pointer arrays
//jumping through hoops to conform to attachInterrupt()
void (*updateEncA[6])();
void (*updateEncB[6])();

//assign the arduino pin numbers to joint components
void assignJointPins(short jointNum, char enPin, char phPort, char encAPin, char encBPin, char hallPin){
  //motor ports
  Joint[jointNum].enPort = enPin;
  Joint[jointNum].phPort = phPort;
  //encoder ports
  Joint[jointNum].encA = encAPin;
  Joint[jointNum].encB = encBPin;
  //hall effect port
  Joint[jointNum].hallPort = hallPin;
}

//ISR function pointers point to the corresonding functions, ugh
//jumping through hoops, is there a better way?????????
void setupISRs(){
  updateEncA[0] = updateEnc0A;
  updateEncB[0] = updateEnc0B;
  updateEncA[1] = updateEnc1A;
  updateEncB[1] = updateEnc1B;
  updateEncA[2] = updateEnc2A;
  updateEncB[2] = updateEnc2B;
  //that's enough for now . . .
}

//function to configure pins for a joint
void initializeJoint(short jointNum) {
  //motor pins
  pinMode(Joint[jointNum].enPort, OUTPUT);
  pinMode(Joint[jointNum].phPort, OUTPUT);
  //encoder pins

  //should we use pullup????????
  // pinMode(Joint[jointNum].encA, INPUT);
  // pinMode(Joint[jointNum].encB, INPUT);
  //encoders use interrupts
  //attachInterrupt(Joint[jointNum].encA, updateEncA[jointNum], FALLING);
  //attachInterrupt(Joint[jointNum].encB, updateEncB[jointNum], FALLING);
  //hall effect port is analog
}

void setup() {
  //initialize serial
  Serial.begin(9600);
  //pins for first (0th) joint
  //motor driver needs PWM, encoder needs interrupts
  assignJointPins(0, 2, 3, 4, 5, 0);
  //point to the ISRs
  //setupISRs();
  //initialize 0th Joint now that pin numbers have been assigne;
  initializeJoint(0);
}
Encoder myEnc(4, 5);

//general function for updateing any ticks when encoder pin when falling
void encUpdateA(char otherPin, short jointNum){
  if(!digitalRead(otherPin))
    Joint[jointNum].ticks++;
  else
    Joint[jointNum].ticks--;
}
void encUpdateB(char otherPin, short jointNum){
  if(digitalRead(otherPin))
    Joint[jointNum].ticks++;
  else
    Joint[jointNum].ticks--;
}

//more jumping through hoops to avoid parameters in attachInterrupt()
void updateEnc0A(){
  encUpdateA(Joint[0].encB, 0);
}
void updateEnc0B(){
  encUpdateB(Joint[0].encA, 0);
}
void updateEnc1A(){
  encUpdateA(Joint[1].encB, 1);
}
void updateEnc1B(){
  encUpdateB(Joint[1].encA, 1);
}
void updateEnc2A(){
  encUpdateA(Joint[2].encA, 2);
}
void updateEnc2B(){
  encUpdateB(Joint[2].encB, 2);
} // that's enough for now . . .

//position contoller
//just PD for now, D could prob use more tuning
void pControlUpdate(short jointNum){
  //perform proportional calc
  Joint[jointNum].error = Joint[jointNum].target-Joint[jointNum].ticks;
  Joint[jointNum].P=Joint[jointNum].kP*Joint[jointNum].error;

  //perform derivative calc
  Joint[jointNum].D = (Joint[jointNum].error - Joint[jointNum].pError)*Joint[jointNum].kD;

  //no integral yet
  // if(Joint[jointNum].error < 100)
  //   Joint[jointNum].I -= Joint[jointNum].error;

  //sum to output motor command, scaling constants have already been applied
  Joint[jointNum].output = Joint[jointNum].P + Joint[jointNum].D;

  //if we are going backwards, reverse phase pin and use positive PWM
  if(Joint[jointNum].output < 0){
    Joint[jointNum].output = abs(Joint[jointNum].output);
    digitalWrite(Joint[jointNum].phPort,LOW);
  } //otherwise we are going forwards
  else
    digitalWrite(Joint[jointNum].phPort,HIGH);
  //limit to max PWM value
  if(Joint[jointNum].output > 255)
    Joint[jointNum].output = 255;

  //record previous error
  Joint[jointNum].pError = Joint[jointNum].error;

  //send PWM to motor
  analogWrite(Joint[jointNum].enPort,Joint[jointNum].output);
}

void hallAngleUpdate(short jointNum){
  const short maxField=404, centerField=273, minField=260;
  const short fieldRange = 2*(maxField - centerField);
  int newAngle;
  newAngle = 90*(short)(analogRead(Joint[jointNum].hallPort)-centerField)/fieldRange;
  Joint[jointNum].hallAngle = .5*Joint[jointNum].hallAngle + .5*newAngle;
}

void encAngleUpdate(short jointNum){
  const unsigned int countsPerEdgePerChannel = 3, numChannels = 2, numEdges = 2, gearRatio = 300;
  const unsigned long countsPerRev = countsPerEdgePerChannel*numChannels*numEdges*gearRatio;
  const double ticksPerDegree = (double) countsPerRev/360;
  Joint[jointNum].encAngle = Joint[jointNum].ticks/ticksPerDegree;
}

void deflecionUpdate(short jointNum){
  const unsigned char length = 4;
  float rad;
  const float kS = .0743;
  const float defk = .695;
  const float kSdeg = .001141;
  Joint[jointNum].deflectionAngle = Joint[jointNum].encAngle + Joint[jointNum].hallAngle;
  rad = (float) Joint[jointNum].deflectionAngle/180*3.14159;
  Joint[jointNum].deflectionDistance = length*sin(rad);
  Joint[jointNum].force = Joint[jointNum].deflectionAngle*kSdeg;
}

void angleVsSignal(){
  hallAngleUpdate(0);
  encAngleUpdate(0);
  Serial.print(analogRead(Joint[0].hallPort));
  Serial.print(", ");
  Serial.print(Joint[0].hallAngle);
  Serial.print(", ");
  Serial.print(Joint[0].encAngle);
  Serial.println("; ");
}

void forceVsForce(){
  hallAngleUpdate(0);
  encAngleUpdate(0);
  deflecionUpdate(0);
  Serial.println(Joint[0].force, 5);
}

void maintainUntilMaxForce(float maxForce){
  float forceOverload;
  hallAngleUpdate(0);
  encAngleUpdate(0);
  deflecionUpdate(0);
  forceOverload = Joint[0].force - maxForce;
  if(forceOverload > 0){
    Joint[0].target--;
  }
  pControlUpdate(0);
}

void maintainForce(float targetForce, int maxPos, int minPos){
  float forceError;
  hallAngleUpdate(0);
  encAngleUpdate(0);
  deflecionUpdate(0);
  forceError= targetForce - Joint[0].force;
  Joint[0].target += forceError*100;
  if(Joint[0].target > maxPos)
    Joint[0].target = maxPos;
  else if(Joint[0].target < minPos)
    Joint[0].target = minPos;
  pControlUpdate(0);
}

void loop() {
  Joint[0].ticks = myEnc.read();
  //put your main code here, to run repeatedly:
  //set target
  //Joint[0].target = 0;
  //update 0th joint
  //pControlUpdate(0);

  // //print error to terminal
  //Serial.println(Joint[0].error);
  //maintainUntilMaxForce(.02);
  //angleVsSignal();
  //forceVsForce();
  maintainForce(.02, 200, -400);
  Serial.println(analogRead(1));

  // Serial.print("Hall analog, angle: ");
  // Serial.print(analogRead(Joint[0].hallPort));
  // Serial.print(", ");
  // Serial.println(Joint[0].hallAngle);
  // Serial.print("Encoder angle: ");
   //Serial.println(Joint[0].ticks);
  // Serial.print("Deflection angle: ");
  // Serial.println(Joint[0].deflectionAngle);
  // Serial.println(Joint[0].force*6.0/(5.0/16.0), 5);
  delay(20);
}

