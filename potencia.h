#ifndef POTENCIA_H
#define POTENCIA_H
#include <cmath>

inline int potencia(int base, int exponente) {
    int resultado = 1;
    for (int i = 0; i < exponente; ++i) {
        resultado *= base;
    }
    return resultado;
}

#endif // POTENCIA_H
