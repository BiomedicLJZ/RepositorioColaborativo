#ifndef DIVISION_H
#define DIVISION_H

float dividir(float a, float b) {
    if (b == 0.0f) {
        throw std::invalid_argument("Division por cero no permitida.");
    }
    return a / b;
}
#endif //DIVISION_H
