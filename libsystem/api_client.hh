#pragma once 

#include <google/protobuf/any.pb.h>
#include <google/protobuf/message.h>

namespace api {
namespace client {

class Connection {
public:
    Connection(std::string socket) : socket_path{socket} {}
    template<typename T>
    void send(std::string, google::protobuf::Message&, T*);
private:
    std::string socket_path;
    int socket;
    bool connected = false;
};

class ConnectionManager {
public:
    ConnectionManager(std::string socket) : socket_path{socket} {}
    std::shared_ptr<Connection> getConnection();
private:
    std::string socket_path;
    std::unordered_map<pid_t, std::shared_ptr<Connection>> pool;
};

class ApiClient {
public:
    static ApiClient& the();
    std::string getcwd();
private:
    ApiClient();
    
    std::unique_ptr<ConnectionManager> cm;
};

};
};