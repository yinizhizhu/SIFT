#pragma once
#ifndef CIMAGE_H
#define CIMAGE_H
#include "std.h"

class CImage {
private:
	long	m_Width;
	long	m_Height;
	int		get_extension(string fname);
public:
	CImage() :m_Width(0), m_Height(0) {};
	void LoadImage(char* fname);
	long get_width() { return m_Width; };
	long get_height() { return m_Height; };
};
#endif