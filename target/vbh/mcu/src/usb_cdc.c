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

    Description: USB CDC ACM related functions

    Copyright (C) 2018 Wenting Zhang

*******************************************************************************/
#include "usb_cdc.h"
#include "misc.h"

#define UID_LEN (12 * 2 + 1) /* 12-byte, each byte turnned into 2-byte hex, then '\0'. */

static const struct usb_device_descriptor dev = {
    .bLength            = USB_DT_DEVICE_SIZE,
    .bDescriptorType    = USB_DT_DEVICE,
    .bcdUSB             = 0x0200,
    .bDeviceClass       = USB_CLASS_CDC,
    .bDeviceSubClass    = 0,
    .bDeviceProtocol    = 0,
    .bMaxPacketSize0    = USBCDC_PKT_SIZE_DAT,
    .idVendor           = DEV_VID,
    .idProduct          = DEV_PID,
    .bcdDevice          = DEV_VER,
    .iManufacturer      = STR_MAN,
    .iProduct           = STR_PROD,
    .iSerialNumber      = STR_SER,
    .bNumConfigurations = 1,
};
/*
 * This notification endpoint isn't implemented. According to CDC spec its
 * optional, but its absence causes a NULL pointer dereference in Linux
 * cdc_acm driver.
 */
static const struct usb_endpoint_descriptor comm_endp[] = {{
    .bLength            = USB_DT_ENDPOINT_SIZE,
    .bDescriptorType    = USB_DT_ENDPOINT,
    .bEndpointAddress   = EP_INT,
    .bmAttributes       = USB_ENDPOINT_ATTR_INTERRUPT,
    .wMaxPacketSize     = USBCDC_PKT_SIZE_INT,
    .bInterval          = 255,
}};

static const struct usb_endpoint_descriptor data_endp[] = {{
    .bLength            = USB_DT_ENDPOINT_SIZE,
    .bDescriptorType    = USB_DT_ENDPOINT,
    .bEndpointAddress   = EP_IN,
    .bmAttributes       = USB_ENDPOINT_ATTR_BULK,
    .wMaxPacketSize     = USBCDC_PKT_SIZE_DAT,
    .bInterval          = 1,
}, {
    .bLength            = USB_DT_ENDPOINT_SIZE,
    .bDescriptorType    = USB_DT_ENDPOINT,
    .bEndpointAddress   = EP_OUT,
    .bmAttributes       = USB_ENDPOINT_ATTR_BULK,
    .wMaxPacketSize     = USBCDC_PKT_SIZE_DAT,
    .bInterval          = 1,
}};

static const struct {
    struct usb_cdc_header_descriptor header;
    struct usb_cdc_call_management_descriptor call_mgmt;
    struct usb_cdc_acm_descriptor acm;
    struct usb_cdc_union_descriptor cdc_union;
} __attribute__((packed)) cdcacm_functional_descriptors = {
    .header = {
        .bFunctionLength    = sizeof(struct usb_cdc_header_descriptor),
        .bDescriptorType    = CS_INTERFACE,
        .bDescriptorSubtype = USB_CDC_TYPE_HEADER,
        .bcdCDC = 0x0110,
    },
    .call_mgmt = {
        .bFunctionLength    = sizeof(struct usb_cdc_call_management_descriptor),
        .bDescriptorType    = CS_INTERFACE,
        .bDescriptorSubtype = USB_CDC_TYPE_CALL_MANAGEMENT,
        .bmCapabilities     = 0,
        .bDataInterface     = 1,
    },
    .acm = {
        .bFunctionLength    = sizeof(struct usb_cdc_acm_descriptor),
        .bDescriptorType    = CS_INTERFACE,
        .bDescriptorSubtype = USB_CDC_TYPE_ACM,
        .bmCapabilities     = 0,
    },
    .cdc_union = {
        .bFunctionLength    = sizeof(struct usb_cdc_union_descriptor),
        .bDescriptorType    = CS_INTERFACE,
        .bDescriptorSubtype = USB_CDC_TYPE_UNION,
        .bControlInterface  = 0,
        .bSubordinateInterface0 = 1,
    },
};

static const struct usb_interface_descriptor comm_iface[] = {{
    .bLength              = USB_DT_INTERFACE_SIZE,
    .bDescriptorType      = USB_DT_INTERFACE,
    .bInterfaceNumber     = 0,
    .bAlternateSetting    = 0,
    .bNumEndpoints        = 1,
    .bInterfaceClass      = USB_CLASS_CDC,
    .bInterfaceSubClass   = USB_CDC_SUBCLASS_ACM,
    .bInterfaceProtocol   = USB_CDC_PROTOCOL_AT,
    .iInterface           = 0,

    .endpoint             = comm_endp,

    .extra                = &cdcacm_functional_descriptors,
    .extralen             = sizeof(cdcacm_functional_descriptors),
}};

