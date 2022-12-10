//
// VerilogBoy simulator
// Copyright 2022 Wenting Zhang
//
// dispsim.cpp: Display simulation unit
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
#include <SDL.h>
#include "dispsim.h"

DISPSIM::DISPSIM(void) {
    window = SDL_CreateWindow("VerilogBoy Simulation", 
            SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
            dispWidth, dispHeight, SDL_SWSURFACE);

    if (window == NULL) {
        fprintf(stderr, "Unable to create window\n");
        return;
    }

    renderer = SDL_CreateRenderer(window, -1, 
            SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);

    if (renderer == NULL)
    {
        fprintf(stderr, "Unable to create renderer\n");
        return;
    }

    screen = SDL_CreateRGBSurface(SDL_SWSURFACE, contentWidth, contentHeight, 32,
            0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000);

    textureRect.x = textureRect.y = 0;
    textureRect.w = contentWidth; 
    textureRect.h = contentHeight;

    texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, 
            SDL_TEXTUREACCESS_STREAMING, contentWidth, contentHeight);
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");

    if (screen == NULL || texture == NULL)
    {
        fprintf(stderr, "Unable to allocate framebuffer or texture\n");
        return;
    }

    xCounter = 0;
    yCounter = 0;

    SDL_FillRect(screen, &textureRect, 0xFF0000FF);
    renderCopy();
    
    tick = SDL_GetTicks();
}

DISPSIM::~DISPSIM(void) {
    if (screen != NULL)
    {
        SDL_FreeSurface(screen);
    }

    if (texture)
    {
	    SDL_DestroyTexture(texture);
    }

    if (renderer)
    {
        SDL_DestroyRenderer(renderer);
    }

    if (window)
    {
        SDL_DestroyWindow(window);
    }
}

void DISPSIM::apply(const unsigned char lcd_data, const unsigned char lcd_hs, 
            const unsigned char lcd_vs, const unsigned char lcd_enable) {
    if (!last_hs && lcd_hs) {
        xCounter = 0;
        yCounter ++;
    }
    if (!last_vs && lcd_vs) {
        // Verical sync can happen at the same time.
        yCounter = 0;
    }
    if (lcd_enable) {
        xCounter ++;
        setPixel(xCounter - HBP, yCounter - VBP, colorMap(lcd_data));
    }

    last_vs = lcd_vs;
    last_hs = lcd_hs;

    if ((SDL_GetTicks() - tick) > REFRESH_INTERVAL) {
        renderCopy();
        tick = SDL_GetTicks();
    }
}

void DISPSIM::set_title(char *title) {
    SDL_SetWindowTitle(window, title);
}

void DISPSIM::renderCopy(void) {
	void *texturePixels;
	int texturePitch;

	SDL_LockTexture(texture, NULL, &texturePixels, &texturePitch);
	memset(texturePixels, 0, textureRect.y * texturePitch);
	uint8_t *pixels = (uint8_t *)texturePixels + textureRect.y * texturePitch;
	uint8_t *src = (uint8_t *)screen->pixels;
	int leftPitch = textureRect.x << 2;
	int rightPitch = texturePitch - ((textureRect.x + textureRect.w) << 2);
	for (int y = 0; y < textureRect.h; y++, src += screen->pitch)
	{
		memset(pixels, 0, leftPitch); pixels += leftPitch;
		memcpy(pixels, src, contentWidth << 2); pixels += contentWidth << 2;
		memset(pixels, 0, rightPitch); pixels += rightPitch;
	}
	memset(pixels, 0, textureRect.y * texturePitch);
	SDL_UnlockTexture(texture);

	SDL_RenderClear(renderer);
	SDL_RenderCopy(renderer, texture, NULL, NULL);
	SDL_RenderPresent(renderer);
}

void DISPSIM::setPixel(int x, int y, unsigned long pixel) {
    uint32_t *pixels = (uint32_t *)screen->pixels;
    if ((x < 0) || (y < 0) || (x >= contentWidth) || (y >= contentHeight))
        return;
    pixels[y * contentWidth + x] = pixel;
}

unsigned long DISPSIM::colorMap(unsigned char pixel) {
    if (pixel == 3) 
        return 0xff212f25;
    else if (pixel == 2)
        return 0xff32513a;
    else if (pixel == 1)
        return 0xff658635;
    else if (pixel == 0)
        return 0xff8b9a26;
    else
        // how???
        return 0xffffffff;
}