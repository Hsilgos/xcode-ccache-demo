// #include "foo.h"

#include <iostream>
#include <vector>

extern "C" {
 
void foo()
{
    int *ptr = nullptr;
    {
        std::vector<int> vec = {1, 2, 3};
        ptr = &vec[1];
    }

    // Accessing freed memory
    std::cout << "value=" << *ptr << std::endl;
}

}