static const struct usb_interface_descriptor data_iface[] = {{
    .bLength              = USB_DT_INTERFACE_SIZE,
    .bDescriptorType      = USB_DT_INTERFACE,
    .bInterfaceNumber     = 1,
    .bAlternateSetting    = 0,
    .bNumEndpoints        = 2,
    .bInterfaceClass      = USB_CLASS_DATA,
    .bInterfaceSubClass   = 0,
    .bInterfaceProtocol   = 0,
    .iInterface           = 0,

    .endpoint             = data_endp,
}};

static const struct usb_interface ifaces[] = {{
    .num_altsetting       = 1,
    .altsetting           = comm_iface,
}, {
    .num_altsetting       = 1,
    .altsetting           = data_iface,
}};

static const struct usb_config_descriptor config = {
    .bLength              = USB_DT_CONFIGURATION_SIZE,
    .bDescriptorType      = USB_DT_CONFIGURATION,
    .wTotalLength         = 0,
    .bNumInterfaces       = 2,
    .bConfigurationValue  = 1,
    .iConfiguration       = 0,
    .bmAttributes         = 0x80,
    .bMaxPower            = 0x32,

    .interface            = ifaces,
};

/* Buffer to be used for control requests. */
static uint8_t usbd_control_buffer[128];

static enum usbd_request_return_codes cdcacm_control_request(usbd_device *usbd_dev, struct usb_setup_data *req, uint8_t **buf,
    uint16_t *len, void (**complete)(usbd_device *usbd_dev, struct usb_setup_data *req)) {
    (void)usbd_dev;
    (void)buf;
    (void)complete;

    switch (req->bRequest) {
    case USB_CDC_REQ_SET_CONTROL_LINE_STATE: {
        /*
        * This Linux cdc_acm driver requires this to be implemented
        * even though it's optional in the CDC spec, and we don't
        * advertise it in the ACM functional descriptor.
        */
        char local_buf[10];
        struct usb_cdc_notification *notif = (void *)local_buf;

        /* We echo signals back to host as notification. */
        notif->bmRequestType = 0xa1;
        notif->bNotification = USB_CDC_NOTIFY_SERIAL_STATE;
        notif->wValue        = 0;
        notif->wIndex        = 0;
        notif->wLength       = 2;
        local_buf[8]         = req->wValue & 3;
        local_buf[9]         = 0;
        return USBD_REQ_HANDLED;
    }
    case USB_CDC_REQ_SET_LINE_CODING:
        if (*len < sizeof(struct usb_cdc_line_coding))
            return USBD_REQ_NOTSUPP;
        return USBD_REQ_HANDLED;
    }
    return USBD_REQ_NOTSUPP;
}

volatile bool usb_ready = false;

static void cdcacm_reset(void) {
    usb_ready = false;
}

static void cdcacm_data_rx_cb(usbd_device *usbd_dev, uint8_t ep)
{
    (void)ep;
    (void)usbd_dev;

    char buf[64];
    int len = usbd_ep_read_packet(usbd_dev, 0x01, buf, 64);

    if (len) {
        usbd_ep_write_packet(usbd_dev, 0x82, buf, len);
        buf[len] = 0;
    }
}

static void cdcacm_set_config(usbd_device *usbd_dev, uint16_t wValue) {
    usbd_ep_setup(usbd_dev, EP_IN , USB_ENDPOINT_ATTR_BULK, 64, cdcacm_data_rx_cb);
    usbd_ep_setup(usbd_dev, EP_OUT, USB_ENDPOINT_ATTR_BULK, 64, NULL);
    usbd_ep_setup(usbd_dev, EP_INT, USB_ENDPOINT_ATTR_INTERRUPT, 16, NULL);

    usbd_register_control_callback(
            usbd_dev,
            USB_REQ_TYPE_CLASS | USB_REQ_TYPE_INTERFACE,
            USB_REQ_TYPE_TYPE | USB_REQ_TYPE_RECIPIENT,
            cdcacm_control_request);

    if (wValue > 0) {
        usb_ready = true;
    }
}

usbd_device *usbd_dev_global;

static char serial[UID_LEN];

static const char *usb_strings[] = {
    "zephray.me",
    "VerilogBoy Virtual COM Port",
    serial,
};

