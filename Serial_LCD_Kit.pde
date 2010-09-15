/*
  Serial Enabled LCD Kit
  by: Jim Lindblom
  Based on the LiquidCrystal library and Serial LCD example by Mellis/Fried/Igoe
  
  The circuit:
  * LCD RS pin to digital pin 2
  * LCD R/W pin to digital pin 3
  * LCD Enable pin to digital pin 4
  * LCD D4 pin to digital pin 5
  * LCD D5 pin to digital pin 6
  * LCD D6 pin to digital pin 7
  * LCD D7 pin to digital pin 8
  * 10K resistor:
  * ends to +5V and ground
  * wiper to LCD VO pin (pin 3)
 
  Library originally added 18 Apr 2008
  by David A. Mellis
  library modified 5 Jul 2009
  by Limor Fried (http://www.ladyada.net)
  example added 9 Jul 2009
  by Tom Igoe 
  modified 25 July 2009
  by David A. Mellis
   
  http://www.arduino.cc/en/Tutorial/LiquidCrystal
*/

#include <LiquidCrystal.h>
#include <EEPROM.h>

#define LCD_BACKLIGHT_ADDRESS 1  // EEPROM address for backlight setting
#define BAUD_ADDRESS 2  // EEPROM address for Baud rate setting
#define SPLASH_SCREEN_ADDRESS 3 // EEPROM address for splash screen on/off
#define BACKLIGHT_COMMAND 128  // 0x80
#define SPECIAL_COMMAND 254 // 0xFE
#define BAUD_COMMAND 129  // 0x81

char BLPin = 9;
char inKey;
char Cursor = 0;
char LCDOnOff = 1;
char blinky = 0;
char underline = 0;
int splashScreenEnable = 1;

// initialize the library with the numbers of the interface pins
LiquidCrystal lcd(2, 3, 4, 5, 6, 7, 8);

void setup(){
  // set up the LCD's number of rows and columns: 
  lcd.begin(16, 2, 0);
  
  // initialize the serial communications:
  setBaudRate(EEPROM.read(BAUD_ADDRESS));
  
  // Set up the backlight
  pinMode(BLPin, OUTPUT);
  setBacklight(EEPROM.read(LCD_BACKLIGHT_ADDRESS));
  
  // Do splashscreen if set
  splashScreenEnable = EEPROM.read(SPLASH_SCREEN_ADDRESS);
  if (splashScreenEnable!=0)
  {
    lcd.print("www.SparkFun.com");
    lcd.setCursor(0, 1);
    lcd.print(" Serial LCD Kit ");
    delay(2000);
    lcd.clear();
  }
}

void loop()
{
    while (Serial.available() > 0) {
      inKey = Serial.read();
      // Check for special LCD command
      if ((inKey&0xFF) == SPECIAL_COMMAND)
        SpecialCommands();
      // Backlight control
      else if ((inKey&0xFF) == BACKLIGHT_COMMAND)
      {
        // Wait for the next character
        while(Serial.available() == 0)
          ;
        setBacklight(Serial.read());
      }
      // baud rate control
      else if ((inKey&0xFF) == BAUD_COMMAND)
      {
        // Wait for the next character
        while(Serial.available() == 0)
          ;
        setBaudRate(Serial.read());
      }
      // backspace
      else if (inKey == 8)
      {
        Cursor--;
        LCDDisplay(0x20);
        Cursor--;
      }
      // horizontal tab
      else if (inKey == 9)
        Cursor += 5;
      // line feed
      else if (inKey == 10)
      {
        Cursor += 16;
        if (Cursor < 32)
          Cursor = 16;
        else
          Cursor = 0;
      }
      // carriage return
      else if (inKey == 13)
        Cursor += 16;
      // finally, just display the character
      else
        LCDDisplay(inKey);
    }
}

void SpecialCommands()
{
  // Wait for the next character
  while(Serial.available() == 0)
    ;
  inKey = Serial.read();
  // Clear Display
  if (inKey == 1)
  {
    Cursor = 0;
    lcd.clear();
  }
  // Move cursor right one
  else if (inKey == 20)
    Cursor++;
  // Move cursor left one
  else if (inKey == 16)
    Cursor--;
  // Scroll right
  else if (inKey == 28)
    lcd.scrollDisplayRight();
  // Scroll left
  else if (inKey == 24)
    lcd.scrollDisplayLeft();
  // Turn display on
  else if ((inKey == 12)&&(LCDOnOff==0))
  {
    LCDOnOff = 1;
    lcd.display();
  }
  // Turn display off
  else if (inKey == 8)
  {
    LCDOnOff = 0;
    lcd.noDisplay();
  }
  // Underline Cursor on
  else if (inKey == 14)
  {
    underline = 1;
    blinky = 0;
    lcd.noBlink();
    lcd.cursor();
  }
  // Underline Cursor off
  else if ((inKey == 12)&&(underline==1))
  {
    underline = 0;
    lcd.noCursor();
  }
  // Blinking box cursor on
  else if (inKey == 13)
  {
    lcd.noCursor();
    lcd.blink();
    blinky = 1;
    underline = 0;
  }
  // Blinking box cursor off
  else if ((inKey == 12)&&(blinky=1))
  {
    blinky = 0;
    lcd.noBlink();
  }
  // Set Cursor position
  else if ((inKey&0xFF) == 128)
  {
    // Wait for the next character
    while(Serial.available() == 0)
      ;
    inKey = Serial.read();
    Cursor = inKey;
  }
  else if (inKey == 30)
  {
    if (splashScreenEnable)
      splashScreenEnable = 0;
    else
      splashScreenEnable = 1;
    EEPROM.write(SPLASH_SCREEN_ADDRESS, splashScreenEnable);
  }
}

void LCDDisplay(char character)
{
  int currentRow = 0;
  
  // If Cursor is beyond screen size, get it right
  while (Cursor >= 32)
    Cursor -= 32;
  while (Cursor < 0)
    Cursor += 32;
  
  if (Cursor >= 16)
    currentRow = 1;
    
  lcd.setCursor(Cursor%16, currentRow);
  lcd.write(character);
  
  Cursor++;
}

void setBacklight(uint8_t backlightSetting)
{
  analogWrite(BLPin, backlightSetting);
  EEPROM.write(LCD_BACKLIGHT_ADDRESS, backlightSetting);
}

void setBaudRate(uint8_t baudSetting)
{
  // If EEPROM is unwritten (0xFF), set it to 9600 by default
  if (baudSetting==255)
    baudSetting = 4;
    
  switch(baudSetting)
  {
    case 0:
      Serial.begin(300);
      break;
    case 1:
      Serial.begin(1200);
      break;
    case 2:
      Serial.begin(2400);
      break;
    case 3:
      Serial.begin(4800);
      break;
    case 4:
      Serial.begin(9600);
      break;
    case 5:
      Serial.begin(14400);
      break;
    case 6:
      Serial.begin(19200);
      break;
    case 7:
      Serial.begin(28800);
      break;
    case 8:
      Serial.begin(38400);
      break;
    case 9:
      Serial.begin(57600);
      break;
    case 10:
      Serial.begin(115200);
      break;
  }
  if ((baudSetting>=0)&&(baudSetting<=10))
    EEPROM.write(BAUD_ADDRESS, baudSetting);
}

