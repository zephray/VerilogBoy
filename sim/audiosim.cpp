//
// VerilogBoy simulator
// Copyright 2022 Wenting Zhang
//
// audiosim.cpp: Capture PDM output and pass through a filter then save to wave
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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <assert.h>
#include <vector>
#include "audiosim.h"
#include "waveheader.h"

AUDIOSIM::AUDIOSIM(void) {
    pcm.clear();
    sample_counter = 0;
}

AUDIOSIM::~AUDIOSIM(void) {

}

void AUDIOSIM::save(const char *fname) {
    save_wav(fname, pcm);
}

void AUDIOSIM::save_wav(const char *fname, std::vector<int16_t> &pcm) {
    uint8_t header[44];
    waveheader(header, 48000, 16, pcm.size() / 2);
    FILE *fp;
    fp = fopen(fname, "wb+");
    fwrite(header, 44, 1, fp);
    fwrite(&pcm[0], pcm.size() * 2, 1, fp);
    fclose(fp);
    printf("Audio save to %s\n", fname);
}

void AUDIOSIM::apply(uint8_t left, uint8_t right) {
    sample_counter++;
    if (sample_counter == DECIMATION_M) {
        sample_counter = 0;
        pcm.push_back(left);
        pcm.push_back(right);
    }
}
