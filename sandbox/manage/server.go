package manage

import "context"

type ExecResponse struct {
	Pid int64
}

type Server interface {
	Exec(context.Context, []string) (*ExecResponse, error)
	Stop(context.Context)
}
