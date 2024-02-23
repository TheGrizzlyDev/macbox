package main

import (
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/TheGrizzlyDev/macbox/common/rpc"
	rpcmanage "github.com/TheGrizzlyDev/macbox/proto/macbox/manage/v1"
	"google.golang.org/protobuf/proto"
)

var (
	socketPath = flag.String("socket", "", "")
)

func main() {
	if err := run(os.Args[1:]); err != nil {
		panic(err)
	}
}

func run(args []string) error {
	if err := flag.CommandLine.Parse(args); err != nil {
		flag.Usage()
		return nil
	}

	managementServer := rpc.NewUnixSocketRpcServer(*socketPath)
	managementServer.AddHandler("create", rpc.RpcHandlerFn(func(request proto.Message) (proto.Message, error) {
		fmt.Println(request)
		return &rpcmanage.CreateSandboxResponse{
			SandboxUuid: "blablabla",
		}, nil
	}))

	go func() {
		time.Sleep(time.Second)
		client := rpc.NewUnixSocketRpcClient(*socketPath)
		response, err := client.Send("create", &rpcmanage.CreateSandboxRequest{Socket: "/tmp/bla"})
		if err != nil {
			panic(err)
		}
		fmt.Println(response)
	}()

	if err := managementServer.Listen(); err != nil {
		return err
	}

	return nil
}
