/*
 *  VerilogBoy
 *  
 *  dispsim.cpp: Display simulation unit
 * 
 *  Copyright (C) 2019  Wenting Zhang <zephray@outlook.com>
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms and conditions of the GNU General Public License as 
 *  published by the Free Software Foundation, either version 3 of the license,
 *  or (at your option) any later version.
 *
 *  This program is distributed in the hope it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 *  more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, see <http://www.gnu.org/licenses/> for a copy.
 */
#ifndef DISPSIM_H
#define DISPSIM_H

class DISPSIM {
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
public:    
    const int contentWidth = 160;
    const int contentHeight = 144;
    const int dispWidth = 320;
    const int dispHeight = 288;
    DISPSIM(void);
    ~DISPSIM(void);
    void apply(const unsigned char lcd_data, const unsigned char lcd_hs, 
            const unsigned char lcd_vs, const unsigned char lcd_enable); 
    void operator()(const unsigned char lcd_data, const unsigned char lcd_hs, 
            const unsigned char lcd_vs, const unsigned char lcd_enable) {
        apply(lcd_data, lcd_hs, lcd_vs, lcd_enable);
    }
};

#endif