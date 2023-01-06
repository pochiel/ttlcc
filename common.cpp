#include <iostream>
#include <iomanip>
#include <vector>
#include <sstream>
#include <string>
#include "common.hpp"
#include "crc.h"

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

// 文字列をハッシュ値に変えてくれる便利関数
std::string common_utl::str_to_hash(std::string name) {
    std::ostringstream ss;
    ss << std::setfill('0') << std::setw(8) << std::hex << crc_32((uint8_t*)name.c_str(), name.length());
    return ss.str();
}

