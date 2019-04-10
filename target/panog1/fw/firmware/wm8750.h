/*
 *  VerilogBoy
 *
 *  Copyright (C) 2019  Wenting Zhang <zephray@outlook.com>
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms and conditions of the GNU General Public License,
 *  version 2, as published by the Free Software Foundation.
 *
 *  This program is distributed in the hope it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 *  more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin St - Fifth Floor, Boston, MA 02110-1301 USA.
 */
#ifndef __WM8750_H__
#define __WM8750_H__

#include <stdint.h>

#define WM8750_LIN_VOL_ADDR                     0x00
#define WM8750_RIN_VOL_ADDR                     0x01
#define WM8750_LOUT1_VOL_ADDR                   0x02
#define WM8750_ROUT1_VOL_ADDR                   0x03
#define WM8750_ADC_DAC_CTRL_ADDR                0x05
#define WM8750_AUDIO_INTFC_ADDR                 0x07
#define WM8750_SAMPLE_RATE_ADDR                 0x08
#define WM8750_LCHAN_VOL_ADDR                   0x0A
#define WM8750_RCHAN_VOL_ADDR                   0x0B
#define WM8750_BASS_CTRL_ADDR                   0x0C
#define WM8750_TREBLE_CTRL_ADDR                 0x0D
#define WM8750_RESET_ADDR                       0x0F
#define WM8750_3D_CTRL_ADDR                     0x10
#define WM8750_ALC1_ADDR                        0x11
#define WM8750_ALC2_ADDR                        0x12
#define WM8750_ALC3_ADDR                        0x13
#define WM8750_NOISE_GATE_ADDR                  0x14
#define WM8750_LADC_VOL                         0x15
#define WM8750_RADC_VOL                         0x16
#define WM8750_ADDITIONAL_CTRL1_ADDR            0x17
#define WM8750_ADDITIONAL_CTRL2_ADDR            0x18
#define WM8750_PWR_MANAGEMENT1_ADDR             0x19
#define WM8750_PWR_MANAGEMENT2_ADDR             0x1a
#define WM8750_ADDITIONAL_CTRL3_ADDR            0x1b
#define WM8750_ADC_IN_MODE_ADDR                 0x1f
#define WM8750_ADCL_SIGNAL_PATH_ADDR            0x20
#define WM8750_ADCR_SIGNAL_PATH_ADDR            0x21
#define WM8750_LEFT_MIXER_CTRL1_ADDR            0x22
#define WM8750_LEFT_MIXER_CTRL2_ADDR            0x23
#define WM8750_RIGHT_MIXER_CTRL1_ADDR           0x24
#define WM8750_RIGHT_MIXER_CTRL2_ADDR           0x25
#define WM8750_MONO_MIXER_CTRL1_ADDR            0x26
#define WM8750_MONO_MIXER_CTRL2_ADDR            0x27
#define WM8750_LOUT2_VOL_ADDR                   0x28
#define WM8750_ROUT2_VOL_ADDR                   0x29
#define WM8750_MONOOUT_VOL_ADDR                 0x2A

#define WM8750_I2C_ADDR                         0x34

void wm8750_init();

#endif
