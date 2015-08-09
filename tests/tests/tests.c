#include <stdio.h>
#include "test-01.h"

#define _TEST_(name) do { int result = test##name(); if (result != 0 ) { printf ("[FAIL] test%s() returns %d\n", #name, result); return result; } else {printf ("[ OK ] test%s()\n", #name);} } while (0)
int main(int argc, char* argv[]) {
	_TEST_(01);
	return 0;
}
