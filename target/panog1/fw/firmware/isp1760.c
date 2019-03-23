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
#include <stdio.h>
#include <stddef.h>
#include <string.h>
#include "misc.h"
#include "term.h"
#include "usb.h"
#include "isp1760.h"

uint32_t isp_read_word(uint32_t address) {
    return *((volatile uint32_t *)(ISP_BASE_ADDR | (address << 1)));
}

uint32_t isp_read_dword(uint32_t address) {
    uint32_t l = *((volatile uint32_t *)(ISP_BASE_ADDR | (address << 1)));
    uint32_t h = *((volatile uint32_t *)(ISP_BASE_ADDR | (address << 1) | 0x4));
    return ((h << 16) | (l & 0xFFFF));
}

void isp_write_word(uint32_t address, uint32_t data) {
    *((volatile uint32_t *)(ISP_BASE_ADDR | (address << 1))) = data;
}

void isp_write_dword(uint32_t address, uint32_t data) {  
    *((volatile uint32_t *)(ISP_BASE_ADDR | (address << 1))) = data & 0xFFFF;
    *((volatile uint32_t *)(ISP_BASE_ADDR | (address << 1) | 0x4)) = data >> 16;  
}

// Datasheet, page 17
uint32_t isp_addr_mem_to_cpu(uint32_t mem_address) {
    return (mem_address << 3) + MEM_BASE;
}

uint32_t isp_addr_cpu_to_mem(uint32_t cpu_address) {
    return (cpu_address - MEM_BASE) >> 3;
}

void isp_write_memory(uint32_t address, uint32_t *data, uint32_t length) {
    address = isp_addr_mem_to_cpu(address);
    for (uint32_t i = 0; i < length; i+= 4) {
        isp_write_dword(address, *data++);
        address += 4;
    }
}

void isp_read_memory(uint32_t address, uint32_t *data, uint32_t length) {
    // TODO: What about bank address?
    // Doesn't seem to matter if read is not interleaved
    address = isp_addr_mem_to_cpu(address);
    isp_write_dword(ISP_MEMORY, address);
    for (uint32_t i = 0; i < length; i+= 4) {
        *data++ = isp_read_dword(address);
        address ++;
    }
}

ISP_RESULT isp_wait(uint32_t address, uint32_t mask, uint32_t value, 
        uint32_t timeout) {
    uint32_t start_ticks = ticks_ms();
    do {
        if (isp_read_dword(address) & mask == value)
            return ISP_SUCCESS;
        delay_us(10);
    } while ((ticks_ms() - start_ticks) < timeout);
    return ISP_GENERAL_FAILURE;
}

void isp_reset() {
    isp_reset_pin = 1;
    delay_ms(50);
    isp_reset_pin = 0;
    delay_ms(50);
    isp_reset_pin = 1;
    delay_ms(50);
}

