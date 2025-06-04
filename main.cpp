#include <iostream>

// Declaración de la función
void mostrarMenu();

int main() {
    std::cout << "Hola, bienvenido a la calculadora UNIAT" << std::endl;
    mostrarMenu();
    return 0;
}

// Definición de la función del menú
void mostrarMenu() {
    bool salir = false;
    int opcion;
    //!! CAMBIAR EL COUT DE CADA OPERACION POR LAS OPERACIONES PERTINENTES
    while (!salir) {
        std::cout << "Escoge el número de la operación a realizar:\n"
                  << "1. Suma\n"
                  << "2. Resta\n"
                  << "3. Multiplicación\n"
                  << "4. División\n"
                  << "5. Potencia\n"
                  << "6. Salir\n";

        std::cin >> opcion;

        switch (opcion) {
            case 1:
                std::cout << "Aquí va la operación de suma." << std::endl;
                break;
            case 2:
                std::cout << "Aquí va la operación de resta." << std::endl;
                break;
            case 3:
                std::cout << "Aquí va la operación de multiplicación." << std::endl;
                break;
            case 4:
                std::cout << "Aquí va la operación de división." << std::endl;
                break;
            case 5:
                std::cout << "Aquí va la operación de potencia." << std::endl;
                break;
            case 6:
                std::cout << "Saliendo de la calculadora. ¡Hasta luego!" << std::endl;
                salir = true;
                break;
            default:
                std::cout << "Opción no válida. Intenta de nuevo." << std::endl;
                break;
        }
    }
}

