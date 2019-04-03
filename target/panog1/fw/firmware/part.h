/*
 * (C) Copyright 2000-2004
 * Wolfgang Denk, DENX Software Engineering, wd@denx.de.
 *
 * See file CREDITS for list of people who contributed to this
 * project.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */
#ifndef _PART_H
#define _PART_H

typedef struct block_dev_desc {
	int		dev;		/* device number */
	unsigned char	target;		/* target SCSI ID */
	unsigned char	lun;		/* target LUN */
	unsigned char	type;		/* device type */
	unsigned char	removable;	/* removable device */
	unsigned long	lba;		/* number of blocks */
	unsigned long	blksz;		/* block size */
	char		vendor [40+1];	/* IDE model, SCSI Vendor */
	char		product[20+1];	/* IDE Serial no, SCSI product */
	char		revision[8+1];	/* firmware revision */
	unsigned long	(*block_read)(int dev,
				      unsigned long start,
				      unsigned long blkcnt,
				      void *buffer);
	unsigned long	(*block_write)(int dev,
				       unsigned long start,
				       unsigned long blkcnt,
				       const void *buffer);
	void		*priv;		/* driver private struct pointer */
}block_dev_desc_t;

#endif /* _PART_H */
