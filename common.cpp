#include <iostream>
#include <iomanip>
#include <vector>
#include <sstream>
#include <string>
#include "common.hpp"
extern "C" {
  #include "crc.h"
}

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

const std::string WHITESPACE = " \n\r\t\f\v";
 
std::string common_utl::ltrim(const std::string &s)
{
    size_t start = s.find_first_not_of(WHITESPACE);
    return (start == std::string::npos) ? "" : s.substr(start);
}
 
std::string common_utl::rtrim(const std::string &s)
{
    size_t end = s.find_last_not_of(WHITESPACE);
    return (end == std::string::npos) ? "" : s.substr(0, end + 1);
}
 
std::string common_utl::trim(const std::string &s) {
    return rtrim(ltrim(s));
}
 