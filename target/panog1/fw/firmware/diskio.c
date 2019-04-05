/*-----------------------------------------------------------------------*/
/* Low level disk I/O module skeleton for FatFs     (C)ChaN, 2016        */
/*-----------------------------------------------------------------------*/
/* If a working storage control module is available, it should be        */
/* attached to the FatFs via a glue function rather than modifying it.   */
/* This is an example of glue functions to attach various exsisting      */
/* storage control modules to the FatFs module with a defined API.       */
/*-----------------------------------------------------------------------*/

#include "ff.h"			/* Obtains integer types */
#include "diskio.h"		/* Declarations of disk functions */

#include "part.h"
#include "usb.h"

/* Definitions of physical drive number for each drive */
#define DEV_USB		0	/* Map USB MSD to physical drive 0 */

static int init_finished = 0;
static block_dev_desc_t *msd;

/*-----------------------------------------------------------------------*/
/* Get Drive Status                                                      */
/*-----------------------------------------------------------------------*/

DSTATUS disk_status (
	BYTE pdrv		/* Physical drive nmuber to identify the drive */
)
{
	if ((pdrv == 0) && init_finished)
		return 0;
	else 
		return STA_NOINIT;
}



/*-----------------------------------------------------------------------*/
/* Inidialize a Drive                                                    */
/*-----------------------------------------------------------------------*/

DSTATUS disk_initialize (
	BYTE pdrv				/* Physical drive nmuber to identify the drive */
)
{
	DSTATUS stat;
	uint32_t devid;

	switch (pdrv) {
	case DEV_USB :
		if (init_finished) {
			return 0;
		}
		else {
			devid = usb_stor_scan(1);
    		if (devid == -1) {
        		return STA_NOINIT;
    		}
    		msd = usb_stor_get_dev(devid);
			init_finished = 1;
		}
		return 0;
	}
	return STA_NOINIT;
}



/*-----------------------------------------------------------------------*/
/* Read Sector(s)                                                        */
/*-----------------------------------------------------------------------*/

DRESULT disk_read (
	BYTE pdrv,		/* Physical drive nmuber to identify the drive */
	BYTE *buff,		/* Data buffer to store read data */
	DWORD sector,	/* Start sector in LBA */
	UINT count		/* Number of sectors to read */
)
{
	DRESULT res;
	int result;

	switch (pdrv) {
	case DEV_USB :
		result = msd->block_read(msd->dev, sector, count, buff);
		if (result != count)
			return RES_NOTRDY;
		else
			return RES_OK;
	}

	return RES_PARERR;
}



/*-----------------------------------------------------------------------*/
/* Write Sector(s)                                                       */
/*-----------------------------------------------------------------------*/

#if FF_FS_READONLY == 0

DRESULT disk_write (
	BYTE pdrv,			/* Physical drive nmuber to identify the drive */
	const BYTE *buff,	/* Data to be written */
	DWORD sector,		/* Start sector in LBA */
	UINT count			/* Number of sectors to write */
)
{
	DRESULT res;
	int result;

	switch (pdrv) {
	case DEV_USB :
		// not supported, yet.
		return RES_NOTRDY;
	}

	return RES_PARERR;
}

#endif


/*-----------------------------------------------------------------------*/
/* Miscellaneous Functions                                               */
/*-----------------------------------------------------------------------*/

DRESULT disk_ioctl (
	BYTE pdrv,		/* Physical drive nmuber (0..) */
	BYTE cmd,		/* Control code */
	void *buff		/* Buffer to send/receive control data */
)
{
	DRESULT res;
	int result;

	switch (pdrv) {
	case DEV_USB :

		if (cmd == GET_SECTOR_COUNT) {
			*(uint32_t *)buff = msd->lba;
			return RES_OK;
		}
		else if (cmd == GET_SECTOR_SIZE) {
			*(uint32_t *)buff = msd->blksz;
			return RES_OK;
		}

		return RES_NOTRDY;
	}

	return RES_PARERR;
}