void usbcdc_init()
{
    desig_get_unique_id_as_string(serial, UID_LEN);
    usbd_dev_global = usbd_init(&st_usbfs_v1_usb_driver, &dev, &config, usb_strings, 3, usbd_control_buffer, sizeof(usbd_control_buffer));
    usbd_register_set_config_callback(usbd_dev_global, cdcacm_set_config);
    usbd_register_reset_callback(usbd_dev_global, cdcacm_reset);
    nvic_enable_irq(NVIC_USB_LP_CAN_RX0_IRQ);
    nvic_enable_irq(NVIC_USB_WAKEUP_IRQ);
}


/* Application-level functions */
uint16_t usbcdc_write(void *buf, size_t len) {
    uint16_t ret;

    /* Blocking write */
    while (0 == (ret = usbd_ep_write_packet(usbd_dev_global, EP_OUT, buf, len)));
    return ret;
}

uint16_t usbcdc_putc(char c) {
    return usbcdc_write(&c, sizeof(c));
}

uint16_t usbcdc_putu32(uint32_t word) {
    //uint32_t l = __builtin_bswap32(word);
    //return usbcdc_write(&l, sizeof(word));
    /* We are using little endian, so no bit swap. */
    return usbcdc_write(&word, sizeof(word));
}

/* We need to maintain a RX user buffer since libopencm3 will throw rest of the packet away. */
char usbcdc_rxbuf[USBCDC_PKT_SIZE_DAT]; /* DMA needs access */
static uint8_t usbcdc_rxbuf_head = 0;
static uint8_t usbcdc_rxbuf_tail = 0; /* Indicates empty buffer */

uint16_t usbcdc_fetch_packet(void) {
    uint16_t ret;
    /* Blocking read. Assume RX user buffer is empty. TODO: consider setting a timeout */
    while (0 == (ret = usbd_ep_read_packet(usbd_dev_global, EP_IN, usbcdc_rxbuf, USBCDC_PKT_SIZE_DAT)));
    usbcdc_rxbuf_head = 0;
    usbcdc_rxbuf_tail = ret;
    return ret;
}

char usbcdc_getc(void) {
    char c;

    if (usbcdc_rxbuf_head >= usbcdc_rxbuf_tail) {
      usbcdc_fetch_packet();
    }

    c = usbcdc_rxbuf[usbcdc_rxbuf_head];
    usbcdc_rxbuf_head ++;
    return c;
}

uint32_t usbcdc_getu24(void) {
    uint32_t val = 0;

    val  = (uint32_t)usbcdc_getc() << 0;
    val |= (uint32_t)usbcdc_getc() << 8;
    val |= (uint32_t)usbcdc_getc() << 16;

    return val;
}

uint32_t usbcdc_getu32(void) {
    uint32_t val = 0;

    val  = (uint32_t)usbcdc_getc() << 0;
    val |= (uint32_t)usbcdc_getc() << 8;
    val |= (uint32_t)usbcdc_getc() << 16;
    val |= (uint32_t)usbcdc_getc() << 24;

    return val;
}

uint8_t usbcdc_get_remainder(char **bufpp) {
    uint8_t len = usbcdc_rxbuf_tail - usbcdc_rxbuf_head;

    *bufpp = &(usbcdc_rxbuf[usbcdc_rxbuf_head]);
    usbcdc_rxbuf_head = usbcdc_rxbuf_tail; /* Mark as used. */

    return len;
}

void usb_disconnect(void) {
    gpio_clear(GPIOA, GPIO12);
    gpio_set_mode(GPIOA, GPIO_MODE_OUTPUT_2_MHZ, GPIO_CNF_OUTPUT_PUSHPULL, GPIO12);
    delay_ms(100);
    gpio_set_mode(GPIOA, GPIO_MODE_INPUT, GPIO_CNF_INPUT_FLOAT, GPIO12);
}

/* REDIRECT */
int _write(int file, char *ptr, int len)
{
    int i;

    if (file == STDOUT_FILENO || file == STDERR_FILENO) {
        for (i = 0; i < len; i++) {
        usbcdc_putc(ptr[i]);
        }
        return i;
    }
    errno = EIO;
    return -1;
}

/* Interrupts */

static void usb_int_relay(void) {
    /* Need to pass a parameter... otherwise just alias it directly. */
    usbd_poll(usbd_dev_global);
}

void usb_wakeup_isr(void)
__attribute__ ((alias ("usb_int_relay")));

void usb_hp_can_tx_isr(void)
__attribute__ ((alias ("usb_int_relay")));

void usb_lp_can_rx0_isr(void)
__attribute__ ((alias ("usb_int_relay")));
