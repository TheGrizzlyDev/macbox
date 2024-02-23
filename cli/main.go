package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/TheGrizzlyDev/macbox/common/rpc"

	rpcmanage "github.com/TheGrizzlyDev/macbox/proto/macbox/manage/v1"
)

func main() {
	if err := run(os.Args[1:]); err != nil {
		panic(err)
	}
}

func run(args []string) error {

	switch args[0] {
	case "create":
		cmd := flag.NewFlagSet("create", flag.ContinueOnError)
		socket := cmd.String("socket", "", "")
		if err := cmd.Parse(args[1:]); err != nil {
			cmd.Usage()
			return err
		}
		responseAsAny, err := rpc.NewUnixSocketRpcClient(*socket).Send("create", &rpcmanage.CreateSandboxRequest{})
		if err != nil {
			return err
		}
		response := &rpcmanage.CreateSandboxResponse{}
		if err = responseAsAny.UnmarshalTo(response); err != nil {
			return err
		}
		fmt.Println(response.SandboxUuid)
	case "exec":
		cmd := flag.NewFlagSet("exec", flag.ContinueOnError)
		socket := cmd.String("socket", "", "")
		sandboxId := cmd.String("sandbox_id", "", "")
		if err := cmd.Parse(args[1:]); err != nil {
			cmd.Usage()
			return err
		}

		responseAsAny, err := rpc.NewUnixSocketRpcClient(*socket).Send("exec", &rpcmanage.ExecRequest{
			Args:        cmd.Args(),
			SandboxUuid: *sandboxId,
		})
		if err != nil {
			return err
		}
		response := &rpcmanage.ExecResponse{}
		if err = responseAsAny.UnmarshalTo(response); err != nil {
			return err
		}
		fmt.Println(response)
	case "stop":
		cmd := flag.NewFlagSet("stop", flag.ContinueOnError)
		socket := cmd.String("socket", "", "")
		sandboxId := cmd.String("sandbox_id", "", "")
		if err := cmd.Parse(args[1:]); err != nil {
			cmd.Usage()
			return err
		}

		responseAsAny, err := rpc.NewUnixSocketRpcClient(*socket).Send("stop", &rpcmanage.StopRequest{
			SandboxUuid: *sandboxId,
		})
		if err != nil {
			return err
		}
		response := &rpcmanage.StopResponse{}
		if err = responseAsAny.UnmarshalTo(response); err != nil {
			return err
		}
		fmt.Println(response)
	}

	return nil
}
