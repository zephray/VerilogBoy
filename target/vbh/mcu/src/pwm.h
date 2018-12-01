/*******************************************************************************

    This program is free software (firmware): you can redistribute it and/or
    modify it under the terms of  the GNU General Public License as published
    by the Free Software Foundation, either version 3 of the License, or (at
    your option) any later version.
   
    This program is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.
   
    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses/> for a copy.

    Description: Wrapper file of timer PWM function

    Copyright (C) 2018 Wenting Zhang

*******************************************************************************/
#ifndef __PWM_H__
#define __PWM_H__

#include "inc.h"

// Backlight is connected to PB3, TIM2 CH2
#define PWM_TIM      TIM2
#define PWM_RCC      RCC_TIM2
#define PWM_GPIO     GPIOB
#define PWM_GPIO_AF  GPIO_TIM2_FR_CH2
#define PWM_GPIO_RCC RCC_GPIOB
#define PWM_OC       TIM_OC2
#define PWM_REMAP    AFIO_MAPR_TIM2_REMAP_FULL_REMAP
#define SWJ_REMAP    AFIO_MAPR_SWJ_CFG_JTAG_OFF_SW_ON  // Needed by GPIO remap

void pwm_init(void);
void pwm_set_duty(unsigned char duty);

#endif