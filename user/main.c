#import <stdint.h>

extern void _write_hello_init();
extern void _write_uart(char*);

void c_main(void) {
	_write_uart("Hello from c_main!\0");
}

uint8_t c_add(uint8_t a, uint8_t b) {
	if (b == 0) {
		return a;
	} else {
		return 1 + c_add(a, b-1);
	}
}

extern void _write_uart_wrapper(char*);
extern void _write_register_to_uart_literal_wrapper(uint64_t, uint64_t, uint64_t);

uint64_t fibonacci(uint64_t a, uint64_t b, uint64_t count) {
	uint64_t c;

	for (uint64_t i=0; i<count; i++) {
		c = a + b;
		a = b;
		b = c;
		
	}
	_write_uart_wrapper("Next fibonacci number is: \0");
	_write_register_to_uart_literal_wrapper(c, 0, 63);
	_write_uart_wrapper("\n\0");

	return c;
}

