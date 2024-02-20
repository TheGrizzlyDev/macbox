package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/TheGrizzlyDev/macbox/common/rpc"
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
	managementServer.AddHandler("create", rpc.RpcHandlerFn(func(request []byte) ([]byte, error) {
		fmt.Println(request)
		return nil, nil
	}))
	if err := managementServer.Listen(); err != nil {
		return err
	}

	return nil
}