int isp_init() {
    uint32_t value;

    // Reset the ISP1760 controller
    isp_reset();

    // Set to 16 bit mode
    isp_write_dword(ISP_HW_MODE_CONTROL, 0x00000000);
    isp_write_dword(ISP_HW_MODE_CONTROL, 0x00000000);

    // Test SCRATCH register
    isp_write_dword(ISP_SCRATCH, 0x410C0C0A);
    // change bus pattern
    value = isp_read_dword(ISP_CHIP_ID);
    value = isp_read_dword(ISP_SCRATCH);
    if (value != 0x410C0C0A) {
        term_print("ISP1760: Scratch RW test failed!\n");
        return -1;
    } 
    
    // Disable all buffers
    isp_write_dword(ISP_BUFFER_STATUS, 0x00000000);

    // Skip all transfers
    isp_write_dword(ISP_ATL_PTD_SKIPMAP, 0xffffffff);
    isp_write_dword(ISP_INT_PTD_SKIPMAP, 0xffffffff);
    isp_write_dword(ISP_ISO_PTD_SKIPMAP, 0xffffffff);

    // Clear done maps
    isp_write_dword(ISP_ATL_PTD_DONEMAP, 0x00000000);
    isp_write_dword(ISP_INT_PTD_DONEMAP, 0x00000000);
    isp_write_dword(ISP_ISO_PTD_DONEMAP, 0x00000000);

    // Reset all
    isp_write_dword(ISP_SW_RESET, ISP_SW_RESET_ALL);
    delay_ms(250);

    // Reset HC
    isp_write_dword(ISP_SW_RESET, ISP_SW_RESET_HC);
    delay_ms(250);

    // Execute reset command
    isp_write_dword(ISP_HW_MODE_CONTROL, 0x00000000);
    isp_write_dword(ISP_HW_MODE_CONTROL, 0x00000000);
    value = isp_read_dword(ISP_USBCMD);
    value |= ISP_USBCMD_RESET;
    isp_write_dword(ISP_USBCMD, value);

    delay_ms(100);
    /*if (isp_wait(ISP_USBCMD, ISP_USBCMD_RESET, 0, 250) != ISP_SUCCESS) {
        term_print("Failed to reset the ISP1760!\n");
        return;
    }*/

    isp_write_dword(ISP_HW_MODE_CONTROL, 0x00000000);
    isp_write_dword(ISP_HW_MODE_CONTROL, 0x00000000);

    // Clear USB reset command
    value &= ~ISP_USBCMD_RESET;
    isp_write_dword(ISP_USBCMD, value);

    // Configure interrupt here
    isp_write_dword(ISP_INTERRUPT, 2);

    isp_write_dword(ISP_INTERRUPT_ENABLE, 2);

    isp_write_dword(ISP_HW_MODE_CONTROL, 0x80000000);
    delay_ms(50);
    isp_write_dword(ISP_HW_MODE_CONTROL, 0x00000000);

    isp_write_dword(ISP_ATL_IRQ_MASK_AND, 0x00000000);
    isp_write_dword(ISP_ATL_IRQ_MASK_OR,  0x00000000);
    isp_write_dword(ISP_INT_IRQ_MASK_AND, 0x00000000);
    isp_write_dword(ISP_INT_IRQ_MASK_OR,  0x00000000);
    isp_write_dword(ISP_ISO_IRQ_MASK_AND, 0x00000000);
    isp_write_dword(ISP_ISO_IRQ_MASK_OR,  0xffffffff);

    // Global interrupt enable
    isp_write_dword(ISP_HW_MODE_CONTROL, 0x00000001);

    // Execute run command
    isp_write_dword(ISP_USBCMD, ISP_USBCMD_RUN);
    if (isp_wait(ISP_USBCMD, ISP_USBCMD_RUN, ISP_USBCMD_RUN, 
            50) != ISP_SUCCESS) {
        term_print("Failed to start the ISP1760!\n");
        return -1;
    }

    // Enable EHCI mode
    isp_write_dword(ISP_CONFIGFLAG, ISP_CONFIGFLAG_CF);
    if (isp_wait(ISP_CONFIGFLAG, ISP_CONFIGFLAG_CF, ISP_CONFIGFLAG_CF,
            50) != ISP_SUCCESS) {
        term_print("Failed to enable the EHCI mode!\n");
        return -1;
    }

    // Set last maps
    isp_write_dword(ISP_ATL_PTD_LASTPTD, 0x80000000);
    isp_write_dword(ISP_INT_PTD_LASTPTD, 0x80000000);
    isp_write_dword(ISP_ISO_PTD_LASTPTD, 0x00000001);

    // Config port 1
    // Config as USB HOST (On ISP1761 it can also be device)
    isp_write_dword(ISP_PORT_1_CONTROL, 0x00800018);

    // Enable port power
    isp_write_dword(ISP_PORTSC1, ISP_PORTSC1_PP);

    // Wait connection
    if (isp_wait(ISP_PORTSC1, ISP_PORTSC1_ECSC, ISP_PORTSC1_ECSC, 
            10) != ISP_SUCCESS) {
        term_print("Internal hub failed to connect!\n");
        return -1;
    }

    isp_write_dword(ISP_PORTSC1, 
            isp_read_dword(ISP_PORTSC1) | ISP_PORTSC1_ECSC);

    // Port reset
    isp_write_dword(ISP_PORTSC1, 
            ISP_PORTSC1_PP | 
            (2u << 10) | 
            ISP_PORTSC1_PR |
            ISP_PORTSC1_ECCS);
    delay_ms(50);

    // Clear reset
    isp_write_dword(ISP_PORTSC1, 
            isp_read_dword(ISP_PORTSC1) & ~(ISP_PORTSC1_PR));

    return 0;
}

void isp_enable_irq(uint32_t enable) {
    isp_write_dword(ISP_INTERRUPT_ENABLE, enable);
}

