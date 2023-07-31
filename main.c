extern void _write_hello_init();
extern void _write_uart(char*);

void c_main(void) {
	_write_hello_init();
	_write_uart("Hello from c_main!\0");
}
