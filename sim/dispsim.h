//
// VerilogBoy simulator
// Copyright 2022 Wenting Zhang
//
// dispsim.h: Display simulation unit
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

class DISPSIM {
public:    
    const int contentWidth = 160;
    const int contentHeight = 144;
    const int dispWidth = 320;
    const int dispHeight = 288;
    DISPSIM(void);
    ~DISPSIM(void);
    void apply(const unsigned char lcd_data, const unsigned char lcd_hs, 
            const unsigned char lcd_vs, const unsigned char lcd_enable); 
    void set_title(char *title);
private:
    static constexpr int HBP = 1;
    static constexpr int VBP = 2;
    static constexpr int REFRESH_INTERVAL = 20;
    SDL_Surface       *screen           = NULL;
    SDL_Window        *window           = NULL;
    SDL_Renderer      *renderer         = NULL;
    SDL_Texture       *texture          = NULL;
    SDL_Rect           textureRect;
    unsigned char last_vs;
    unsigned char last_hs;
    int xCounter;
    int yCounter;
    int tick;
    void renderCopy(void);
    void setPixel(int x, int y, unsigned long pixel);
    unsigned long colorMap(unsigned char pixel);
};
