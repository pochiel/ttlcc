#include <vector>
#include <string>

#ifndef __COMMON_HPP__
#define __COMMON_HPP__

class common_utl {
    public:
    static std::vector<std::string> split(const std::string &s, char delim);
    static std::string str_to_hash(std::string name);
    static std::string ltrim(const std::string &s) ;
    static std::string rtrim(const std::string &s) ;
    static std::string trim(const std::string &s) ;

}; 

#endif //__COMMON_HPP__