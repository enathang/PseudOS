

_user_mode_entry:
	la a0, user_mode_welcome
	call _write_uart
	wfi

