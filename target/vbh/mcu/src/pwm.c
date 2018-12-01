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

#include "pwm.h"

void pwm_init(void) {
    rcc_periph_clock_enable(PWM_RCC);
    rcc_periph_clock_enable(PWM_GPIO_RCC);
    rcc_periph_clock_enable(RCC_AFIO);

    gpio_set_mode(PWM_GPIO, GPIO_MODE_OUTPUT_50_MHZ,
        GPIO_CNF_OUTPUT_ALTFN_PUSHPULL, PWM_GPIO_AF);
    gpio_primary_remap(SWJ_REMAP, PWM_REMAP);

    timer_set_mode(PWM_TIM, TIM_CR1_CKD_CK_INT, TIM_CR1_CMS_EDGE,
		       TIM_CR1_DIR_UP);
    timer_set_prescaler(PWM_TIM, 10);
    timer_set_repetition_counter(PWM_TIM, 0);
    timer_enable_preload(PWM_TIM);
    timer_continuous_mode(PWM_TIM);
    timer_set_period(PWM_TIM, 255);
    timer_disable_oc_output(PWM_TIM, PWM_OC);
	timer_set_oc_mode(PWM_TIM, PWM_OC, TIM_OCM_PWM1);
    timer_set_oc_value(PWM_TIM, PWM_OC, 127);
	timer_enable_oc_output(PWM_TIM, PWM_OC);
	timer_enable_counter(PWM_TIM);
}

void pwm_set_duty(unsigned char duty) {
    timer_set_oc_value(PWM_TIM, PWM_OC, (unsigned short)duty);
}