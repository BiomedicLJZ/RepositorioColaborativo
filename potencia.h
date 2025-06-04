#include <iostream>
#include "potencia.h"

int main() {
    float f = 2.0f;
    double d = 3.0;
    long double ld = 4.0;

    std::cout << "float: 2^3 = " << potencia(f, 3.0f) << std::endl;
    std::cout << "double: 2^3 = " << potencia(d, 3.0) << std::endl;
    std::cout << "long double: 2^3 = " << potencia(ld, 3.0L) << std::endl;

    return 0;
}
