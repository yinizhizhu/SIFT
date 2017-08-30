#include "CImage.h"

int  CImage::get_extension(string fname) {
	char c = fname.at(fname.length() - 1);
	char c2 = fname.at(fname.length() - 3);
	if ((c == 'f') && (c2 == 'g'))		//gif 
		return 1;
	else if ((c == 'g') && (c2 == 'j')) //jpg
		return 2;
	else if ((c == 'g') && (c2 == 'p')) //png
		return 3;
	else if ((c == 'p') && (c2 == 'b')) //bmp
		return 4;
	return 0;
}

void  CImage::LoadImage(char *fname) {
	m_Width = m_Height = 0;
	ifstream ffin(fname, std::ios::binary);
	if (!ffin) {
		cout << "Can not open this file." << endl;
		return;
	}
	int result = get_extension(fname);
	char s1[2] = { 0 }, s2[2] = { 0 };
	switch (result) {
	case 1:  // gif  
		ffin.seekg(6);
		ffin.read(s1, 2);
		ffin.read(s2, 2);
		m_Width = (unsigned int)(s1[1]) << 8 | (unsigned int)(s1[0]);
		m_Height = (unsigned int)(s2[1]) << 8 | (unsigned int)(s2[0]);
		break;
	case 2:  // jpg
		ffin.seekg(164);
		ffin.read(s1, 2);
		ffin.read(s2, 2);
		m_Width = (unsigned int)(s1[1]) << 8 | (unsigned int)(s1[0]);
		m_Height = (unsigned int)(s2[1]) << 8 | (unsigned int)(s2[0]);
		break;
	case 3:   // png
		ffin.seekg(17);
		ffin.read(s1, 2);
		ffin.seekg(2, std::ios::cur);
		ffin.read(s2, 2);
		m_Width = (unsigned int)(s1[1]) << 8 | (unsigned int)(s1[0]);
		m_Height = (unsigned int)(s2[1]) << 8 | (unsigned int)(s2[0]);
		break;
	case 4:   // bmp    
		ffin.seekg(18);
		ffin.read(s1, 2);
		ffin.seekg(2, std::ios::cur);
		ffin.read(s2, 2);
		m_Width = (unsigned int)(s1[1]) << 8 | (unsigned int)(s1[0]);
		m_Height = (unsigned int)(s2[1]) << 8 | (unsigned int)(s2[0]);
		break;
	default:
		cout << "NO" << endl;
		break;
	}
	ffin.close();
};

