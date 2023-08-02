#import <stdint.h>

extern void _write_hello_init();
extern void _write_uart(char*);

void c_main(void) {
	_write_hello_init();
	_write_uart("Hello from c_main!\0");
}

uint8_t c_add(uint8_t a, uint8_t b) {
	if (b == 0) {
		return a;
	} else {
		return 1 + c_add(a, b-1);
	}
}