ISP_RESULT isp_transfer(ISP_PTD_TYPE ptd_type, USB_SPEED speed,
        ISP_TRANSFER_DIRECTION direction, USB_TOKEN token, 
        uint32_t device_address, uint32_t parent_port, uint32_t parent_address, 
        uint32_t max_packet_length, uint32_t toggle,  USB_EP_TYPE ep_type,
        uint32_t ep, uint8_t *buffer, uint32_t max_length, uint32_t *length) {
    ISP_RESULT result = ISP_SUCCESS;
    uint32_t payload_address;
    uint32_t ptd_address;
    uint32_t reg_ptd_donemap;
    uint32_t reg_ptd_skipmap;
    uint32_t reg_ptd_lastptd;
    uint32_t buffer_status_filled;
    uint32_t start_ptd[PTD_SIZE_DWORD], readback_ptd[PTD_SIZE_DWORD];
    uint32_t start_ticks;
    uint32_t actual_transfer_length;

    printf("111\n");

    payload_address = MEM_PAYLOAD_BASE;

    switch(ptd_type) {
        case TYPE_ATL:
            ptd_address = MEM_ATL_BASE;
            reg_ptd_donemap = ISP_ATL_PTD_DONEMAP;
            reg_ptd_skipmap = ISP_ATL_PTD_SKIPMAP;
            reg_ptd_lastptd = ISP_ATL_PTD_LASTPTD;
            buffer_status_filled = ISP_BUFFER_STATUS_ATL_FILLED;
            break;
        case TYPE_INT:
            ptd_address = MEM_INT_BASE;
            reg_ptd_donemap = ISP_INT_PTD_DONEMAP;
            reg_ptd_skipmap = ISP_INT_PTD_SKIPMAP;
            reg_ptd_lastptd = ISP_INT_PTD_LASTPTD;
            buffer_status_filled = ISP_BUFFER_STATUS_INT_FILLED;
            break;
        case TYPE_ISO:
            // not supported
        default:
            result = ISP_NOT_IMPLEMENTED;
            return result;
    }

    // Disable all existing PTD entries
    isp_write_dword(reg_ptd_skipmap, 0xffffffff);

    // If direction is output, write payload into ISP1760
    if ((direction == DIRECTION_OUT) && (*length != 0))
        isp_write_memory(payload_address, (uint32_t *)buffer, *length);

    // Build PTD
    isp_build_header(speed, token, device_address, parent_port, parent_address,
            toggle, ep_type, ep, start_ptd, payload_address, 
            (direction == DIRECTION_OUT) ? (*length) : (max_length),
            max_packet_length);

    printf("222\n");

    // Transfer, only loop if NAKed
    start_ticks = ticks_ms();
    uint32_t retry;
    do {
        // Only retry when NACK
        retry = 0;

        // Write PTD
        isp_write_memory(ptd_address, start_ptd, PTD_SIZE_BYTE);

        // Start process PTD
        isp_write_dword(reg_ptd_skipmap, 0xfffffffe);
        isp_write_dword(reg_ptd_lastptd, 0x00000001);

        // Indicate ATL PTD is filled, start process
        isp_write_dword(ISP_BUFFER_STATUS, buffer_status_filled);

        // Wait for the setup to be completed
        uint32_t donemap;
        uint32_t check_count = 0;
        do {
            delay_us(5);
            check_count++;
            donemap = isp_read_dword(reg_ptd_donemap);
        } while (!(donemap & 0x1) && (check_count < SETUP_TIMEOUT_MS*200));

        // Readback PTD header
        if (donemap & 0x1) {
            isp_read_memory(ptd_address, readback_ptd, PTD_SIZE_BYTE);
            actual_transfer_length = readback_ptd[3] & 0x7FFF;
            // Check A bit
            if (readback_ptd[3] & (1u << 31)) {
                // NACK, retry later
                result = ISP_NACK_TIMEOUT;
                retry = 1;
                term_print("NACK");
                delay_us(100);
            }
            // Check H bit
            else if (readback_ptd[3] & (1u << 30)) {
                // halt, do not retry
                result = ISP_TRANSFER_HALT;
                term_print("HALT");
            }
            // Check B bit
            else if (readback_ptd[3] & (1u << 29)) {
                result = ISP_BABBLE;
                term_print("BABBLE");
            }
            // Check X bit
            else if (readback_ptd[3] & (1u << 28)) {
                result = ISP_TRANSFER_ERROR;
                term_print("ERR");
            }
            else if ((direction == DIRECTION_OUT) && 
                    (actual_transfer_length != *length)) {
                result = ISP_WRONG_LENGTH;
                term_print("WLEN");
            }
            else {
                result = ISP_SUCCESS;
                term_print("OK");
            }
        }
        else {
            result = ISP_SETUP_TIMEOUT;
        }

        // No matter what happens, end this PTD
        isp_write_dword(reg_ptd_skipmap, 0xffffffff);
    } while (retry && ((ticks_ms() - start_ticks) < NACK_TIMEOUT_MS));

    printf("333\n");

    // If current direction is input, read payload back
    if (direction == DIRECTION_IN) {
        if (result == ISP_SUCCESS) {
            *length = actual_transfer_length;
            if ((actual_transfer_length != 0) && 
                    (actual_transfer_length <= max_length)) {
                isp_read_memory(payload_address, (uint32_t *)buffer, 
                        actual_transfer_length);
            }
        } 
        else {
            *length = 0;
        }
    }

    return result;
}

