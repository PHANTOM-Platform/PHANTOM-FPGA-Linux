#First we must build a version of the shared library for the host architecture, rather
#than cross-compiling for the Zynq
cd ..
make clean
#We pass in the current directory to tell the library to load our config from this
#directory rather than an absolute place on the rootfs
make DEBUG=`pwd`/tests/
cd tests

#Compile the tests
export LIBRARY_PATH=`pwd`/../
export LD_LIBRARY_PATH=`pwd`/../
gcc -c -I../ xml_parse.c
gcc xml_parse.o -lphantom -o xml_parse
