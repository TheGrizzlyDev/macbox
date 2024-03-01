#include "api_client.hh"
#include "libs.hh"
#include "proto/protocol/v1/rpc.pb.h"
#include "proto/macbox/core/v1/macbox.pb.h"

namespace api {
namespace client {

std::unique_ptr<google::protobuf::Any> Connection::send(std::string method, google::protobuf::Message& request) {
    if (! connected) {
        if ((this->socket = libs::libc::socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
            throw std::runtime_error{"could not open socket"};
        }

        sockaddr address{};
        address.sa_family = AF_UNIX;
        strcpy(address.sa_data, socket_path.c_str());

        if (libs::libc::connect(this->socket, &address, sizeof(address) + socket_path.size()) == -1) {
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
    char lengthAsBytes[8];
    lengthAsBytes[7] = serailizedRequestLength & 0xff;
    lengthAsBytes[6] = (serailizedRequestLength >> 8) & 0xff;
    lengthAsBytes[5] = (serailizedRequestLength >> 16) & 0xff;
    lengthAsBytes[4] = (serailizedRequestLength >> 24) & 0xff;
    lengthAsBytes[3] = (serailizedRequestLength >> 32) & 0xff;
    lengthAsBytes[2] = (serailizedRequestLength >> 40) & 0xff;
    lengthAsBytes[1] = (serailizedRequestLength >> 48) & 0xff;
    lengthAsBytes[0] = (serailizedRequestLength >> 56) & 0xff;
    libs::libc::write(this->socket, lengthAsBytes, 8);
    libs::libc::write(this->socket, serializedRequest.c_str(), serailizedRequestLength);

    char *responseLengthBuf = new char[8];
    libs::libc::read(this->socket, responseLengthBuf, 8);
    size_t responseLength = responseLengthBuf[7] + 
        (responseLengthBuf[6] << 8) +
        (responseLengthBuf[5] << 16) +
        (responseLengthBuf[4] << 24) +
        (static_cast<size_t>(responseLengthBuf[3]) << 32) +
        (static_cast<size_t>(responseLengthBuf[2]) << 40) +
        (static_cast<size_t>(responseLengthBuf[1]) << 48) +
        (static_cast<size_t>(responseLengthBuf[0]) << 56);
    delete [] responseLengthBuf;

    char *responseBuf = new char[responseLength];
    libs::libc::read(this->socket, responseBuf, responseLength);

    protocol::v1::Response responseWrapper;
    responseWrapper.ParseFromArray(responseBuf, responseLength);
    delete [] responseBuf;

    std::cout << responseWrapper.DebugString() << std::endl;
    
    return std::unique_ptr<google::protobuf::Any>(responseWrapper.release_payload());

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
    google::protobuf::Arena arena {};
    std::cout << "ok" << std::endl;
    macbox::core::v1::CwdRequest request;
    macbox::core::v1::CwdResponse cwdResponse;
    auto response = cm->getConnection()->send("cwd", request);
    std::cout << response->DebugString() << std::endl;
    // response.payload().UnpackTo(&cwdResponse);
    response->UnpackTo(&cwdResponse);
    std::cout << cwdResponse.DebugString() << std::endl;
    // return cwdResponse.path();
    return "";
}

};
};