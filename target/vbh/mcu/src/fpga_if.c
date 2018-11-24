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

    Description: FPGA communication functions

    Copyright (C) 2018 Wenting Zhang

*******************************************************************************/
#include "fpga_if.h"
#include "misc.h"

#define fpga_deselect() gpio_set(GPIOA, GPIO4)
#define fpga_select() gpio_clear(GPIOA, GPIO4)

void fpga_setup(void) {
    rcc_periph_clock_enable(RCC_GPIOA);
    rcc_periph_clock_enable(RCC_AFIO);
    rcc_periph_clock_enable(RCC_SPI1);

    // Configure GPIOs: SS=PA4, SCK=PA5, MISO=PA6 and MOSI=PA7
    gpio_set_mode(GPIOA, GPIO_MODE_OUTPUT_50_MHZ,
        GPIO_CNF_OUTPUT_ALTFN_PUSHPULL, GPIO5 | GPIO7 );
    gpio_set_mode(GPIOA, GPIO_MODE_OUTPUT_50_MHZ, 
        GPIO_CNF_OUTPUT_PUSHPULL, GPIO4);
    gpio_set_mode(GPIOA, GPIO_MODE_INPUT, GPIO_CNF_INPUT_FLOAT, GPIO6);

    // Deselect
    fpga_deselect();

    // Reset SPI, SPI_CR1 register cleared, SPI is disabled
    spi_reset(SPI1);

    // Set up SPI in Master mode with:
    // Clock baud rate: 1/32 of peripheral clock frequency
    // Clock polarity: Idle Low
    // Clock phase: Data valid on 1st clock pulse
    // Data frame format: 8-bit
    // Frame format: MSB First
    // Basically SPI mode 0
    spi_init_master(SPI1, SPI_CR1_BAUDRATE_FPCLK_DIV_32, 
        SPI_CR1_CPOL_CLK_TO_0_WHEN_IDLE, SPI_CR1_CPHA_CLK_TRANSITION_1, 
        SPI_CR1_DFF_8BIT, SPI_CR1_MSBFIRST);

    // Set NSS management to software.
    // Note: Setting nss high is very important, even if we are controlling
    // the GPIO ourselves this bit needs to be at least set to 1, otherwise 
    // the spi peripheral will not send any data out.
    spi_enable_software_slave_management(SPI1);
    spi_set_nss_high(SPI1);

    // Enable SPI1
    spi_enable(SPI1);
}

void fpga_write_reg(uint8_t addr, uint8_t data) {
    fpga_select();
    spi_send(SPI1, addr);
    spi_read(SPI1);
    spi_send(SPI1, data);
    spi_read(SPI1);
    fpga_deselect();
}

uint8_t fpga_read_reg(uint8_t addr) {
    uint8_t data;

    // Send the address
    fpga_select();
    spi_send(SPI1, addr);
    spi_read(SPI1); // make sure read out the data
    fpga_deselect();

    // Wait for FPGA to finish read
    delay_fast_loop(3);
    
    // Read back the value
    fpga_select();
    spi_send(SPI1, 0x00);
    data = spi_read(SPI1);
    fpga_deselect();

    return data;
}

void fpga_init(void) {
    //fpga_write_reg(0x2a, 0x55);
    for (int i = 0; i < 0x100; i++) {
        fpga_write_reg(i, 255 - i);
    }
    for (int i = 0; i < 0x100; i++) {
        printf("fpga: read reg %02xh = %02xh\r\n", i, fpga_read_reg(i));
    }
    
}