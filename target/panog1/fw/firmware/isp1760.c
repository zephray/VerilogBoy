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
#include "isp_roothub.h"

#undef USE_ROOT_HUB

#undef ISP_DEBUG

#ifdef ISP_DEBUG
#define debug_print(x) term_print(x)
#define debug_print_hex(x,d) term_print_hex(x,d)
#define	debug_printf(fmt, args...) printf(fmt , ##args)
#else
#define debug_print(x)
#define debug_print_hex(x,d)
#define	debug_printf(fmt, args...)
#endif

interrupt_transfer_t registered_transfers[USB_MAX_DEVICE];

// Define the interrupts that the driver will handle
#define ISP_INT_MASK  0x00000080

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
        address += 4;
    }
}

isp_result_t isp_wait(uint32_t address, uint32_t mask, uint32_t value, 
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
        debug_print("Failed to reset the ISP1760!\n");
        return;
    }*/

    isp_write_dword(ISP_HW_MODE_CONTROL, 0x00000000);
    isp_write_dword(ISP_HW_MODE_CONTROL, 0x00000000);

    // Clear USB reset command
    value &= ~ISP_USBCMD_RESET;
    isp_write_dword(ISP_USBCMD, value);

    // Config port 1
    // Config as USB HOST (On ISP1761 it can also be device)
    isp_write_dword(ISP_PORT_1_CONTROL, 0x00800018);

    // Configure interrupt here
    isp_write_dword(ISP_INTERRUPT, ISP_INT_MASK);

    isp_write_dword(ISP_INTERRUPT_ENABLE, ISP_INT_MASK);

    isp_write_dword(ISP_HW_MODE_CONTROL, 0x80000000);
    delay_ms(50);
    isp_write_dword(ISP_HW_MODE_CONTROL, 0x00000000);

    isp_write_dword(ISP_ATL_IRQ_MASK_AND, 0x00000000);
    isp_write_dword(ISP_ATL_IRQ_MASK_OR,  0x00000000);
    isp_write_dword(ISP_INT_IRQ_MASK_AND, 0x00000000);
    isp_write_dword(ISP_INT_IRQ_MASK_OR,  0x00000001);
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

#ifndef USE_ROOT_HUB
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
#endif

    return 0;
}

void isp_enable_irq(uint32_t enable) {
    isp_write_dword(ISP_INTERRUPT_ENABLE, enable);
}