void isp_build_header(USB_SPEED speed, USB_TOKEN token, uint32_t device_address,
        uint32_t parent_port, uint32_t parent_address, uint32_t toggle,
        USB_EP_TYPE ep_type, uint32_t ep, uint32_t *ptd, 
        uint32_t payload_address, uint32_t length, uint32_t max_packet_length) {
    uint32_t multiplier;
    uint32_t port_number;
    uint32_t hub_address;
    uint32_t valid;
    uint32_t split;
    uint32_t start_complete;
    uint32_t error_counter;
    uint32_t micro_frame;
    uint32_t micro_sa;
    uint32_t micro_scs;

    multiplier = (speed == SPEED_HIGH) ? (0x1) : (0x0);
    port_number = (speed == SPEED_HIGH) ? (0x0) : (parent_port);
    hub_address = (speed == SPEED_HIGH) ? (0x0) : (parent_address);
    valid = 0x01;
    split = (speed == SPEED_HIGH) ? (0x0) : (0x1);
    start_complete = 0x0;
    error_counter = 0x3;
    micro_frame = (ep_type == EP_INTERRUPT) ? 
            ((speed == SPEED_HIGH) ? (0xff) : (0x20)) : (0x00);
    micro_sa = (ep_type == EP_INTERRUPT) ? 
            ((speed == SPEED_HIGH) ? (0xff) : (0x01)) : (0x00);
    micro_scs = (ep_type == EP_INTERRUPT) ? 
            ((speed == SPEED_HIGH) ? (0x00) : (0xff)) : (0x00);

    memset(ptd, 0, 32);
    ptd[0] = 
        ((ep & 0x1) << 31) |
        ((multiplier & 0x3) << 29) |
        ((max_packet_length & 0x7FF) << 18) |
        ((length & 0x7FFF) << 3) |
        (valid & 0x1);
    ptd[1] =
        ((hub_address & 0x7F) << 25) |
        ((port_number & 0x7F) << 18) |
        ((split & 0x1) << 14) |
        (((uint32_t)ep_type & 0x3) << 12) |
        (((uint32_t)token & 0x3) << 10) |
        ((device_address & 0x7F) << 3) |
        ((ep & 0xe) >> 1);
    ptd[2] =
        ((payload_address & 0xFFFF) << 8) |
        (micro_frame & 0xFF);
    ptd[3] =
        ((valid & 0x1) << 31) |
        ((start_complete & 0x1) << 27) |
        ((toggle & 0x1) << 25) |
        ((error_counter & 0x3) << 23);
    ptd[4] =
        (micro_sa & 0xff);
    ptd[5] =
        (micro_scs & 0xff);
    ptd[6] = 0;
    ptd[7] = 0;
}

// Glue Layer

