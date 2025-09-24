#include "task_lib.h"

#define WIDTH TASK_VIEWPORT_WIDTH
#define HEIGHT TASK_VIEWPORT_HEIGHT

#define SHARED_SCORE_BASE_VADDR (PAGE_ON_DEMAND_BASE_VADDR + 0xF00)
#define CANT_PONGS 3


void task(void) {
	screen pantalla;
	// ¿Una tarea debe terminar en nuestro sistema?
	while (true)
	{
		uint32_t* scores = (uint32_t*) SHARED_SCORE_BASE_VADDR;

		for (int i = 0; i < CANT_PONGS; ++i) {
			task_print(pantalla, "Puntaje Pong", 8, 9 + i*2, C_FG_LIGHT_GREY);
			task_print_dec(pantalla, i + 1, 1, 21, 9 + i*2, C_FG_LIGHT_GREY);
			task_print_dec(pantalla, scores[i * 2 + 0], 2, 25, 9 + i*2, C_FG_CYAN);
			task_print_dec(pantalla, scores[i * 2 + 1], 2, 28, 9 + i*2, C_FG_MAGENTA);
		}

		syscall_draw(pantalla);
	}
}
