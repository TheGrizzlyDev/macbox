#include "api_client.hh"
#include "libs.hh"
#include "proto/protocol/v1/rpc.pb.h"

namespace api {
namespace client {

template<typename T>
void Connection::send(std::string method, google::protobuf::Message& request, T* response) {
    if (! connected) {
        if ((this->socket = libs::libc::socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
            throw std::runtime_error{"could not open socket"};
        }

        sockaddr address{};
        address.sa_family = AF_UNIX;
        strcpy(address.sa_data, socket_path.c_str());

        if (libs::libc::connect(this->socket, &address, sizeof(address)) == -1) {
            libs::libc::close(this->socket);
            throw std::runtime_error{"could not connect to socket"};
        }

        connected = true;
    }
    google::protobuf::Any requestAsAny;
    requestAsAny.PackFrom(request);
    protocol::v1::Request requestWrapper;
    requestWrapper.set_method(method);
    requestWrapper.set_allocated_payload(&requestAsAny);
    
    std::string serializedRequest = requestWrapper.SerializeAsString();
    auto serailizedRequestLength = serializedRequest.length();
    char* lengthAsBytes = static_cast<char*>(static_cast<void*>(&serailizedRequestLength));
    libs::libc::write(this->socket, lengthAsBytes, 8);
    libs::libc::write(this->socket, serializedRequest.c_str(), serailizedRequestLength);

    char *responseLengthBuf;
    libs::libc::read(this->socket, responseLengthBuf, 8);
    size_t responseLength = *static_cast<size_t*>(static_cast<void*>(responseLengthBuf));
    char *responseBuf;
    libs::libc::read(this->socket, responseBuf, responseLength);
    
    protocol::v1::Response responseWrapper;
    responseWrapper.ParseFromArray(responseBuf, responseLength);
    responseWrapper.payload().UnpackTo(response);

    // TODO: this code is cursed, it doesn't check a single damn error. Cringe.
}

std::shared_ptr<Connection> ConnectionManager::getConnection() {
    auto tid = libs::libc::gettid();
    if (! pool.contains(tid)) {
        auto conn = std::make_shared<Connection>(this->socket_path);
        pool[tid] = conn;
        return conn;
    }
    return pool[tid];
}

ApiClient::ApiClient() {
    cm = std::make_unique<ConnectionManager>(std::getenv("MACBOX_SANDBOX_SOCKET_PATH"));
}

ApiClient& ApiClient::the() {
    static ApiClient instance {};
    return instance;
}

std::string ApiClient::getcwd() {
    return "/bla/bla";
}

};
};