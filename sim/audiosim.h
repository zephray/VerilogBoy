//
// VerilogBoy simulator
// Copyright 2022 Wenting Zhang
//
// audiosim.h: Capture PDM output and pass through a filter then save to wave
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

// 4M->48K: 88 times decimation
#define DECIMATION_M        88

class AUDIOSIM {
public:
    AUDIOSIM(void);
    ~AUDIOSIM(void);
    void save(const char *fname);
    void apply(uint8_t left, uint8_t right);
    void bypass(int16_t left, int16_t right);
private:
    int sample_counter;
    std::vector<int16_t> pcm;
    void save_wav(const char *fname, std::vector<int16_t> &pcm);
};
