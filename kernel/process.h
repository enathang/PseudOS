#import <stdint.h>

enum process_status { READY, WAITING, DEAD  };

struct process {
	uint64_t* root_page_table;
	uint64_t pid;
	uint64_t parent_pid;
	char* name;

	enum process_status status;
};