isp_result_t isp_transfer(ptd_type_t ptd_type, usb_speed_t speed,
        transfer_direction_t direction, usb_token_t token, 
        uint32_t device_address, uint32_t parent_port, uint32_t parent_address, 
        uint32_t max_packet_length, uint32_t *toggle,  usb_ep_type_t ep_type,
        uint32_t ep, uint8_t *buffer, uint32_t max_length, uint32_t *length,
        int need_setup) {
    isp_result_t result = ISP_SUCCESS;
    uint32_t payload_address;
    uint32_t ptd_address;
    uint32_t reg_ptd_donemap;
    uint32_t reg_ptd_skipmap;
    uint32_t reg_ptd_lastptd;
    uint32_t buffer_status_filled;
    uint32_t start_ptd[PTD_SIZE_DWORD], readback_ptd[PTD_SIZE_DWORD];
    uint32_t start_ticks;
    uint32_t actual_transfer_length;

    payload_address = MEM_PAYLOAD_BASE;

    switch(ptd_type) {
        case TYPE_ATL:
            debug_print("A");
            ptd_address = MEM_ATL_BASE;
            reg_ptd_donemap = ISP_ATL_PTD_DONEMAP;
            reg_ptd_skipmap = ISP_ATL_PTD_SKIPMAP;
            reg_ptd_lastptd = ISP_ATL_PTD_LASTPTD;
            buffer_status_filled = ISP_BUFFER_STATUS_ATL_FILLED;
            break;
        case TYPE_INT:
            debug_print("I");
            ptd_address = MEM_INT_BASE;
            reg_ptd_donemap = ISP_INT_PTD_DONEMAP;
            reg_ptd_skipmap = ISP_INT_PTD_SKIPMAP;
            reg_ptd_lastptd = ISP_INT_PTD_LASTPTD;
            buffer_status_filled = ISP_BUFFER_STATUS_INT_FILLED;
            break;
        case TYPE_ISO:
            // not supported
        default:
            debug_print("ERR");
            result = ISP_NOT_IMPLEMENTED;
            return result;
    }

    if (need_setup) {
        // Disable all existing PTD entries
        isp_write_dword(reg_ptd_skipmap, 0xffffffff);

        // If direction is output, write payload into ISP1760
        if ((direction == DIRECTION_OUT) && (*length != 0))
            isp_write_memory(payload_address, (uint32_t *)buffer, *length);

        // Build PTD
        isp_build_header(speed, token, device_address, parent_port, 
                parent_address, *toggle, ep_type, ep, start_ptd, 
                payload_address, 
                (direction == DIRECTION_OUT) ? (*length) : (max_length),
                max_packet_length);
    }
    
    // Transfer, only loop if NAKed
    start_ticks = ticks_ms();
    uint32_t retry;
    do {
        // Only retry when NACK
        retry = 0;

        if (need_setup) {
            // Write PTD
            isp_write_memory(ptd_address, start_ptd, PTD_SIZE_BYTE);

            // Start process PTD
            isp_write_dword(reg_ptd_skipmap, 0xfffffffe);
            isp_write_dword(reg_ptd_lastptd, 0x00000001);

            // Indicate ATL PTD is filled, start process
            isp_write_dword(ISP_BUFFER_STATUS, buffer_status_filled);

            // If the transfer is a interrupt transfer, stop here.
            if (ep_type == EP_INTERRUPT) 
                return 0;
        }
        
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
                debug_print("NACK");
                delay_us(100);
            }
            // Check H bit
            else if (readback_ptd[3] & (1u << 30)) {
                // halt, do not retry
                result = ISP_TRANSFER_HALT;
                debug_print("HALT");
            }
            // Check B bit
            else if (readback_ptd[3] & (1u << 29)) {
                result = ISP_BABBLE;
                debug_print("BABBLE");
            }
            // Check X bit
            else if (readback_ptd[3] & (1u << 28)) {
                result = ISP_TRANSFER_ERROR;
                debug_print("ERR");
            }
            else if ((direction == DIRECTION_OUT) && 
                    (actual_transfer_length != *length)) {
                result = ISP_WRONG_LENGTH;
                debug_print("WLEN");
            }
            else {
                *toggle = (readback_ptd[3] >> 25) & 0x1;
                result = ISP_SUCCESS;
                debug_print("OK");
            }
        }
        else {
            debug_print("STO");
            result = ISP_SETUP_TIMEOUT;
        }

        // No matter what happens, end this PTD
        isp_write_dword(reg_ptd_skipmap, 0xffffffff);
    // only retry if: NAKed, not timed out, setup is required in this call
    } while (retry && ((ticks_ms() - start_ticks) < NACK_TIMEOUT_MS) && 
            need_setup);

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

    debug_print(".");

    return result;
}

