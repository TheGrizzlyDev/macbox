package sandbox

import "google.golang.org/protobuf/proto"

type Server interface {
	Exec(proto.Message) (proto.Message, error)
}
