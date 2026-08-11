#include <stdint.h>

volatile uint32_t last_exception;

static uint32_t read_ipsr(void) {
    uint32_t ipsr;

    __asm volatile (
        "mrs %0, ipsr"
        : "=r" (ipsr)
    );

    return ipsr;
}

void default_handler(void) {
    last_exception = read_ipsr();

    while (1) {
    }
}

void hard_fault_handler(void) {
    while (1) {
    }
}

void nmi_handler(void) {
    while (1) {
    }
}