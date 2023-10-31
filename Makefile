main: main.o vecAdd.o
	gcc -o main $+ -lstdc++ -lcudart

main.o: main.cpp
	gcc -c -std=c++14 -pedantic-errors -Wall -Wextra main.cpp

vecAdd.o: vecAdd.cu
	nvcc -c vecAdd.cu

clean:
	rm -f main *.o