static int isp_submit_async(struct usb_device *dev, unsigned long pipe, 
        void *buffer, int length, struct devrequest *req) {
    ISP_RESULT result = ISP_SUCCESS;
    USB_SPEED speed = (USB_SPEED)usb_pipespeed(pipe);
    uint32_t ep = usb_pipeendpoint(pipe);
    uint32_t max_packet_length = usb_maxpacket(dev, pipe);
    uint32_t toggle = usb_gettoggle(dev, ep, usb_pipeout(pipe));
    uint32_t address = usb_pipedevice(pipe);
    uint32_t parent_address = dev->parent->devnum;
    uint32_t parent_port = dev->portnr;
    USB_EP_TYPE ep_type = 
            (usb_pipetype(pipe) == PIPE_BULK) ? EP_BULK : EP_CONTROL;

    if ((req != NULL) && (ep_type != EP_CONTROL)) {
        printf("Suspicious request! Non control transfer with request payload.\n");
    }

    printf("1111\n");
    if (req != NULL) {
        // If control request is present, start SETUP transaction
        // CONTROL (ATL) OUT
        printf("2222\n");
        toggle = 0;
        uint32_t req_length = sizeof(*req);
        result = isp_transfer(TYPE_ATL, speed, DIRECTION_OUT, TOKEN_SETUP, 
                address, parent_port, parent_address, max_packet_length, toggle, 
                ep_type, ep, (uint8_t *)req, 0, &req_length);
        toggle = 1;
        delay_us(50);
    }

    printf("3333\n");
    if ((length > 0 || req == NULL) && (result == ISP_SUCCESS)) {
        // If data payload provided or not a control request
        // Could be Bulk/Control IN/OUT
        printf("4444\n");
        ISP_TRANSFER_DIRECTION direction = 
                usb_pipein(pipe) ? DIRECTION_IN : DIRECTION_OUT;
        USB_TOKEN token = 
                (direction == DIRECTION_IN) ? (TOKEN_IN) : (TOKEN_OUT);
        result = isp_transfer(TYPE_ATL, speed, direction, token, address, 
                parent_port, parent_address, max_packet_length, toggle, ep_type,
                ep, buffer, (uint32_t)length, (uint32_t *)&length);
    }

    printf("5555\n");
    if ((req != NULL) && (result == ISP_SUCCESS)) {
        // Ack depending on previous direction
        printf("6666\n");
        uint32_t ack_length = 0;
        ISP_TRANSFER_DIRECTION direction = 
                usb_pipein(pipe) ? DIRECTION_OUT : DIRECTION_IN;
        USB_TOKEN token = 
                (direction == DIRECTION_IN) ? (TOKEN_OUT) : (TOKEN_IN);
        result = isp_transfer(TYPE_ATL, speed, direction, token, address, 
                parent_port, parent_address, max_packet_length, toggle, ep_type,
                ep, NULL, 0, &ack_length);
    }

    switch(result) {
    case ISP_SUCCESS:
        dev->status = 0;
        usb_settoggle(dev, usb_pipeendpoint(pipe),
			    usb_pipeout(pipe), toggle);
        dev->act_len = 0;
        break;
    case ISP_TRANSFER_HALT:
        dev->status = USB_ST_STALLED;
        break;
    case ISP_TRANSFER_ERROR:
        dev->status = USB_ST_BUF_ERR;
        break;
    case ISP_BABBLE:
        dev->status = USB_ST_BUBBLE_DET;
        break;
    default:
        dev->status = USB_ST_CRC_ERR;
        break;
    }
    printf("dev=%u, usbsts=%04x, p[1]=%04x\n",
            dev->devnum, isp_read_dword(ISP_USBSTS), isp_read_dword(ISP_PORTSC1));
}

// External APIs

#if 1

int usb_lowlevel_init(void) {
    return isp_init();
}

int usb_lowlevel_stop(void) {
    isp_reset();
}

int submit_bulk_msg(struct usb_device *dev, unsigned long pipe,
		void *buffer, int transfer_len) {
    if (usb_pipetype(pipe) != PIPE_BULK) {
		term_print("non-bulk pipe");
		return -1;
	}
    return isp_submit_async(dev, pipe, buffer, transfer_len, NULL);
}
int submit_control_msg(struct usb_device *dev, unsigned long pipe, void *buffer,
		int transfer_len, struct devrequest *setup) {
    if (usb_pipetype(pipe) != PIPE_CONTROL) {
		term_print("non-control pipe");
		return -1;
	}

    // Why u-boot need to emulate a root device?
	//if (usb_pipedevice(pipe) == rootdev) {
	//	if (rootdev == 0)
	//		dev->speed = USB_SPEED_HIGH;
	//	return ehci_submit_root(dev, pipe, buffer, length, setup);
	//}

	return isp_submit_async(dev, pipe, buffer, transfer_len, setup);
}
int submit_int_msg(struct usb_device *dev, unsigned long pipe, void *buffer,
		int transfer_len, int interval) {
    // u-boot's ehci-hcd driver didn't implement this
    // probably it is okay? 
    term_print("int msg not supported.");
    return -1;
}

void usb_event_poll(void) {
    // ?
}

#endif