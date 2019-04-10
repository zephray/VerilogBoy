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
#ifndef __ISP1760_H__
#define __ISP1760_H__

#define ISP_BASE_ADDR 0x04000000
#define isp_reset_pin *((volatile uint32_t *)0x0300001c)

#define ISP_CAPLENGTH            0x0000
#define ISP_HCIVERSION           0x0002
#define ISP_HCSPARAMS            0x0004
#define ISP_HCCPARAMS            0x0008
#define ISP_USBCMD               0x0020
#define ISP_USBSTS               0x0024
#define ISP_USBINTR              0x0028
#define ISP_FRINDEX              0x002C
#define ISP_CONFIGFLAG           0x0060
#define ISP_PORTSC1              0x0064
#define ISP_ISO_PTD_DONEMAP      0x0130
#define ISP_ISO_PTD_SKIPMAP      0x0134
#define ISP_ISO_PTD_LASTPTD      0x0138
#define ISP_INT_PTD_DONEMAP      0x0140
#define ISP_INT_PTD_SKIPMAP      0x0144
#define ISP_INT_PTD_LASTPTD      0x0148
#define ISP_ATL_PTD_DONEMAP      0x0150
#define ISP_ATL_PTD_SKIPMAP      0x0154
#define ISP_ATL_PTD_LASTPTD      0x0158
#define ISP_HW_MODE_CONTROL      0x0300
#define ISP_CHIP_ID              0x0304
#define ISP_SCRATCH              0x0308
#define ISP_SW_RESET             0x030C
#define ISP_DMA_CONFIGURATION    0x0330
#define ISP_BUFFER_STATUS        0x0334
#define ISP_ATL_DONE_TIMEOUT     0x0338
#define ISP_MEMORY               0x033C
#define ISP_EDGE_INTERRUPT_COUNT 0x0340
#define ISP_DMA_START_ADDRESS    0x0344
#define ISP_POWER_DOWN_CONTROL   0x0354
#define ISP_PORT_1_CONTROL       0x0374

#define ISP_INTERRUPT            0x0310
#define ISP_INTERRUPT_ENABLE     0x0314
#define ISP_ISO_IRQ_MASK_OR      0x0320
#define ISP_INT_IRQ_MASK_OR      0x031C
#define ISP_ATL_IRQ_MASK_OR      0x0320
#define ISP_ISO_IRQ_MASK_AND     0x0324
#define ISP_INT_IRQ_MASK_AND     0x0328
#define ISP_ATL_IRQ_MASK_AND     0x032C

// Bitfields for few registers
#define ISP_BUFFER_STATUS_ATL_FILLED   (1u << 0)
#define ISP_BUFFER_STATUS_INT_FILLED   (1u << 1)
#define ISP_BUFFER_STATUS_ISO_FILLED   (1u << 2)

#define ISP_USBCMD_RESET    (1u << 1)
#define ISP_USBCMD_RUN      (1u << 0)

#define ISP_SW_RESET_HC     (1u << 1)
#define ISP_SW_RESET_ALL    (1u << 0)

#define ISP_CONFIGFLAG_CF   (1u << 0)

#define ISP_PORTSC1_PO      (1u << 13)
#define ISP_PORTSC1_PP      (1u << 12)
#define ISP_PORTSC1_PR      (1u << 8)
#define ISP_PORTSC1_SUSP    (1u << 7)
#define ISP_PORTSC1_FPR     (1u << 6)
#define ISP_PORTSC1_PED     (1u << 2)
#define ISP_PORTSC1_ECSC    (1u << 1)
#define ISP_PORTSC1_ECCS    (1u << 0)

#define ISP_INTERRUPT_ISO   (1u << 9)
#define ISP_INTERRUPT_ATL   (1u << 8)
#define ISP_INTERRUPT_INT   (1u << 7)
#define ISP_INTERRUPT_CLKREADY   (1u << 6)
#define ISP_INTERRUPT_HC_SUSP    (1u << 5)
#define ISP_INTERRUPT_DMAEOTINT  (1u << 3)
#define ISP_INTERRUPT_SOFITLINT  (1u << 1)

// These are refering to the ISP1760 internal memory address
#define MEM_ISO_BASE             0x0000
#define MEM_INT_BASE             0x0080
#define MEM_ATL_BASE             0x0100
#define MEM_PAYLOAD_BASE         0x0180

// ISP1760 internal memory address mapped in ISP1760 PIO interface address
#define MEM_BASE                 0x0400

#define PTD_SIZE_BYTE            (32)
#define PTD_SIZE_DWORD           (8)

#define MAX_EP_NUM               (16)

#define STALL_RETRY_NUM          (1000)
#define NACK_TIMEOUT_MS          (10)
#define SETUP_TIMEOUT_MS         (10)

#define MAX_REG_INT_TRANSFER_NUM (2)

// This should match the define in u-boot
typedef enum {
    SPEED_FULL = 0,
    SPEED_LOW = 1,
    SPEED_HIGH = 2
} usb_speed_t;

// Endpoint Type used in PTD
typedef enum {
    EP_CONTROL = 0,
    EP_ISOCHRONOUS = 1,
    EP_BULK = 2,
    EP_INTERRUPT = 3
} usb_ep_type_t;

// Transaction PID Token used in PTD
typedef enum {
    TOKEN_OUT = 0,
    TOKEN_IN = 1,
    TOKEN_SETUP = 2,
    TOKEN_PING = 3  // written by hw in HS only
} usb_token_t;

// Only used for API calls, not part of PTD
typedef enum {
    DIRECTION_OUT = 0,
    DIRECTION_IN
} transfer_direction_t;

// Only used for API calls, not part of PTD
typedef enum {
    TYPE_ATL = 0,
    TYPE_INT,
    TYPE_ISO
} ptd_type_t;

typedef enum {
    ISP_SUCCESS = 0,
    ISP_GENERAL_FAILURE,
    ISP_NOT_IMPLEMENTED,
    ISP_NACK_TIMEOUT,  // Device keeps NAK
    ISP_SETUP_TIMEOUT, // Unable to setup the transfer
    ISP_WRONG_LENGTH,  // Readback transferred length incorrect
    ISP_TRANSFER_HALT, // H bit being marked in the PTD
    ISP_BABBLE,        // B bit being marked in the PTD
    ISP_TRANSFER_ERROR,// X bit being marked in the PTD
} isp_result_t;

typedef enum {
    STATE_IDLE = 0,
    STATE_SCHEDULED,
    STATE_FINISHED
} transfer_state_t;

typedef struct interrupt_transfer {
    struct usb_device *device;
    unsigned long pipe;
    void *buffer;
    int length;
    transfer_state_t state;
} interrupt_transfer_t;

int isp_init();

// Internal Functions
isp_result_t isp_transfer(ptd_type_t ptd_type, usb_speed_t speed,
        transfer_direction_t direction, usb_token_t token, 
        uint32_t device_address, uint32_t parent_port, uint32_t parent_address, 
        uint32_t max_packet_length, uint32_t *toggle,  usb_ep_type_t ep_type,
        uint32_t ep, uint8_t *buffer, uint32_t max_length, uint32_t *length,
        int need_setup);
void isp_build_header(usb_speed_t speed, usb_token_t token, uint32_t device_address,
        uint32_t parent_port, uint32_t parent_address, uint32_t toggle,
        usb_ep_type_t ep_type, uint32_t ep, uint32_t *ptd, 
        uint32_t payload_address, uint32_t length, uint32_t max_packet_length);

// External API is defined in usb.h
#endif
