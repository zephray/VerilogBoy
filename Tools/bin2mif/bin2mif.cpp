// bin2mif.cpp : 定义控制台应用程序的入口点。
//

#include "stdafx.h"
#include <iostream>
#include <fstream>

using namespace std;

int main(int argc, char * argv[])
{
	int size;
	if (argc == 4) {
		size = atoi(argv[3]);
	}
	else if (argc == 3) {
		size = 256; // Default GB BROM Size
	}
	else {
		cout << "Usage: bin2mif <input.bin> <output.mif> [size]" << endl;
		return -1;
	}
	
	ifstream inFile(argv[1], ios::in | ios::binary);
	ofstream outFile(argv[2], ios::out | ios::trunc);
	
	uint8_t* buffer;

	buffer = (uint8_t *)malloc(size);
	inFile.read((char *)buffer, size);
	for (int i = 0; i < size; i++) {
		outFile << std::hex << buffer[i] << endl;
	}

	inFile.close();
	outFile.close();

    return 0;
}

