#ifndef __VARIABLE_NODE_HPP_
#define __VARIABLE_NODE_HPP_

#include "variable_manager.hpp"
#include "t_token.hpp"

class variable_node {
    public:
    variable_node(){}
    variable_node(uint32_t id, std::string name, std::string local, std::string func){
        id = id;
        realname = name;
        localname = local;
        parent_function = func;
        physicalname = variable_manager::convert_name_to_local(func, local);
        synbol_info = NULL;
    }
    uint32_t id;
    std::string parent_function;
    std::string realname;
    std::string localname;
    std::string physicalname;
    t_token * synbol_info;
    bool is_lending;
};

#endif  // __VARIABLE_NODE_HPP_