void isp_build_header(usb_speed_t speed, usb_token_t token, uint32_t device_address,
        uint32_t parent_port, uint32_t parent_address, uint32_t toggle,
        usb_ep_type_t ep_type, uint32_t ep, uint32_t *ptd, 
        uint32_t payload_address, uint32_t length, uint32_t max_packet_length) {
    uint32_t multiplier;
    uint32_t port_number;
    uint32_t hub_address;
    uint32_t valid;
    uint32_t split;
    uint32_t se;
    uint32_t start_complete;
    uint32_t error_counter;
    uint32_t micro_frame;
    uint32_t micro_sa;
    uint32_t micro_scs;

    debug_print("D");
    debug_print_hex(parent_address, 2);
    debug_print(":");
    debug_print_hex(parent_port, 2);
    debug_print(":");
    debug_print_hex(device_address, 2);
    debug_print(" ");
    debug_print((speed == SPEED_HIGH) ? "HS " : "FS ");
    debug_print((token == TOKEN_IN) ? "TIN " : (token == TOKEN_OUT) ? "TOUT " : (token == TOKEN_SETUP) ? "TSETUP " : "TPING ");
    debug_print((ep_type == EP_BULK) ? "EB" : (ep_type == EP_CONTROL) ? "EC" : "EI");
    debug_print_hex(ep, 2);
    debug_print(" L");
    debug_print_hex(length, 4);
    debug_print(" ");

    multiplier = (speed == SPEED_HIGH) ? (0x1) : (0x0);
    port_number = (speed == SPEED_HIGH) ? (0x0) : (parent_port);
    hub_address = (speed == SPEED_HIGH) ? (0x0) : (parent_address);
    valid = 0x01;
    split = (speed == SPEED_HIGH) ? (0x0) : (0x1);
    se = (speed == SPEED_FULL) ? (0x0): (0x2);
    start_complete = 0x0;
    error_counter = 0x3;
    micro_frame = (ep_type == EP_INTERRUPT) ? // Polling every 8 ms for FS/LS
            ((speed == SPEED_HIGH) ? (0xff) : (0x20)) : (0x00);
    micro_sa = (ep_type == EP_INTERRUPT) ? 
            ((speed == SPEED_HIGH) ? (0xff) : (0x01)) : (0x00);
    micro_scs = (ep_type == EP_INTERRUPT) ? 
            ((speed == SPEED_HIGH) ? (0x00) : (0xfe)) : (0x00);

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
        ((se & 0x3) << 16) |
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

static int isp_submit(struct usb_device *dev, unsigned long pipe, 
        void *buffer, int length, struct devrequest *req) {
    isp_result_t result = ISP_SUCCESS;
    usb_speed_t speed = (usb_speed_t)usb_pipespeed(pipe);
    uint32_t ep = usb_pipeendpoint(pipe);
    uint32_t max_packet_length = usb_maxpacket(dev, pipe);
    uint32_t toggle = usb_gettoggle(dev, ep, usb_pipeout(pipe));
    uint32_t new_toggle;
    uint32_t address = usb_pipedevice(pipe);
    uint32_t parent_address = (dev->parent != NULL) ? dev->parent->devnum : 0;
    uint32_t parent_port = dev->portnr;
    usb_ep_type_t ep_type = 
            (usb_pipetype(pipe) == PIPE_BULK) ? EP_BULK : 
            (usb_pipetype(pipe) == PIPE_INTERRUPT) ? EP_INTERRUPT: EP_CONTROL;
    ptd_type_t ptd_type = 
            (usb_pipetype(pipe) == PIPE_INTERRUPT) ? TYPE_INT : TYPE_ATL;
    uint32_t actual_length = length;

    if ((req != NULL) && (ep_type != EP_CONTROL)) {
        printf("Suspicious request! Non control transfer with request payload.\n");
    }

    if (req != NULL) {
        // If control request is present, start SETUP transaction
        // CONTROL (ATL) OUT
        uint32_t req_length = sizeof(*req);
        result = isp_transfer(ptd_type, speed, DIRECTION_OUT, TOKEN_SETUP, 
                address, parent_port, parent_address, max_packet_length, &toggle, 
                ep_type, ep, (uint8_t *)req, 0, &req_length, true);
        toggle = 1;
        delay_us(50);
    }

    if ((length > 0 || req == NULL) && (result == ISP_SUCCESS)) {
        // If data payload provided or not a control request
        // Could be Bulk/Control IN/OUT
        transfer_direction_t direction = 
                usb_pipein(pipe) ? DIRECTION_IN : DIRECTION_OUT;
        usb_token_t token = 
                (direction == DIRECTION_IN) ? (TOKEN_IN) : (TOKEN_OUT);
        new_toggle = toggle;
        result = isp_transfer(ptd_type, speed, direction, token, address, 
                parent_port, parent_address, max_packet_length, &new_toggle, ep_type,
                ep, buffer, (uint32_t)length, (uint32_t *)&actual_length, true);
    }

    if ((req != NULL) && (result == ISP_SUCCESS)) {
        // Ack depending on previous direction
        uint32_t ack_length = 0;
        transfer_direction_t direction = 
                usb_pipein(pipe) ? DIRECTION_OUT : DIRECTION_IN;
        usb_token_t token = 
                (direction == DIRECTION_IN) ? (TOKEN_IN) : (TOKEN_OUT);
        result = isp_transfer(ptd_type, speed, direction, token, address, 
                parent_port, parent_address, max_packet_length, &toggle, ep_type,
                ep, NULL, 0, &ack_length, true);
    }

    switch(result) {
    case ISP_SUCCESS:
        dev->status = 0;
        usb_settoggle(dev, usb_pipeendpoint(pipe),
			    usb_pipeout(pipe), new_toggle);
        dev->act_len = actual_length;
        break;
    case ISP_TRANSFER_HALT:
        dev->status = USB_ST_STALLED;
        break;
    case ISP_TRANSFER_ERROR:
        dev->status = USB_ST_BUF_ERR;
        break;
    case ISP_BABBLE:
        dev->status = USB_ST_BABBLE_DET;
        break;
    default:
        dev->status = USB_ST_CRC_ERR;
        break;
    }
    debug_print("AL");
    debug_print_hex(actual_length, 4);
    debug_print("\n");
    /*printf("dev=%u, usbsts=%04x, p[1]=%04x\n",
            dev->devnum, isp_read_dword(ISP_USBSTS), isp_read_dword(ISP_PORTSC1));*/
    
    return (dev->status != USB_ST_NOT_PROC) ? 0 : -1;
}

#ifdef USE_ROOT_HUB
// Root hub emulation
int rootdev;
static uint16_t portreset;

static inline int min3(int a, int b, int c)Manufacturer 
Product      Core (Plus) Wired Controller
SerialNumber 
{
	if (b < a)
		a = b;
	if (c < a)
		a = c;
	return a;
}

int isp_submit_root(struct usb_device *dev, unsigned long pipe, void *buffer,
		 int length, struct devrequest *req)
{
	uint8_t tmpbuf[4];
	uint16_t typeReq;
	void *srcptr = NULL;
	int len, srclen;
	uint32_t reg;
	uint32_t status_reg;

	if ((le16_to_cpu(req->index) - 1) >= CONFIG_SYS_USB_EHCI_MAX_ROOT_PORTS) {
		printf("The request port(%d) is not configured\n",
			le16_to_cpu(req->index) - 1);
		return -1;
	}
	status_reg = ISP_PORTSC1;
	srclen = 0;

	debug_printf("req=%u (%#x), type=%u (%#x), value=%u, index=%u\n",
	      req->request, req->request,
	      req->requesttype, req->requesttype,
	      le16_to_cpu(req->value), le16_to_cpu(req->index));

	typeReq = req->request | req->requesttype << 8;

	switch (typeReq) {
	case DeviceRequest | USB_REQ_GET_DESCRIPTOR:
		switch (le16_to_cpu(req->value) >> 8) {
		case USB_DT_DEVICE:
			debug_printf("USB_DT_DEVICE request\n");
			srcptr = &descriptor.device;
			srclen = 0x12;
			break;
		case USB_DT_CONFIG:
			debug_printf("USB_DT_CONFIG config\n");
			srcptr = &descriptor.config;
			srclen = 0x19;
			break;
		case USB_DT_STRING:
			debug_printf("USB_DT_STRING config\n");
			switch (le16_to_cpu(req->value) & 0xff) {
			case 0:	/* Language */
				srcptr = "\4\3\1\0";
				srclen = 4;
				break;
			case 1:	/* Vendor */
				srcptr = "\16\3u\0-\0b\0o\0o\0t\0";
				srclen = 14;
				break;
			case 2:	/* Product */
				srcptr = "\52\3E\0H\0C\0I\0 "
					 "\0H\0o\0s\0t\0 "
					 "\0C\0o\0n\0t\0r\0o\0l\0l\0e\0r\0";
				srclen = 42;
				break;
			default:
				debug_printf("unknown value DT_STRING %x\n",
					le16_to_cpu(req->value));
				goto unknown;
			}
			break;
		default:
			debug_printf("unknown value %x\n", le16_to_cpu(req->value));
			goto unknown;
		}
		break;
	case USB_REQ_GET_DESCRIPTOR | ((USB_DIR_IN | USB_RT_HUB) << 8):
		switch (le16_to_cpu(req->value) >> 8) {
		case USB_DT_HUB:
			debug_printf("USB_DT_HUB config\n");
			srcptr = &descriptor.hub;
			srclen = 0x8;
			break;
		default:
			debug_printf("unknown value %x\n", le16_to_cpu(req->value));
			goto unknown;
		}
		break;
	case USB_REQ_SET_ADDRESS | (USB_RECIP_DEVICE << 8):
		debug_printf("USB_REQ_SET_ADDRESS\n");
		rootdev = le16_to_cpu(req->value);
		break;
	case DeviceOutRequest | USB_REQ_SET_CONFIGURATION:
		debug_printf("USB_REQ_SET_CONFIGURATION\n");
		/* Nothing to do */
		break;
	case USB_REQ_GET_STATUS | ((USB_DIR_IN | USB_RT_HUB) << 8):
		tmpbuf[0] = 1;	/* USB_STATUS_SELFPOWERED */
		tmpbuf[1] = 0;
		srcptr = tmpbuf;
		srclen = 2;
		break;
	case USB_REQ_GET_STATUS | ((USB_RT_PORT | USB_DIR_IN) << 8):
		memset(tmpbuf, 0, 4);
		reg = isp_read_dword(status_reg);
        debug_printf("USB_REQ_GET_STATUS, REG = %08x\n", reg);
		if (reg & ISP_PORTSC1_ECCS)
			tmpbuf[0] |= USB_PORT_STAT_CONNECTION;
		if (reg & ISP_PORTSC1_PED)
			tmpbuf[0] |= USB_PORT_STAT_ENABLE;
		if (reg & ISP_PORTSC1_SUSP)
			tmpbuf[0] |= USB_PORT_STAT_SUSPEND;
		if (reg & ISP_PORTSC1_PR &&
		    (portreset & (1 << le16_to_cpu(req->index)))) {
			int ret;
			/* force reset to complete */
			//reg = reg & ~(ISP_PORTSC1_PR | ISP_PORTSC1_ECSC);
			//isp_write_dword(status_reg, reg);
			ret = isp_wait(status_reg, ISP_PORTSC1_PR, 0, 2 * 1000);
			if (ret == ISP_SUCCESS)
				tmpbuf[0] |= USB_PORT_STAT_RESET;
			else
				printf("port(%d) reset error\n",
					le16_to_cpu(req->index) - 1);
		}
		if (reg & ISP_PORTSC1_PP)
			tmpbuf[1] |= USB_PORT_STAT_POWER >> 8;

		tmpbuf[1] |= USB_PORT_STAT_HIGH_SPEED >> 8;

		if (reg & ISP_PORTSC1_ECSC)
			tmpbuf[2] |= USB_PORT_STAT_C_CONNECTION;
		if (portreset & (1 << le16_to_cpu(req->index)))
			tmpbuf[2] |= USB_PORT_STAT_C_RESET;

		srcptr = tmpbuf;
		srclen = 4;
		break;
	case USB_REQ_SET_FEATURE | ((USB_DIR_OUT | USB_RT_PORT) << 8):
		reg = isp_read_dword(status_reg);
        debug_printf("USB_REQ_SET_FEATURE, REG = %08x\n", reg);
		reg &= ~ISP_PORTSC1_ECSC;
		switch (le16_to_cpu(req->value)) {
		case USB_PORT_FEAT_ENABLE:
			reg |= ISP_PORTSC1_PED;
			isp_write_dword(status_reg, reg);
			break;
		case USB_PORT_FEAT_POWER:
			reg |= ISP_PORTSC1_PP;
			isp_write_dword(status_reg, reg);
			break;
		case USB_PORT_FEAT_RESET:
            reg |= ISP_PORTSC1_PR;
            reg &= ~ISP_PORTSC1_PED;
            isp_write_dword(status_reg, reg);
            /*
                * caller must wait, then call GetPortStatus
                * usb 2.0 specification say 50 ms resets on
                * root
                */
            delay_ms(50);
            portreset |= 1 << le16_to_cpu(req->index);
            /* Clear reset */
            isp_write_dword(ISP_PORTSC1, 
                    isp_read_dword(ISP_PORTSC1) & ~(ISP_PORTSC1_PR));
			break;
		default:
			debug_printf("unknown feature %x\n", le16_to_cpu(req->value));
			goto unknown;
		}
		/* unblock posted writes */
		(void) isp_read_dword(ISP_USBCMD);
		break;
	case USB_REQ_CLEAR_FEATURE | ((USB_DIR_OUT | USB_RT_PORT) << 8):
		reg = isp_read_dword(status_reg);
        debug_printf("USB_REQ_CLEAR_FEATURE, REG = %08x\n", reg);
		switch (le16_to_cpu(req->value)) {
		case USB_PORT_FEAT_ENABLE:
			reg &= ~ISP_PORTSC1_PED;
			break;
		case USB_PORT_FEAT_C_ENABLE:
			reg = (reg & ~ISP_PORTSC1_ECSC) | ISP_PORTSC1_PED;
			break;
		case USB_PORT_FEAT_POWER:
			reg = reg & ~(ISP_PORTSC1_ECSC | ISP_PORTSC1_PP);
            break;
		case USB_PORT_FEAT_C_CONNECTION:
			reg = reg | ISP_PORTSC1_ECSC;
			break;
		case USB_PORT_FEAT_C_RESET:
			portreset &= ~(1 << le16_to_cpu(req->index));
			break;
		default:
			debug_printf("unknown feature %x\n", le16_to_cpu(req->value));
			goto unknown;
		}
		isp_write_dword(status_reg, reg);
		/* unblock posted write */
		(void) isp_read_dword(ISP_USBCMD);
		break;
	default:
		debug_printf("Unknown request\n");
		goto unknown;
	}

	delay_ms(1);
	len = min3(srclen, le16_to_cpu(req->length), length);
	if (srcptr != NULL && len > 0)
		memcpy(buffer, srcptr, len);
	else
		debug_printf("Len is 0\n");

	dev->act_len = len;
	dev->status = 0;
	return 0;

unknown:
	debug_printf("requesttype=%x, request=%x, value=%x, index=%x, length=%x\n",
	      req->requesttype, req->request, le16_to_cpu(req->value),
	      le16_to_cpu(req->index), le16_to_cpu(req->length));

	dev->act_len = 0;
	dev->status = USB_ST_STALLED;
	return -1;
}
#endif

// Periodical interrupt transfer scheduling
// -----------------------------------------------------------------------------

void isp_register_transfer(struct usb_device *dev, unsigned long pipe, 
        void *buffer, int transfer_len) {
    // new transfer must come as scheduled
    for (int i = 0; i < MAX_REG_INT_TRANSFER_NUM; i++) {
        if (registered_transfers[i].device == NULL) {
            registered_transfers[i].device = dev;
            registered_transfers[i].pipe = pipe;
            registered_transfers[i].buffer = buffer;
            registered_transfers[i].length = transfer_len;
            registered_transfers[i].state = STATE_SCHEDULED;
            debug_print("New interrupt transfer registered.\n");
            break;
        }
    }
}

void isp_deregister_transfer(struct usb_device *device) {
    for (int i = 0; i < MAX_REG_INT_TRANSFER_NUM; i++) {
        if (registered_transfers[i].device == device) {
            registered_transfers[i].device = NULL;
            break;
        }
    }
}

isp_result_t isp_finish_trasnfer(uint32_t id) {
    struct usb_device *dev = registered_transfers[id].device;
    unsigned long pipe = registered_transfers[id].pipe;
    uint32_t length = registered_transfers[id].length;
    uint8_t *buffer = registered_transfers[id].buffer;
    usb_speed_t speed = (usb_speed_t)usb_pipespeed(pipe);
    uint32_t ep = usb_pipeendpoint(pipe);
    uint32_t max_packet_length = usb_maxpacket(dev, pipe);
    uint32_t toggle = usb_gettoggle(dev, ep, usb_pipeout(pipe));
    uint32_t address = usb_pipedevice(pipe);
    uint32_t parent_address = (dev->parent != NULL) ? dev->parent->devnum : 0;
    uint32_t parent_port = dev->portnr;
    usb_ep_type_t ep_type = EP_INTERRUPT;
    ptd_type_t ptd_type = TYPE_INT;
    transfer_direction_t direction = DIRECTION_IN;
    usb_token_t token = TOKEN_IN;
    
    debug_print("FI");
    return isp_transfer(ptd_type, speed, direction, token, address, 
            parent_port, parent_address, max_packet_length, &toggle, ep_type,
            ep, buffer, (uint32_t)length, (uint32_t *)&length, false);
}

void isp_callback_irq(void) {
    for (int i = 0; i < MAX_REG_INT_TRANSFER_NUM; i++) {
        if (registered_transfers[i].device != NULL) {
            if (registered_transfers[i].state == STATE_SCHEDULED) {
                isp_result_t result = isp_finish_trasnfer(i);
                if (result == ISP_SUCCESS)
                    registered_transfers[i].device->irq_handle(
                            registered_transfers[i].device);
                registered_transfers[i].state = STATE_FINISHED;
            }
        }
    }
}

void isp_schedule(uint32_t id) {
    isp_submit(registered_transfers[id].device,
            registered_transfers[id].pipe, 
            registered_transfers[id].buffer, 
            registered_transfers[id].length, NULL);
    registered_transfers[id].state = STATE_SCHEDULED;
}

void isp_reschedule(void) {
    // should only be called when no transfers are scheduled
    for (int i = 0; i < MAX_REG_INT_TRANSFER_NUM; i++) {
        if (registered_transfers[i].device != NULL) {
            if (registered_transfers[i].state == STATE_IDLE) {
                // schedule this
                isp_schedule(i);
                return;
            }
        }
    }
    // finished but nothing has been scheduled, probably all transfers are done
    int scheduled = false;
    for (int i = 0; i < MAX_REG_INT_TRANSFER_NUM; i++) {
        registered_transfers[i].state = STATE_IDLE;
        if ((registered_transfers[i].device != NULL) && !scheduled) {
            isp_schedule(i);
            scheduled = 1;
        }
    }
}

void isp_isr(void) {
    uint32_t interrupts;
    interrupts = isp_read_dword(ISP_INTERRUPT);
    if (interrupts & ISP_INTERRUPT_INT) {
        // An interrupt transfer has completed.
        // Call the callback
        debug_print("i");
        isp_callback_irq();
        isp_reschedule();
    }
}

// External APIs
// -----------------------------------------------------------------------------

#if 1

int usb_lowlevel_init(void) {
#ifdef USE_ROOT_HUB
    rootdev = 0;
#endif

    for (int i = 0; i < USB_MAX_DEVICE; i++) {
    // be handled by the stack I guess...)
        registered_transfers[i].device = NULL;
    }
    return isp_init();
}

int usb_lowlevel_stop(void) {
    isp_reset();
}

int submit_bulk_msg(struct usb_device *dev, unsigned long pipe,
		void *buffer, int transfer_len) {
    if (usb_pipetype(pipe) != PIPE_BULK) {
		debug_print("non-bulk pipe");
		return -1;
	}
    return isp_submit(dev, pipe, buffer, transfer_len, NULL);
}
int submit_control_msg(struct usb_device *dev, unsigned long pipe, void *buffer,
		int transfer_len, struct devrequest *setup) {
    if (usb_pipetype(pipe) != PIPE_CONTROL) {
		debug_print("non-control pipe");
		return -1;
	}

#ifdef USE_ROOT_HUB
    // Emulate the root hub
	if (usb_pipedevice(pipe) == rootdev) {
		if (rootdev == 0)
			dev->speed = usb_speed_t_HIGH;
		return isp_submit_root(dev, pipe, buffer, transfer_len, setup);
	}
#endif

	return isp_submit(dev, pipe, buffer, transfer_len, setup);
}

int submit_int_msg(struct usb_device *dev, unsigned long pipe, void *buffer,
		int transfer_len, int interval) {
    if (usb_pipetype(pipe) != PIPE_INTERRUPT) {
		debug_print("non-interrupt pipe");
		return -1;
	}
    // interrupt messages usually have a callback function.
    // the callback need to be managed inside the driver
    isp_register_transfer(dev, pipe, buffer, transfer_len);

    // interval is not changeable
    return isp_submit(dev, pipe, buffer, transfer_len, NULL);
}

void usb_event_poll(void) {
    // Check if there is any interrupts, if so, call the interrupt handler
    // This is used when there is no hardware IRQs in the system
    if ((isp_read_dword(ISP_INTERRUPT) & ISP_INT_MASK) != 0) {
        isp_isr();
    }
    isp_write_dword(ISP_INTERRUPT, ISP_INT_MASK); // Clear interrupts
}

#endif
