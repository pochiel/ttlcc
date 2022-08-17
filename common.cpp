#include <iostream>
#include <vector>
#include <sstream>
#include <string>
#include "common.hpp"

// 	https://qiita.com/iseki-masaya/items/70b4ee6e0877d12dafa8
std::vector<std::string> common_utl::split(const std::string &s, char delim) {
    std::vector<std::string> elems;
    std::stringstream ss(s);
    std::string item;
    while (std::getline(ss, item, delim)) {
    if (!item.empty()) {
            elems.push_back(item);
        }
    }
    return elems;
}
