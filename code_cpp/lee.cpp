#include "CImage.h"

int main() {
	CImage test;
	test.LoadImage("1.JPG");
	cout << "width:" << test.get_width() << endl;
	cout << "height:" << test.get_height() << endl;
	return 0;
}