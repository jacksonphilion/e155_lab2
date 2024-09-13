/*********************************************************************
*                    SEGGER Microcontroller GmbH                     *
*                        The Embedded Experts                        *
**********************************************************************

-------------------------- END-OF-HEADER -----------------------------

File    : main.c
Purpose : Generic application start

Jackson Philion, Sep.2.2024, jphilion@g.hmc.edu. Starter code from E155 github, Prof Josh Brake.

*/

#include <stdio.h>
#include <stdlib.h>
// Include the device header
#include <stm32l432xx.h>

/*********************************************************************
*
*       main()
*
*  Function description
*   Application entry point.
*/

int main(void) {
  // Initialization code

  RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN;

  // Set PA6 and PA10 as an output
  // GPIOA->MODER |=  (GPIO_MODER_MODE10_0);
  // GPIOA->MODER &= ~(GPIO_MODER_MODE10_1);

  // Jackson set PA6 as an output
  GPIOA->MODER |=  (GPIO_MODER_MODE6_0);
  GPIOA->MODER &= ~(GPIO_MODER_MODE6_1);

  // Jackson set PB3 as an output
  GPIOB->MODER |=  (GPIO_MODER_MODE3_0);
  GPIOB->MODER &= ~(GPIO_MODER_MODE3_1);

  // Set PA9 as an input
  GPIOA->MODER &= ~GPIO_MODER_MODE9_0;
  GPIOA->MODER &= ~GPIO_MODER_MODE9_1;

  // Jackson Test set PA10 as an input
  GPIOA->MODER &= ~GPIO_MODER_MODE10_0;
  GPIOA->MODER &= ~GPIO_MODER_MODE10_1;


  // Initialization code
  // Read input on PA9 and output on PA6; then, in on PA10 and out on PB3.
  while(1) {
    if ((GPIOA->IDR >> 9) & 0x1) {
      GPIOA->ODR |= (1 << 6);
      }
    else {
      GPIOA->ODR &= ~(1 << 6);
    }
    if ((GPIOA->IDR >> 10) & 0x1) {
      GPIOB->ODR |= (1 << 3);
      }
    else {
      GPIOB->ODR &= ~(1 << 3);
    }
  }
}

/*************************** End of file ****************************/
