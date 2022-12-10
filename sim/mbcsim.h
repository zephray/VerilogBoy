//
// VerilogBoy simulator
// Copyright 2022 Wenting Zhang
//
// memsim.h: Cartridge with memory bank controller (MBC) simulation
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
#pragma once

#define MBC_RAM_SIZE (128*1024)
#define MBC_ROM_SIZE (8*1024*1024)

class MBCSIM {
public:
    MBCSIM(void);
    ~MBCSIM(void);
    void load(const char *fname);
    void apply(const uint8_t wr_data, const uint16_t address, const uint8_t wr,
        const uint8_t rd, uint8_t &rd_data);
private:
    typedef enum {
        MBCNONE,
        MBC1,
        MBC2,
        MBC3,
        MBC5,
        MBCUNKNOWN
    } MBCTYPE;

    uint8_t *rom;
    uint8_t *ram;
    MBCTYPE mbc_type;
    char ram_enable;
    char mbc_mode;
    unsigned int rom_bank;
    unsigned int ram_bank;
};
